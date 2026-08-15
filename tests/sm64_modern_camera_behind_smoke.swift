import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func hash(_ h: UInt64, _ result: SM64CameraBehindResult) -> UInt64 {
    var x = hf(h, result.distance); x = hi16(x, result.pitch); x = hi16(x, result.yaw)
    x = hf(x, result.maxDistance); x = hf(x, result.focusYOffset)
    x = hi16(x, result.sideButtonYaw); x = hi16(x, result.behindMarioSoundTimer)
    x = hi16(x, result.yawSpeed); x = hi16(x, result.pitchIncrement)
    x = hi16(x, result.goalPitch); x = hi16(x, result.goalYawOffset)
    return h8(x, result.playedSideSound ? 1 : 0)
}

@main
enum SM64ModernCameraBehindSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let normal = SM64CameraBehindKernel.update(.init(
            distance: 900, pitch: 0x1000, yaw: 0x2000,
            marioFacePitch: -0x0800, marioYaw: 0x4000,
            marioModeActive: false, waterOrMetalAction: false,
            cButtonsPressed: 0, sideButtonYaw: 0, behindMarioSoundTimer: 0
        ))!
        precondition(normal.distance == 800 && normal.goalPitch == 0x0800
            && normal.yawSpeed == 24 && !normal.playedSideSound)
        fingerprint = hash(fingerprint, normal)

        let rotateLeft = SM64CameraBehindKernel.update(.init(
            distance: 300, pitch: 0, yaw: 0,
            marioFacePitch: 0, marioYaw: 0x4000,
            marioModeActive: false, waterOrMetalAction: false,
            cButtonsPressed: SM64CameraPrimitives.leftCButtons,
            sideButtonYaw: 0, behindMarioSoundTimer: 0
        ))!
        precondition(rotateLeft.distance == 305 && rotateLeft.yaw == 4
            && rotateLeft.goalYawOffset == -0x3FF8
            && rotateLeft.sideButtonYaw == 30 && rotateLeft.yawSpeed == 2)
        fingerprint = hash(fingerprint, rotateLeft)

        let rotateUp = SM64CameraBehindKernel.update(.init(
            distance: 340, pitch: -0x100, yaw: 0x0100,
            marioFacePitch: 0x100, marioYaw: 0,
            marioModeActive: true, waterOrMetalAction: true,
            cButtonsPressed: SM64CameraPrimitives.upCButtons,
            sideButtonYaw: 4, behindMarioSoundTimer: 3
        ))!
        precondition(rotateUp.distance == 345 && rotateUp.goalPitch == 0x3000
            && rotateUp.pitchIncrement == 0x800 && rotateUp.behindMarioSoundTimer == 30
            && rotateUp.focusYOffset == 120 && rotateUp.playedSideSound)
        fingerprint = hash(fingerprint, rotateUp)

        precondition(SM64CameraBehindKernel.update(.init(
            distance: .nan, pitch: 0, yaw: 0, marioFacePitch: 0, marioYaw: 0,
            marioModeActive: false, waterOrMetalAction: false,
            cButtonsPressed: 0, sideButtonYaw: 0, behindMarioSoundTimer: 0
        )) == nil)
        print(String(format: "cameraBehindFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera behind kernel smoke passed")
    }
}
