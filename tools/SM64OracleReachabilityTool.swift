import Darwin
import Foundation

private struct ReachabilityRow: Comparable, Hashable {
    let domain: String
    let identity: String
    let source: String
    let status: String
    let notes: String

    static func < (lhs: ReachabilityRow, rhs: ReachabilityRow) -> Bool {
        Array(lhs.encoded.utf8).lexicographicallyPrecedes(Array(rhs.encoded.utf8))
    }

    var encoded: String {
        [domain, identity, source, status, notes].joined(separator: "|")
    }
}

private enum ReachabilityError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case unavailableRoot(String)
    case outputFailed(String)

    var description: String {
        switch self {
        case let .invalidArguments(message), let .unavailableRoot(message), let .outputFailed(message):
            return message
        }
    }
}

@main
struct SM64OracleReachabilityTool {
    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            let message = "sm64-oracle-reachability: \(error)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let root = URL(fileURLWithPath: options.root).standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ReachabilityError.unavailableRoot(root.path)
        }

        let files = try enumerateFiles(root: root)
        var rows: [ReachabilityRow] = []
        rows += levelScriptRows(files: files)
        rows += geoRows(files: files)
        rows += behaviorRows(files: files)
        rows += displayListRows(files: files)
        rows += audioRows(files: files)
        rows += textRows(files: files)
        rows += callRows(files: files, domain: "save_mutation", prefix: "src/game/", pattern: #"\b(save_file_[A-Za-z0-9_]+)\s*\("#, notes: "save mutation call site")
        rows += callRows(files: files, domain: "render_callback", prefix: "src/pc/gfx/", pattern: #"\b(gfx_[A-Za-z0-9_]+)\s*\("#, notes: "render callback call site")
        rows += callRows(files: files, domain: "collision", prefix: "src/game/", pattern: #"\b(find_floor|find_ceil|find_wall_collisions|resolve_and_return_wall_collisions|find_water_level|find_poison_gas_level)\s*\("#, notes: "collision query call site")
        rows += callRows(files: files, domain: "rng", prefix: "src/game/", pattern: #"\b(random_[A-Za-z0-9_]+|random_u16|random_float)\s*\("#, notes: "random draw call site")
        rows += callRows(
            files: files,
            domain: "transition",
            prefix: "src/game/",
            pattern: #"\b(warp_to_level|level_trigger_warp|initiate_warp|fade_into_special_warp|set_play_mode)\s*\("#,
            notes: "transition call site",
            // Phase 52 added this prototype alongside the real C transition;
            // keep the historical header-derived rows stable while excluding
            // the new declaration from the canonical denominator.
            excluding: ["initiate_warp|src/game/level_update.h"]
        )
        rows += oracleHookRows()

        let ordered = Array(Set(rows)).sorted()
        let header = [
            "# sm64-modern-oracle-reachability-v1",
            "# domain|identity|source|status|notes",
        ]
        let output = (header + ordered.map { $0.encoded }).joined(separator: "\n") + "\n"
        let outputURL = URL(fileURLWithPath: options.output).standardizedFileURL
        do {
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(output.utf8).write(to: outputURL, options: .atomic)
        } catch {
            throw ReachabilityError.outputFailed("cannot write \(outputURL.path): \(error)")
        }

        let counts = Dictionary(grouping: ordered, by: { $0.domain })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
        print("SM64 oracle reachability inventory rows=\(ordered.count) domains=[\(counts)] output=\(outputURL.path)")
    }

    private struct Options {
        let root: String
        let output: String
    }

    private static func parse(arguments: [String]) throws -> Options {
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            guard argument.hasPrefix("--"), index + 1 < arguments.count else {
                throw ReachabilityError.invalidArguments(usage)
            }
            values[argument] = arguments[index + 1]
            index += 2
        }
        guard let root = values["--root"], let output = values["--output"] else {
            throw ReachabilityError.invalidArguments(usage)
        }
        return Options(root: root, output: output)
    }

    private static func enumerateFiles(root: URL) throws -> [(path: String, text: String)] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw ReachabilityError.unavailableRoot("cannot enumerate \(root.path)")
        }
        var files: [(path: String, text: String)] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            let relative = url.path.replacingOccurrences(of: root.path + "/", with: "")
            guard !relative.hasPrefix("build/"), !relative.hasPrefix(".git/") else { continue }
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            files.append((relative, text))
        }
        return files.sorted { $0.path < $1.path }
    }

    private static func levelScriptRows(files: [(path: String, text: String)]) -> [ReachabilityRow] {
        files.filter { path, _ in
            path.hasPrefix("levels/") && (path.hasSuffix("/script.c") || path == "levels/entry.c")
        }.map { path, _ in
            ReachabilityRow(domain: "level_script", identity: path, source: path, status: "declared", notes: "level script source")
        }
    }

    private static func geoRows(files: [(path: String, text: String)]) -> [ReachabilityRow] {
        files.filter { path, _ in
            (path.hasPrefix("levels/") || path.hasPrefix("actors/"))
                && (path.hasSuffix("/geo.c") || path.hasSuffix("/leveldata.c"))
        }.map { path, _ in
            ReachabilityRow(domain: "geo_layout", identity: path, source: path, status: "declared", notes: "geo/level layout source")
        }
    }

    private static func behaviorRows(files: [(path: String, text: String)]) -> [ReachabilityRow] {
        rowsFromMatches(
            files: files.filter { path, _ in path.hasPrefix("data/") || path.hasPrefix("src/game/") || path.hasPrefix("actors/") },
            domain: "behavior",
            pattern: #"\b(?:const\s+)?BehaviorScript\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            notes: "behavior script declaration"
        )
    }

    private static func displayListRows(files: [(path: String, text: String)]) -> [ReachabilityRow] {
        rowsFromMatches(
            files: files.filter { path, _ in path.hasPrefix("levels/") || path.hasPrefix("actors/") },
            domain: "display_list",
            pattern: #"\bGfx\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:\[|=)"#,
            notes: "display-list declaration"
        )
    }

    private static func audioRows(files: [(path: String, text: String)]) -> [ReachabilityRow] {
        files.filter { path, _ in path.hasPrefix("sound/") && !path.hasSuffix("/") }.map { path, _ in
            ReachabilityRow(domain: "audio_asset", identity: path, source: path, status: "declared", notes: "audio source/sequence asset")
        }
    }

    private static func textRows(files: [(path: String, text: String)]) -> [ReachabilityRow] {
        files.filter { path, _ in
            path.hasPrefix("src/game/") && (path.localizedCaseInsensitiveContains("text") || path.hasSuffix(".inc.h"))
        }.map { path, _ in
            ReachabilityRow(domain: "text", identity: path, source: path, status: "declared", notes: "text/dialog source")
        }
    }

    private static func callRows(
        files: [(path: String, text: String)],
        domain: String,
        prefix: String,
        pattern: String,
        notes: String,
        excluding: Set<String> = []
    ) -> [ReachabilityRow] {
        rowsFromMatches(
            files: files.filter { path, _ in path.hasPrefix(prefix) },
            domain: domain,
            pattern: pattern,
            notes: notes,
            excluding: excluding
        )
    }

    private static func rowsFromMatches(
        files: [(path: String, text: String)],
        domain: String,
        pattern: String,
        notes: String,
        excluding: Set<String> = []
    ) -> [ReachabilityRow] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var rows: [ReachabilityRow] = []
        for (path, text) in files {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            for match in regex.matches(in: text, range: range) {
                guard match.numberOfRanges > 1,
                      let identityRange = Range(match.range(at: 1), in: text) else { continue }
                let identity = String(text[identityRange])
                guard !excluding.contains("\(identity)|\(path)") else { continue }
                rows.append(ReachabilityRow(domain: domain, identity: identity, source: path, status: "declared", notes: notes))
            }
        }
        return rows
    }

    private static func oracleHookRows() -> [ReachabilityRow] {
        let source = "src/pc/sm64_modern_gameplay_parity.c"
        return [
            ("input", "hooked", "normalized pad and replay boundary"),
            ("global_state", "hooked", "global snapshot boundary"),
            ("mario_state", "hooked", "Mario snapshot boundary"),
            ("interaction_state", "hooked", "interaction snapshot boundary"),
            ("camera_state", "hooked", "camera snapshot boundary"),
            ("object_state", "hooked", "actor snapshot boundary"),
            ("effects", "hooked", "sound rumble spawn/despawn effects"),
            ("audio_pcm", "hooked", "pre-device PCM checksum boundary"),
            ("save_bytes", "hooked", "mutation/persist/load/reload byte boundary; full save closure remains"),
            ("render_packet", "hooked", "draw packet hash plus frame begin/end/finish boundaries"),
            ("script_events", "hooked", "level/behavior command and lifecycle boundaries"),
            ("collision_queries", "hooked", "floor/ceil/wall/environment query boundary"),
            ("rng_draws", "hooked", "u16/float/sign draw boundary"),
            ("audio_sequence", "hooked", "owner-thread tick, sequence, queue, and secondary boundaries"),
        ].map { domain, status, notes in
            ReachabilityRow(domain: "oracle_hook", identity: domain, source: source, status: status, notes: notes)
        }
    }

    private static let usage = "usage: sm64-oracle-reachability --root ROOT --output TSV"
}
