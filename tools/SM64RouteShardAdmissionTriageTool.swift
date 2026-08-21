import Foundation

/// Read-only admission triage for a composite schema-4 route trace.
///
/// This tool deliberately does not use the execution ledger and never writes a
/// report, trace, or manifest. It answers the narrower question needed before
/// live promotion: which planned manifest rows have every expected
/// (domain,record_kind) key in the supplied trace, and which independent gates
/// still keep those rows out of the canonical ledger.
@main
struct SM64RouteShardAdmissionTriageTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case invalidManifest(String)
        case invalidTrace(String)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid route-shard manifest: \(reason)"
            case let .invalidTrace(reason): return "invalid route trace: \(reason)"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let trace: URL
    }

    private struct ManifestRow {
        let shard: SM64RouteShard
        let line: Int
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            let message = "sm64-route-shard-admission-triage: \(error)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let manifest = try read(options.manifest)
        let rows = try parseManifest(manifest)
        let trace: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord])
        do {
            trace = try SM64OracleTraceFile.read(from: options.trace)
        } catch {
            throw ToolError.invalidTrace("cannot decode \(options.trace.path): \(error)")
        }

        let observedKeys = Set(trace.records.map { key(domain: $0.domain, recordKind: $0.recordKind) })
        let observedKeyList = observedKeys.sorted()
        let tickCount = Set(trace.records.map(\.simulationTick)).count
        let fingerprints = [
            trace.configuration.buildFingerprint,
            trace.configuration.contentFingerprint,
            trace.configuration.timebaseFingerprint,
            trace.configuration.configurationFingerprint,
            trace.configuration.initialSaveFingerprint,
            trace.configuration.coverageFingerprint,
        ]

        print(
            "SM64 route-shard admission triage "
                + "manifest_rows=\(rows.count) "
                + "trace_records=\(trace.records.count) "
                + "trace_ticks=\(tickCount) "
                + "trace_mode=\(trace.configuration.mode.rawValue) "
                + "trace_fingerprints_nonzero=\(fingerprints.allSatisfy { $0 != 0 } ? 1 : 0) "
                + "observed_keys=\(observedKeyList.joined(separator: ","))"
        )

        var fullyCoveredCount = 0
        var admissibleCount = 0
        for row in rows {
            let expectedKeys = Set(row.shard.expectedDomains.map { key(domain: $0.cDomain, recordKind: $0.cRecordKind) })
            guard expectedKeys.isSubset(of: observedKeys) else { continue }
            fullyCoveredCount += 1

            let unexpectedKeys = observedKeys.subtracting(expectedKeys).sorted()
            var blockers: [String] = []
            if trace.records.count < expectedKeys.count {
                blockers.append("record_count=\(trace.records.count)<expected_min=\(expectedKeys.count)")
            }
            if tickCount < 2 {
                blockers.append("tick_window=\(tickCount)<required=2")
            }
            if !unexpectedKeys.isEmpty {
                blockers.append("unexpected_keys=\(unexpectedKeys.joined(separator: ","))")
            }

            // Schema-4's six fingerprints identify the captured run, content,
            // timebase, configuration, initial save, and covered domains. The
            // composite full trace does not carry the manifest row's
            // domain/identity/source binding, so it cannot establish a
            // canonical per-row route identity by itself.
            blockers.append("route_identity=unbound_composite_trace")

            // The retained full.trace is one source-backed composite trace.
            // A C sidecar replay or byte comparison is not an independently
            // recorded C trace for each manifest row and therefore cannot
            // satisfy the promotion boundary.
            blockers.append("independent_c_swift_evidence=per_row_pair_missing")

            let status = blockers.isEmpty ? "admissible" : "blocked"
            if blockers.isEmpty { admissibleCount += 1 }
            print(
                "candidate|"
                    + formatID(row.shard.id)
                    + "|line=\(row.line)"
                    + "|domain=\(row.shard.domain)"
                    + "|identity=\(row.shard.identity)"
                    + "|source=\(row.shard.source)"
                    + "|expected_keys=\(expectedKeys.sorted().joined(separator: ","))"
                    + "|observed_keys=\(observedKeyList.joined(separator: ","))"
                    + "|records=\(trace.records.count)"
                    + "|ticks=\(tickCount)"
                    + "|status=\(status)"
                    + "|blockers=\(blockers.joined(separator: ";"))"
            )
        }

        print(
            "admission_summary|fully_covered_candidates=\(fullyCoveredCount) "
                + "admissible_candidates=\(admissibleCount) "
                + "promoted_rows=0 "
                + "ledger_mutated=0"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard !arguments.isEmpty, arguments.count.isMultiple(of: 2) else {
            throw ToolError.invalidArguments(usage)
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard option.hasPrefix("--"), index + 1 < arguments.count else {
                throw ToolError.invalidArguments(usage)
            }
            guard values[option] == nil else {
                throw ToolError.invalidArguments("duplicate option \(option)\n\(usage)")
            }
            values[option] = arguments[index + 1]
            index += 2
        }
        let known = Set(["--manifest", "--trace"])
        guard values.keys.allSatisfy({ known.contains($0) }),
              let manifest = values["--manifest"],
              let trace = values["--trace"] else {
            throw ToolError.invalidArguments(usage)
        }
        return Options(
            manifest: URL(fileURLWithPath: manifest).standardizedFileURL,
            trace: URL(fileURLWithPath: trace).standardizedFileURL
        )
    }

    private static func parseManifest(_ text: String) throws -> [ManifestRow] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2,
              lines[0] == manifestHeader,
              lines[1] == manifestSchema else {
            throw ToolError.invalidManifest("invalid header")
        }
        var rows: [ManifestRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            do {
                let shard = try SM64RouteShard(manifestLine: line, lineNumber: lineNumber)
                guard seen.insert(shard.id).inserted else {
                    throw ToolError.invalidManifest(
                        String(format: "duplicate shard 0x%016llx", shard.id)
                    )
                }
                rows.append(ManifestRow(shard: shard, line: lineNumber))
            } catch let error as ToolError {
                throw error
            } catch {
                throw ToolError.invalidManifest("line \(lineNumber): \(error)")
            }
        }
        guard !rows.isEmpty else { throw ToolError.invalidManifest("manifest has no rows") }
        return rows
    }

    private static func read(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ToolError.unreadable(url, error)
        }
    }

    private static func key(domain: UInt32, recordKind: UInt32) -> String {
        "\(domain):\(recordKind)"
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }

    private static var usage: String {
        "usage: sm64-route-shard-admission-triage --manifest MANIFEST --trace TRACE"
    }
}
