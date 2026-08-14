import Foundation

@main
struct SM64ModernOracleTraceSwiftSmoke {
    static func main() throws {
        if CommandLine.arguments.count > 1 {
            let cTrace = try SM64OracleTraceFile.read(
                from: URL(fileURLWithPath: CommandLine.arguments[1])
            )
            precondition(cTrace.configuration.mode == .record)
            precondition(cTrace.records.count == 3)
            precondition(cTrace.records[0].canonicalHash == 0x7999f81a870a9f43)
        }

        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x0123456789abcdef,
            contentFingerprint: 0xfedcba9876543210,
            timebaseFingerprint: 0x1122334455667788,
            configurationFingerprint: 0x8877665544332211,
            initialSaveFingerprint: 0x1020304050607080,
            coverageFingerprint: 0x9988776655443322
        )
        let input = try SM64OracleTraceRecord(
            simulationTick: 1,
            domain: 1,
            recordKind: 2,
            recordID: 1,
            sequence: 0,
            values: [0x8000, 0x00007f80]
        )
        let mario = try SM64OracleTraceRecord(
            simulationTick: 1,
            domain: 2,
            recordKind: 1,
            recordID: 111,
            sequence: 0,
            values: [0x1234, 0x3f800000, 0xbf800000, 1]
        )
        precondition(input.encoded().count == 128)
        precondition(mario.encoded().count == 128)
        precondition(input.canonicalHash == 0x7999f81a870a9f43)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-oracle-swift-smoke")
            .appendingPathExtension("trace")
        defer { try? FileManager.default.removeItem(at: url) }
        try SM64OracleTraceFile.write(
            configuration: configuration,
            records: [input, mario],
            to: url
        )
        let decoded = try SM64OracleTraceFile.read(from: url)
        precondition(decoded.configuration == configuration)
        precondition(decoded.records == [input, mario])

        var tampered = try Data(contentsOf: url)
        tampered[tampered.count - 1] ^= 1
        try tampered.write(to: url, options: .atomic)
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            preconditionFailure("tampered trace unexpectedly decoded")
        } catch {
            precondition(String(describing: error).contains("nonCanonicalHash"))
        }
        print("SM64 Modern Swift oracle trace smoke passed")
    }
}
