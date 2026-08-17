import Foundation

@main
struct SM64ModernMarioFaceRouteShardsSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MarioFaceRouteShardsSmoke", code: 1)
        }
        let routes = SM64MarioFaceRouteResourceCatalog.routes
        precondition(routes.map(\.routeID.rawValue) == Array(0..<6))
        let records = try routes.enumerated().map { index, route in
            try SM64MarioFaceRouteRenderOracle.liveCRecord(
                route: route,
                simulationTick: UInt64(index + 1),
                sequence: 0
            )
        }
        precondition(records.count == 6)
        precondition(records.allSatisfy { $0.domain == 11 && $0.recordKind == 7 })
        precondition(records.map(\.recordID) == Array(repeating: UInt64(5), count: 6))
        precondition(records.map { $0.values[0] } == Array(0..<6).map(UInt64.init))
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)

        let output = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_0f01,
            contentFingerprint: 0x4d30_0f02,
            timebaseFingerprint: 0x4d30_0f03,
            configurationFingerprint: 0x4d30_0f04,
            initialSaveFingerprint: 0x4d30_0f05,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: output)
        print("marioFaceRouteShardCount=\(routes.count)")
        print("marioFaceRouteShardRecords=\(records.count)")
        print(String(format: "marioFaceRouteShardFingerprint=0x%016llx", SM64MarioFaceRouteRenderOracle.fingerprint(records)))
        print("SM64 Modern Mario-face route shard Swift trace passed path=\(output.path)")
    }
}
