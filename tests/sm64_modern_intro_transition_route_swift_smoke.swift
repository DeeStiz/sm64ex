import Foundation

private let routeShard: UInt64 = 0x9a0f_7b4f_7ecf_6c41
private let routeCoverage: UInt64 = 0x8fc5_fa3c_2cd2_6867
private let routeContentFingerprint = fnvString(
    "levels/intro/script.c|level_intro_entry_1|script_events,transition"
)
private let routeConfigurationFingerprint = fnvString(
    "region=5553;fullscreen=off;skip_intro=0;native_tick=1;legacy_tick=1;"
        + "input_seed=0x6c1f8a943cb27d50;save_seed=0x2e7fdb4a0c5689b1;"
        + "shard=0x9a0f7b4f7ecf6c41;steps=320"
)

private enum IntroTransitionSmokeError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private func fnvString(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { hash, byte in
        (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func hex16(_ value: UInt64) -> String {
    String(value, radix: 16).leftPadded(to: 16, with: "0")
}

private extension String {
    func leftPadded(to length: Int, with character: Character) -> String {
        guard count < length else { return self }
        return String(repeating: String(character), count: length - count) + self
    }
}

private func resolvedURL(_ path: String) -> URL {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw IntroTransitionSmokeError.invalid(message) }
}

private func read(_ path: String) throws -> (
    data: Data,
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord]
) {
    let url = resolvedURL(path)
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    let trace = try SM64OracleTraceFile.read(from: url)
    return (data, trace.configuration, trace.records)
}

private func validateHeader(_ configuration: SM64OracleTraceConfiguration) throws {
    try require(configuration.mode == .record, "trace mode is not record")
    try require(configuration.contentFingerprint == routeContentFingerprint,
                 "intro source/content fingerprint mismatch")
    try require(configuration.configurationFingerprint == routeConfigurationFingerprint,
                 "intro route configuration fingerprint mismatch")
    try require(configuration.coverageFingerprint == routeCoverage,
                 "intro route coverage fingerprint mismatch")
}

private func validateRoute(
    _ configuration: SM64OracleTraceConfiguration,
    _ records: [SM64OracleTraceRecord]
) throws -> SM64IntroTransitionWindow {
    try validateHeader(configuration)
    let window: SM64IntroTransitionWindow
    do {
        window = try SM64IntroTransitionWindow(records: records)
    } catch {
        throw IntroTransitionSmokeError.invalid("intro transition window mismatch: \(error)")
    }
    try require(window.traceRecords == records, "Swift hash reconstruction changed records")
    return window
}

private func write(input: String, output: String) throws {
    let inputURL = resolvedURL(input)
    let outputURL = resolvedURL(output)
    try require(inputURL != outputURL, "single-artifact evidence is not independent")
    try require(!FileManager.default.fileExists(atPath: outputURL.path),
                 "rerun rejected: Swift output already exists")
    let native = try read(input)
    let window = try validateRoute(native.configuration, native.records)
    let copied = try window.receipts.map { try $0.makeTraceRecord() }
    try require(copied == native.records, "native/Swift receipt mismatch")
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: copied,
        to: outputURL
    )
    print(
        "swift_intro_transition_route_recorded shard=0x\(String(routeShard, radix: 16)) "
            + "records=\(copied.count) ticks=311,391 "
            + "hashes=0x\(hex16(SM64IntroTransitionReceipt.firstHash)),"
            + "0x\(hex16(SM64IntroTransitionReceipt.secondHash))"
    )
}

private func audit(cPath: String, swiftPath: String) throws {
    let cURL = resolvedURL(cPath)
    let swiftURL = resolvedURL(swiftPath)
    try require(cURL != swiftURL, "single-artifact evidence rejected")
    let c = try read(cPath)
    let swift = try read(swiftPath)
    _ = try validateRoute(c.configuration, c.records)
    _ = try validateRoute(swift.configuration, swift.records)
    try require(c.configuration == swift.configuration, "header mismatch")
    try require(c.records == swift.records, "record bytes mismatch")
    print(
        "intro_transition_pairing_audit admitted=1 c_records=\(c.records.count) "
            + "swift_records=\(swift.records.count) ticks=311,391 "
            + "hashes=0x\(hex16(SM64IntroTransitionReceipt.firstHash)),"
            + "0x\(hex16(SM64IntroTransitionReceipt.secondHash)) "
            + "blockers= first_divergence=none"
    )
}

private func tamper(input: String, output: String) throws {
    var data = try Data(contentsOf: resolvedURL(input))
    try require(data.count == 72 + 2 * SM64OracleTraceRecord.encodedSize,
                 "unexpected trace size before tamper")
    data[72 + 56] ^= 1
    try data.write(to: resolvedURL(output), options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: resolvedURL(output))
        throw IntroTransitionSmokeError.invalid("tamper was accepted")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("intro_transition_pairing_tamper_rejected=1")
    }
}

private func reorder(input: String, output: String) throws {
    let native = try read(input)
    try require(native.records.count == 2, "unexpected record count before reorder")
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: [native.records[1], native.records[0]],
        to: resolvedURL(output)
    )
    print("intro_transition_pairing_reordered_fixture_created=1")
}

private func missing(input: String, output: String) throws {
    let native = try read(input)
    try require(native.records.count == 2, "unexpected record count before missing case")
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: [native.records[0]],
        to: resolvedURL(output)
    )
    print("intro_transition_pairing_missing_fixture_created=1")
}

private func partial(input: String, output: String) throws {
    var data = try Data(contentsOf: resolvedURL(input))
    try require(data.count > 72, "trace too short before partial case")
    data.removeLast()
    try data.write(to: resolvedURL(output), options: .atomic)
    print("intro_transition_pairing_partial_fixture_created=1")
}

@main
struct SM64ModernIntroTransitionRouteSwiftSmoke {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else {
                throw IntroTransitionSmokeError.invalid("missing mode")
            }
            switch mode {
            case "write":
                guard arguments.count == 3 else {
                    throw IntroTransitionSmokeError.invalid("write requires C and Swift paths")
                }
                try write(input: arguments[1], output: arguments[2])
            case "audit":
                guard arguments.count == 3 else {
                    throw IntroTransitionSmokeError.invalid("audit requires C and Swift paths")
                }
                try audit(cPath: arguments[1], swiftPath: arguments[2])
            case "tamper":
                guard arguments.count == 3 else {
                    throw IntroTransitionSmokeError.invalid("tamper requires input and output")
                }
                try tamper(input: arguments[1], output: arguments[2])
            case "reorder":
                guard arguments.count == 3 else {
                    throw IntroTransitionSmokeError.invalid("reorder requires input and output")
                }
                try reorder(input: arguments[1], output: arguments[2])
            case "missing":
                guard arguments.count == 3 else {
                    throw IntroTransitionSmokeError.invalid("missing requires input and output")
                }
                try missing(input: arguments[1], output: arguments[2])
            case "partial":
                guard arguments.count == 3 else {
                    throw IntroTransitionSmokeError.invalid("partial requires input and output")
                }
                try partial(input: arguments[1], output: arguments[2])
            default:
                throw IntroTransitionSmokeError.invalid("unknown mode \(mode)")
            }
        } catch {
            FileHandle.standardError.write(
                Data("intro_transition_route_swift_failed=\(error)\n".utf8)
            )
            exit(1)
        }
    }
}
