import Foundation

@main
struct SM64ModernMarioFaceTextureProviderSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceTextureProviderSmoke", code: 1)
        }
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let traceURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let routes = SM64MarioFaceRouteResourceCatalog.routes
        var records: [SM64OracleTraceRecord] = []
        var allPayloads: [SM64MarioFaceTexturePayload] = []

        for (index, route) in routes.enumerated() {
            guard let binding = SM64MarioFaceMetalBindingPacketBuilder.make(routeID: route.routeID) else {
                throw NSError(domain: "MarioFaceTextureProviderSmoke", code: 2)
            }
            let payloads = try SM64MarioFaceTextureProvider.load(route: route, rootURL: rootURL)
            precondition(payloads.count == route.textureIDs.count)
            precondition(payloads.allSatisfy {
                $0.width == 32 && $0.height == 32
                    && $0.sourceByteCount == ($0.sourceFormat == .rgba16 ? 2048 : 1024)
                    && $0.uploadByteCount == 4096
                    && $0.rgba8Pixels.count == 4096
            })
            if route.routeID == .marioNormal {
                precondition(payloads.contains { $0.sourceFormat == .ia8 })
            }
            records.append(contentsOf: try SM64MarioFaceTexturePayloadOracle.records(
                route: route, payloads: payloads, binding: binding,
                simulationTick: UInt64(index + 1)
            ))
            allPayloads.append(contentsOf: payloads)
        }
        precondition(allPayloads.count == 38)
        precondition(records.count == 44)
        let uniquePayloads = Dictionary(allPayloads.map { ($0.textureID, $0) }, uniquingKeysWith: { first, _ in first })
        precondition(uniquePayloads.count == 19)
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)

        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1101,
            contentFingerprint: 0x4d30_1102,
            timebaseFingerprint: 0x4d30_1103,
            configurationFingerprint: 0x4d30_1104,
            initialSaveFingerprint: 0x4d30_1105,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: traceURL)

        print("marioFaceTextureProviderRoutes=\(routes.count)")
        print("marioFaceTextureProviderTextures=\(uniquePayloads.count)")
        print("marioFaceTextureProviderRecords=\(records.count)")
        print("marioFaceTextureProviderSourceBytes=\(uniquePayloads.values.reduce(0) { $0 + $1.sourceByteCount })")
        print("marioFaceTextureProviderUploadBytes=\(uniquePayloads.values.reduce(0) { $0 + $1.uploadByteCount })")
        print(String(format: "marioFaceTextureProviderTraceFingerprint=0x%016llx", SM64MarioFaceTexturePayloadOracle.fingerprint(records)))
        print(String(format: "marioFaceTextureProviderFirstUploadFingerprint=0x%016llx", allPayloads[0].uploadPixelFingerprint))
        print(String(format: "marioFaceTextureProviderShineUploadFingerprint=0x%016llx", uniquePayloads[0x300]!.uploadPixelFingerprint))
        print("SM64 Modern Mario-face texture provider Swift trace passed path=\(traceURL.path)")
    }
}
