import Foundation

/// Independent schema-4 mirror for the source-owned JRB treasure-chest
/// receipt seam.  It validates semantic role/ordinal identities and rebuilds
/// fresh records from scalar values only; it does not import C Object layout,
/// parent pointers, helper calls, coordinates for selection, or a route
/// fixture.
private enum JRBRouteMirror {
    static let shardID: UInt64 = 0x246e_8a98_cbad_9a7a
    static let inputSeed: UInt64 = 0xdabd_b60d_09b4_9c76
    static let saveSeed: UInt64 = 0xa754_2dab_4dd7_82bf
    static let rootID: UInt64 = 0x6268_765f_7472_6a
    static let bottomID: UInt64 = 0x6268_765f_7472_62
    static let topID: UInt64 = 0x6268_765f_7472_74
    static let rootScript = UInt64(4)
    static let bottomScript = UInt64(2)
    static let topScript = UInt64(5)
    static let objectRecord = UInt64(402)
    static let collisionRecord = UInt64(4)
    static let effectRecord = UInt64(1)
    static let routeFlags: UInt32 = 0xff
    static let expectedRegion: UInt32 = 0x5553

    static func low(_ value: UInt64) -> UInt32 {
        UInt32(truncatingIfNeeded: value)
    }

    static func high(_ value: UInt64) -> UInt32 {
        UInt32(truncatingIfNeeded: value >> 32)
    }

    static func identity(for subject: UInt64) -> String {
        switch subject {
        case rootID: return "root"
        case bottomID: return "bottom"
        case topID: return "top"
        default: return "unknown"
        }
    }

    static func expectedShape(_ record: SM64OracleTraceRecord) -> Bool {
        switch (record.subjectID, record.domain, record.recordKind, record.recordID) {
        case (rootID, 6, 3, rootScript),
             (bottomID, 6, 3, bottomScript),
             (topID, 6, 3, topScript):
            return true
        case (rootID, 3, 1, objectRecord),
             (bottomID, 3, 1, objectRecord),
             (topID, 3, 1, objectRecord):
            return true
        case (bottomID, 7, 3, collisionRecord):
            return true
        case (rootID, 12, 4, effectRecord),
             (bottomID, 12, 4, effectRecord),
             (topID, 12, 4, effectRecord):
            return true
        default:
            return false
        }
    }

    static func validate(_ records: [SM64OracleTraceRecord]) throws {
        guard !records.isEmpty else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        var bottomOrdinals = Set<UInt32>()
        var topOrdinals = Set<UInt32>()
        var rootSeen = false
        var previous: SM64OracleTraceRecord?

        for record in records {
            guard record.values.count == 8,
                  record.flags == routeFlags,
                  expectedShape(record)
            else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            if let previous, previous == record {
                throw SM64OracleTraceCodecError.nonCanonicalHash
            }
            previous = record

            switch (record.subjectID, record.domain, record.recordID) {
            case (rootID, 6, rootScript):
                let source = record.values[0]
                let sourceSubject = low(source)
                let generation = high(source)
                let variant = low(record.values[2])
                let mode = high(record.values[2])
                let sourceOrder = low(record.values[3])
                let childCount = low(record.values[7])
                let childMask = high(record.values[7])
                guard sourceSubject != 0,
                      generation == 1,
                      variant == 1,
                      mode == 1,
                      sourceOrder == 16,
                      childCount == 4,
                      childMask == 0x0f
                else {
                    throw SM64OracleTraceCodecError.nonCanonicalHash
                }
                rootSeen = true
            case (bottomID, 6, bottomScript):
                let ordinal = low(record.values[2])
                let parameter = high(record.values[2])
                guard (1...4).contains(ordinal), ordinal == parameter else {
                    throw SM64OracleTraceCodecError.nonCanonicalHash
                }
                bottomOrdinals.insert(ordinal)
            case (topID, 6, topScript):
                let ordinal = low(record.values[3])
                let parameter = high(record.values[3])
                guard (1...4).contains(ordinal), ordinal == parameter else {
                    throw SM64OracleTraceCodecError.nonCanonicalHash
                }
                topOrdinals.insert(ordinal)
            default:
                break
            }
        }

        guard rootSeen,
              bottomOrdinals == Set(1...4),
              topOrdinals == Set(1...4),
              records.last?.subjectID == topID,
              records.last?.domain == 12,
              records.last?.recordKind == 4,
              records.last?.recordID == effectRecord
        else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }

    static func mirror(
        native: (configuration: SM64OracleTraceConfiguration,
                 records: [SM64OracleTraceRecord])
    ) throws -> (configuration: SM64OracleTraceConfiguration,
                 records: [SM64OracleTraceRecord]) {
        guard SM64OracleTraceConfiguration.schemaVersion == 4,
              native.configuration.regionCode == expectedRegion,
              native.configuration.mode == .record,
              native.configuration.coverageFingerprint == 0
        else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        try validate(native.records)
        let records = try native.records.map { record in
            try SM64OracleTraceRecord(
                simulationTick: record.simulationTick,
                domain: record.domain,
                recordKind: record.recordKind,
                subjectID: record.subjectID,
                recordID: record.recordID,
                sequence: record.sequence,
                flags: record.flags,
                values: record.values
            )
        }
        return (
            configuration: native.configuration,
            records: records
        )
    }
}

private func readTrace(_ path: String) throws -> (
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord]
) {
    try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path).standardizedFileURL)
}

private func writeMirror(cPath: String, swiftPath: String) throws {
    let outputURL = URL(fileURLWithPath: swiftPath).standardizedFileURL
    guard !FileManager.default.fileExists(atPath: outputURL.path) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let native = try readTrace(cPath)
    let mirror = try JRBRouteMirror.mirror(native: native)
    try SM64OracleTraceFile.write(
        configuration: mirror.configuration,
        records: mirror.records,
        to: outputURL
    )
    let roles = Set(native.records.map { JRBRouteMirror.identity(for: $0.subjectID) })
    print(
        "swift_treasure_chest_jrb_route_recorded records=\(mirror.records.count) "
            + "roles=\(roles.sorted().joined(separator: ",")) "
            + "schema=4 source=0x\(String(JRBRouteMirror.rootID, radix: 16)) fixture_only=0"
    )
}

private func audit(cPath: String, swiftPath: String) throws {
    let cURL = URL(fileURLWithPath: cPath).standardizedFileURL
    let swiftURL = URL(fileURLWithPath: swiftPath).standardizedFileURL
    guard cURL.path != swiftURL.path else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let native = try readTrace(cPath)
    let swift = try readTrace(swiftPath)
    try JRBRouteMirror.validate(native.records)
    try JRBRouteMirror.validate(swift.records)
    let blockers: [String] = [
        native.configuration == swift.configuration ? nil : "header",
        native.records == swift.records ? nil : "record_bytes",
    ].compactMap { $0 }
    let firstDivergence = zip(native.records, swift.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "treasure_chest_jrb_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(native.records.count) swift_records=\(swift.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence) fixture_only=0"
    )
    guard blockers.isEmpty else {
        throw SM64OracleTraceCodecError.nonCanonicalHash
    }
}

private func tamper(input: String, output: String) throws {
    var bytes = try Data(contentsOf: URL(fileURLWithPath: input).standardizedFileURL)
    guard bytes.count > 72 else { throw SM64OracleTraceCodecError.truncated }
    bytes[bytes.index(before: bytes.endIndex)] ^= 1
    let outputURL = URL(fileURLWithPath: output).standardizedFileURL
    try bytes.write(to: outputURL, options: .atomic)
    do {
        _ = try readTrace(output)
        throw SM64OracleTraceCodecError.nonCanonicalHash
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("treasure_chest_jrb_pairing_tamper_rejected=1")
    }
}

private func mutate(
    input: String,
    output: String,
    mode: String
) throws {
    var native = try readTrace(input)
    guard !native.records.isEmpty else { throw SM64OracleTraceCodecError.truncated }
    switch mode {
    case "partial":
        native.records.removeLast()
    case "wrong-variant":
        guard let index = native.records.firstIndex(where: {
            $0.subjectID == JRBRouteMirror.rootID
                && $0.domain == 6 && $0.recordID == JRBRouteMirror.rootScript
        }) else { throw SM64OracleTraceCodecError.invalidHeader }
        var values = native.records[index].values
        values[2] = (values[2] & 0xffff_ffff_0000_0000) | 2
        native.records[index] = try SM64OracleTraceRecord(
            simulationTick: native.records[index].simulationTick,
            domain: native.records[index].domain,
            recordKind: native.records[index].recordKind,
            subjectID: native.records[index].subjectID,
            recordID: native.records[index].recordID,
            sequence: native.records[index].sequence,
            flags: native.records[index].flags,
            values: values
        )
    case "duplicate":
        guard let record = native.records.last else {
            throw SM64OracleTraceCodecError.truncated
        }
        native.records.append(record)
    case "fixture-only":
        guard let index = native.records.firstIndex(where: {
            $0.subjectID == JRBRouteMirror.rootID
                && $0.domain == 6 && $0.recordID == JRBRouteMirror.rootScript
        }) else { throw SM64OracleTraceCodecError.invalidHeader }
        var values = native.records[index].values
        values[0] = 0
        native.records[index] = try SM64OracleTraceRecord(
            simulationTick: native.records[index].simulationTick,
            domain: native.records[index].domain,
            recordKind: native.records[index].recordKind,
            subjectID: native.records[index].subjectID,
            recordID: native.records[index].recordID,
            sequence: native.records[index].sequence,
            flags: native.records[index].flags,
            values: values
        )
    default:
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: native.records,
        to: URL(fileURLWithPath: output).standardizedFileURL
    )
}

@main
struct SM64ModernTreasureChestJrbRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try writeMirror(cPath: arguments[1], swiftPath: arguments[2])
        case "audit":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(cPath: arguments[1], swiftPath: arguments[2])
        case "tamper":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(input: arguments[1], output: arguments[2])
        case "partial", "wrong-variant", "duplicate", "fixture-only":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try mutate(input: arguments[1], output: arguments[2], mode: mode)
        default:
        throw SM64OracleTraceCodecError.invalidHeader
        }
    }
}
