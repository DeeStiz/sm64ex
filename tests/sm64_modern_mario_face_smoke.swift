import Foundation

@main
struct SM64ModernMarioFaceSmoke {
    static func main() {
        let inputs: [SM64MarioFaceInput] = [
            .init(bodyIndex: 0, areaUpdateCounter: 0, eyeState: 0, action: 0, handState: 0, handSwitchCaseCount: 0, capState: 0, modelState: 0),
            .init(bodyIndex: 1, areaUpdateCounter: 14, eyeState: 0, action: SM64MarioFace.stationaryActionMask, handState: 0, handSwitchCaseCount: 0, capState: 1, modelState: 0x100),
            .init(bodyIndex: 0, areaUpdateCounter: 31, eyeState: 3, action: SM64MarioFace.stationaryActionMask, handState: 1, handSwitchCaseCount: 1, capState: 2, modelState: 0x200),
            .init(bodyIndex: 0, areaUpdateCounter: 8, eyeState: 0, action: SM64MarioFace.swimmingOrFlyingActionMask, handState: 0, handSwitchCaseCount: 0, capState: 2, modelState: 0x300),
            .init(bodyIndex: 0, areaUpdateCounter: 16, eyeState: 0, action: 0, handState: 2, handSwitchCaseCount: 0, capState: 3, modelState: 0x17F),
            .init(bodyIndex: 1, areaUpdateCounter: 63, eyeState: 8, action: 0, handState: 5, handSwitchCaseCount: 1, capState: 0, modelState: 0x2FF),
            .init(bodyIndex: 0, areaUpdateCounter: 2, eyeState: 1, action: SM64MarioFace.stationaryActionMask, handState: 4, handSwitchCaseCount: 0, capState: 1, modelState: 0),
            .init(bodyIndex: 1, areaUpdateCounter: 5, eyeState: 0, action: SM64MarioFace.stationaryActionMask, handState: 3, handSwitchCaseCount: 1, capState: 0, modelState: 0x280),
        ]
        var fingerprint = SM64MarioFaceFingerprint.geometry(SM64MarioFace.geometry)
        for input in inputs {
            fingerprint = SM64MarioFaceFingerprint.packet(
                fingerprint,
                SM64MarioFace.resolve(input)
            )
        }
        let geometryFingerprint = SM64MarioFaceFingerprint.geometry(SM64MarioFace.geometry)
        precondition(SM64MarioFace.geometry.vertexCount == 440)
        precondition(SM64MarioFace.geometry.faceCount == 877)
        precondition(SM64MarioFace.geometry.componentIDs.count == 22)
        precondition(SM64MarioFace.resolve(inputs[0]).eyeCase == 1)
        precondition(SM64MarioFace.resolve(inputs[3]).handCase == 1)
        precondition(SM64MarioFace.resolve(inputs[5]).eyeCase == 7)
        print(String(format: "marioFaceGeometryFingerprint=0x%016llx", geometryFingerprint))
        print(String(format: "marioFaceFingerprint=0x%016llx", fingerprint))
        print("marioFaceScenarios=\(inputs.count)")
        print("SM64 Modern Mario face smoke passed")
    }
}
