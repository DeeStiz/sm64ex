import Foundation

@main
struct SM64ModernMarioFaceMetalTransformSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceMetalTransformSmoke", code: 1)
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
        let input = SM64MarioFaceExpressionInput(
            face: baseFace,
            animationBank: 0,
            animationFrameQ16: 1 << 16,
            peachKissTimeline: false,
            actionTimer: 100
        )
        let face = SM64MarioFaceRenderPacketBuilder.make(input: input, bundle: bundle)
        guard let packet = SM64MarioFaceMetalTransformPacketBuilder.make(
            routeID: .marioNormal,
            face: face
        ) else { throw NSError(domain: "MarioFaceMetalTransformSmoke", code: 2) }
        let records = try SM64MarioFaceMetalTransformOracle.records(packet: packet)
        precondition(records.count == 4)
        precondition(records.allSatisfy { $0.domain == 11 && $0.recordKind == 8 })
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1501,
            contentFingerprint: 0x4d30_1502,
            timebaseFingerprint: 0x4d30_1503,
            configurationFingerprint: 0x4d30_1504,
            initialSaveFingerprint: 0x4d30_1505,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(
            configuration: configuration,
            records: records,
            to: URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        )
        print("marioFaceMetalTransformRoute=\(packet.routeID)")
        print("marioFaceMetalTransformMesh=\(packet.sourceMeshID)")
        print("marioFaceMetalTransformViewport=\(packet.viewportWidth)x\(packet.viewportHeight)")
        print("marioFaceMetalTransformAnimationComponent=\(packet.animationComponentID)")
        print("marioFaceMetalTransformAnimationFrame=\(packet.animationFrameQ16)")
        print(String(format: "marioFaceMetalTransformPacketFingerprint=0x%016llx", SM64MarioFaceMetalTransformFingerprint.packet(packet)))
        print(String(format: "marioFaceMetalTransformTraceFingerprint=0x%016llx", SM64MarioFaceMetalTransformOracle.fingerprint(records)))
        print("marioFaceMetalTransformClipBits=" + packet.clipMatrix.map { String(format: "%08x", $0.bitPattern) }.joined(separator: ":"))
        print("marioFaceMetalTransformLightBits=" + (packet.lightDirection + packet.lightColor).map { String(format: "%08x", $0.bitPattern) }.joined(separator: ":"))
        print("marioFaceMetalTransformUniformFloats=\(packet.gpuUniformFloats.count)")
        print("SM64 Modern Mario-face Metal transform Swift trace passed")
    }
}
