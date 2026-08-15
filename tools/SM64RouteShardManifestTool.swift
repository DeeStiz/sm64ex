import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private struct InventoryRow: Hashable, Comparable {
    let domain: String
    let identity: String
    let source: String
    let status: String
    let notes: String

    var encoded: String {
        [domain, identity, source, status, notes].joined(separator: "|")
    }

    static func < (lhs: InventoryRow, rhs: InventoryRow) -> Bool {
        lhs.encoded.utf8.lexicographicallyPrecedes(rhs.encoded.utf8)
    }
}

private struct RouteShard: Comparable {
    let shardID: UInt64
    let domain: String
    let identity: String
    let source: String
    let inputSeed: UInt64
    let saveSeed: UInt64
    let expectedDomains: String
    let status: String
    let notes: String

    var encoded: String {
        [
            String(format: "0x%016llx", shardID), domain, identity, source,
            String(format: "0x%016llx", inputSeed),
            String(format: "0x%016llx", saveSeed), expectedDomains, status, notes,
        ].joined(separator: "|")
    }

    static func < (lhs: RouteShard, rhs: RouteShard) -> Bool {
        lhs.encoded.utf8.lexicographicallyPrecedes(rhs.encoded.utf8)
    }
}

private enum RouteShardError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case malformedInventory(line: Int, reason: String)
    case duplicateInventoryRow(String)
    case duplicateShardID(String)
    case outputFailed(String)

    var description: String {
        switch self {
        case let .invalidArguments(message): return message
        case let .malformedInventory(line, reason):
            return "inventory line \(line): \(reason)"
        case let .duplicateInventoryRow(row): return "duplicate inventory row: \(row)"
        case let .duplicateShardID(id): return "duplicate route shard id: \(id)"
        case let .outputFailed(message): return message
        }
    }
}

@main
struct SM64RouteShardManifestTool {
    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("sm64-route-shards: \(error)\n".utf8))
            exit(2)
        }
    }

    private struct Options {
        let inventory: URL
        let output: URL
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let rows = try readInventory(from: options.inventory)
        var shards = rows.map(makeShard)
        let ids = shards.map(\.shardID)
        guard Set(ids).count == ids.count else {
            let duplicate = Dictionary(grouping: shards, by: \.shardID)
                .first { $0.value.count > 1 }?.key ?? 0
            throw RouteShardError.duplicateShardID(String(format: "0x%016llx", duplicate))
        }
        shards.sort()

        let header = [
            "# sm64-modern-route-shards-v1",
            "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes",
        ]
        let output = (header + shards.map(\.encoded)).joined(separator: "\n") + "\n"
        do {
            try FileManager.default.createDirectory(
                at: options.output.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(output.utf8).write(to: options.output, options: .atomic)
        } catch {
            throw RouteShardError.outputFailed("cannot write \(options.output.path): \(error)")
        }

        let domains = Dictionary(grouping: shards, by: \.domain)
            .mapValues(\.count)
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
        print("SM64 route-shard manifest rows=\(shards.count) status=planned domains=[\(domains)] output=\(options.output.path)")
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard arguments.count == 4,
              arguments[0] == "--inventory",
              arguments[2] == "--output" else {
            throw RouteShardError.invalidArguments(
                "usage: sm64-route-shards --inventory INVENTORY --output MANIFEST"
            )
        }
        return Options(
            inventory: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
            output: URL(fileURLWithPath: arguments[3]).standardizedFileURL
        )
    }

    private static func readInventory(from url: URL) throws -> [InventoryRow] {
        let text = try String(contentsOf: url, encoding: .utf8)
        var rows = Set<InventoryRow>()
        for (offset, line) in text.split(whereSeparator: { $0.isNewline }).enumerated() {
            let lineNumber = offset + 1
            let value = String(line)
            guard !value.isEmpty, !value.hasPrefix("#") else { continue }
            let fields = value.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 5 else {
                throw RouteShardError.malformedInventory(line: lineNumber, reason: "expected five pipe-delimited fields")
            }
            guard fields.allSatisfy({ !$0.contains("\n") && !$0.contains("\r") }) else {
                throw RouteShardError.malformedInventory(line: lineNumber, reason: "embedded newline")
            }
            let row = InventoryRow(
                domain: fields[0], identity: fields[1], source: fields[2],
                status: fields[3], notes: fields[4]
            )
            guard rows.insert(row).inserted else {
                throw RouteShardError.duplicateInventoryRow(row.encoded)
            }
        }
        guard !rows.isEmpty else {
            throw RouteShardError.malformedInventory(line: 0, reason: "inventory is empty")
        }
        return rows.sorted()
    }

    private static func makeShard(_ row: InventoryRow) -> RouteShard {
        let canonical = row.encoded
        let shardID = hash(canonical)
        let inputSeed = hash(canonical + "|input")
        let saveSeed = hash(canonical + "|save")
        return RouteShard(
            shardID: shardID,
            domain: row.domain,
            identity: row.identity,
            source: row.source,
            inputSeed: inputSeed,
            saveSeed: saveSeed,
            expectedDomains: expectedTraceDomains(for: row.domain, identity: row.identity),
            status: "planned",
            notes: "deterministic route shard; execution remains an M33 gate"
        )
    }

    private static func expectedTraceDomains(for domain: String, identity: String) -> String {
        let values: [String]
        switch domain {
        case "audio_asset": values = ["audio_sequence", "audio_pcm"]
        case "behavior": values = ["script_events", "object_state", "collision_queries", "effects"]
        case "collision": values = ["collision_queries", "object_state"]
        case "display_list", "geo_layout", "render_callback": values = ["render_packet"]
        case "level_script": values = ["script_events", "global_state", "transition"]
        case "oracle_hook": values = [identity]
        case "rng": values = ["rng_draws"]
        case "save_mutation": values = ["save_bytes", "global_state"]
        case "text": values = ["script_events"]
        case "transition": values = ["transition", "global_state", "render_packet"]
        default: values = ["global_state"]
        }
        return Array(Set(values)).sorted().joined(separator: ",")
    }

    private static func hash(_ value: String) -> UInt64 {
        value.utf8.reduce(fnvOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* fnvPrime
        }
    }
}
