import Foundation

@main
struct SM64ModernMarioFaceRouteResourcesSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MarioFaceRouteResourcesSmoke", code: 1)
        }
        let bundle = try SM64MarioFacePayloadBundle.decode(
            Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        )
        let baseFace = SM64MarioFaceInput(
            bodyIndex: 0,
            areaUpdateCounter: 0,
            eyeState: SM64MarioFaceEyeState.blink.rawValue,
            action: 0,
            handState: SM64MarioFaceHandState.fists.rawValue,
            handSwitchCaseCount: 0,
            capState: 0,
            modelState: 0
        )
        let faceInput = SM64MarioFaceExpressionInput(
            face: baseFace,
            animationBank: 0,
            animationFrameQ16: (1 << 16) | 0x8000,
            peachKissTimeline: false,
            actionTimer: 100
        )
        let face = SM64MarioFaceRenderPacketBuilder.make(input: faceInput, bundle: bundle)
        let routes = SM64MarioFaceRouteResourceCatalog.routes
        let textures = SM64MarioFaceRouteResourceCatalog.textures
        precondition(routes.count == 6)
        precondition(textures.count == 19)
        precondition(routes[2].routeID == .marioNormal)
        precondition(routes[2].textureIDs == [1, 2, 0x300])
        precondition(SM64MarioFaceRouteResourceCatalog.texture(0x300)?.format == .ia8)
        precondition(SM64MarioFaceRouteResourceCatalog.texture(0x300)?.policyFlags == 0b111)
        precondition(SM64MarioFaceRouteResourceCatalog.camera(for: routes[2]).viewSymbol == "sMSceneView")
        precondition(SM64MarioFaceRouteResourceCatalog.camera(for: routes[2]).lightDirection == [0, 120, 0])

        var metadataRecords: [SM64OracleTraceRecord] = []
        var dynamicRecords: [SM64OracleTraceRecord] = []
        var liveCRecords: [SM64OracleTraceRecord] = []
        var dynamicPacketFingerprint = SM64MarioFaceRouteResourceFingerprint.offset
        for route in routes {
            let camera = SM64MarioFaceRouteResourceCatalog.camera(for: route)
            let routeMetadata = try SM64MarioFaceRouteRenderOracle.metadataRecords(
                route: route,
                camera: camera,
                textures: route.textureIDs.compactMap(SM64MarioFaceRouteResourceCatalog.texture),
                simulationTick: 100 + UInt64(route.routeID.rawValue),
                sequenceStart: route.routeID.rawValue * 16
            )
            precondition(routeMetadata.count == 2 + route.textureIDs.count)
            precondition(routeMetadata.allSatisfy { $0.domain == 11 && $0.recordKind == 7 })
            let metadataRoundTrip = try routeMetadata.map { try SM64OracleTraceRecord.decode($0.encoded()) }
            precondition(metadataRoundTrip == routeMetadata)
            metadataRecords.append(contentsOf: routeMetadata)
            liveCRecords.append(try SM64MarioFaceRouteRenderOracle.liveCRecord(
                route: route,
                simulationTick: 500 + UInt64(route.routeID.rawValue),
                sequence: route.routeID.rawValue
            ))

            guard let packet = SM64MarioFaceRouteRenderPacketBuilder.make(
                routeID: route.routeID, face: face
            ) else { preconditionFailure("route packet missing") }
            dynamicPacketFingerprint = hash(dynamicPacketFingerprint, packet.fingerprint)
            let routeRecords = try SM64MarioFaceRouteRenderOracle.records(
                packet: packet,
                simulationTick: 700 + UInt64(route.routeID.rawValue),
                sequenceStart: route.routeID.rawValue * 32
            )
            precondition(routeRecords.count == routeMetadata.count + 1)
            let routeRoundTrip = try routeRecords.map { try SM64OracleTraceRecord.decode($0.encoded()) }
            precondition(routeRoundTrip == routeRecords)
            dynamicRecords.append(contentsOf: routeRecords)
        }

        let metadataFingerprint = SM64MarioFaceRouteRenderOracle.fingerprint(metadataRecords)
        let dynamicFingerprint = SM64MarioFaceRouteRenderOracle.fingerprint(dynamicRecords)
        let liveCRecordFingerprint = SM64MarioFaceRouteRenderOracle.fingerprint(liveCRecords)
        print(String(format: "marioFaceRouteResourceFingerprint=0x%016llx", SM64MarioFaceRouteResourceFingerprint.catalog()))
        print("marioFaceRouteCount=\(routes.count)")
        print("marioFaceRouteTextureCount=\(textures.count)")
        print("marioFaceRouteTextureRecords=\(routes.reduce(0) { $0 + $1.textureIDs.count })")
        print("marioFaceRouteCameraRecords=\(routes.count)")
        print("marioFaceRouteMetadataRecords=\(metadataRecords.count)")
        print(String(format: "marioFaceRouteMetadataFingerprint=0x%016llx", metadataFingerprint))
        print("marioFaceRouteLiveRecordCount=\(liveCRecords.count)")
        print(String(format: "marioFaceRouteLiveRecordFingerprint=0x%016llx", liveCRecordFingerprint))
        print(String(format: "marioFaceRouteDynamicPacketFingerprint=0x%016llx", dynamicPacketFingerprint))
        print(String(format: "marioFaceRouteDynamicFingerprint=0x%016llx", dynamicFingerprint))
        print("marioFaceRouteDynamicPackets=\(routes.count)")
        print("marioFaceRouteDynamicRecords=\(dynamicRecords.count)")
        print("SM64 Modern Mario-face route/resource smoke passed")
    }

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xFF
            result &*= SM64MarioFaceRouteResourceFingerprint.prime
        }
        return result
    }
}
