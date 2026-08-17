import Foundation

@main
struct SM64ModernMarioFaceDrawListSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceMetalDrawListSmoke", code: 1)
        }
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let traceURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let source = try SM64MarioFaceSourceGeometryProvider.load(rootURL: rootURL)
        let routeID: SM64MarioFaceGoddardRouteID = .marioNormal
        guard let binding = SM64MarioFaceMetalBindingPacketBuilder.make(routeID: routeID),
              let transform = SM64MarioFaceMetalTransformPacketBuilder.make(
                routeID: routeID, animationFrameQ16: 1 << 16
              ),
              let packet = SM64MarioFaceMetalDrawListBuilder.make(
                source: source, routeID: routeID, binding: binding, transform: transform
              ) else {
            throw NSError(domain: "MarioFaceMetalDrawListSmoke", code: 2)
        }
        precondition(packet.commands.count == 877)
        precondition(packet.materialIndexCount == 2_631)
        precondition(packet.commands[0].indices == [43, 102, 112])
        precondition(packet.commands[876].indices.count == 3)
        precondition(packet.textureBinding.textureID == 0x300)
        let records = try SM64MarioFaceMetalDrawListOracle.records(packet: packet)
        precondition(records.count == 880)
        precondition(records.allSatisfy { $0.domain == 11 && $0.recordKind == 8 })
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1601,
            contentFingerprint: 0x4d30_1602,
            timebaseFingerprint: 0x4d30_1603,
            configurationFingerprint: 0x4d30_1604,
            initialSaveFingerprint: 0x4d30_1605,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: traceURL)
        print("marioFaceMetalDrawListRoute=\(packet.routeID)")
        print("marioFaceMetalDrawListMesh=\(packet.meshID)")
        print("marioFaceMetalDrawListFaces=\(packet.commands.count)")
        print("marioFaceMetalDrawListMaterialIndices=\(packet.materialIndexCount)")
        print("marioFaceMetalDrawListTexture=\(packet.textureBinding.textureID)")
        print("marioFaceMetalDrawListSampler=\(packet.textureBinding.sampler.packed)")
        print(String(format: "marioFaceMetalDrawListTextureFingerprint=0x%016llx", SM64MarioFaceMetalDrawListFingerprint.texture(packet.textureBinding)))
        print(String(format: "marioFaceMetalDrawListMaterialIndexFingerprint=0x%016llx", SM64MarioFaceMetalDrawListFingerprint.materialIndices(packet)))
        print(String(format: "marioFaceMetalDrawListSourceIndexFingerprint=0x%016llx", SM64MarioFaceMetalDrawListFingerprint.sourceIndices(packet)))
        print(String(format: "marioFaceMetalDrawListFingerprint=0x%016llx", SM64MarioFaceMetalDrawListFingerprint.drawList(packet)))
        print(String(format: "marioFaceMetalDrawListTransformFingerprint=0x%016llx", packet.transformFingerprint))
        print(String(format: "marioFaceMetalDrawListTraceFingerprint=0x%016llx", SM64MarioFaceMetalDrawListOracle.fingerprint(records)))
        print("marioFaceMetalDrawListTraceRecords=\(records.count)")
        print("SM64 Modern Mario-face complete draw-list Swift trace passed")
    }
}
