import Foundation

private func readTrace(_ path: String) throws -> (
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord]
) {
    try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path).standardizedFileURL)
}

private func writeMirror(cPath: String, swiftPath: String) throws {
    let native = try readTrace(cPath)
    var migration = SM64RNGBreakParticlesMigration()
    let mirror = try migration.mirror(
        native: native.records,
        configuration: native.configuration
    )
    try SM64OracleTraceFile.write(
        configuration: mirror.configuration,
        records: mirror.records,
        to: URL(fileURLWithPath: swiftPath).standardizedFileURL
    )
    print(
        "swift_rng_break_particles_route_recorded records=\(mirror.records.count) "
            + "tick=\(SM64RNGBreakParticlesMigration.routeTick) "
            + "source=0x\(String(SM64RNGBreakParticlesMigration.sourceIdentity, radix: 16)) "
            + "coverage=0x\(String(mirror.configuration.coverageFingerprint, radix: 16)) "
            + "fixture_only=0"
    )
}

private func audit(cPath: String, swiftPath: String) throws {
    let native = try readTrace(cPath)
    let swift = try readTrace(swiftPath)
    var blockers: [String] = []
    if native.configuration != swift.configuration { blockers.append("header") }
    if native.records.count != swift.records.count { blockers.append("record_count") }
    if native.records != swift.records { blockers.append("record_bytes") }
    let firstDivergence = zip(native.records, swift.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "rng_break_particles_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(native.records.count) swift_records=\(swift.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence) fixture_only=0"
    )
    guard blockers.isEmpty else { throw SM64OracleTraceCodecError.nonCanonicalHash }
}

private func tamper(input: String, output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input).standardizedFileURL)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[data.index(before: data.endIndex)] ^= 1
    let outputURL = URL(fileURLWithPath: output).standardizedFileURL
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try data.write(to: outputURL, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: outputURL)
        print("rng_break_particles_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.nonCanonicalHash
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("rng_break_particles_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernRNGBreakParticlesRouteSwiftSmoke {
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
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
