import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func hash(_ h: UInt64, _ vector: SM64ObjectVector3) -> UInt64 {
    var x = hf(h, vector.x); x = hf(x, vector.y); return hf(x, vector.z)
}

private func hash(_ h: UInt64, _ state: SM64CameraCUpState) -> UInt64 {
    var x = h8(h, state.active ? 1 : 0); x = h8(x, state.startedExiting ? 1 : 0)
    x = hi16(x, state.pitch); x = hi16(x, state.modeOffsetYaw)
    x = hi16(x, state.headPitch); x = hi16(x, state.headYaw)
    x = hash(x, state.storedPosition); return hf(x, state.storedFocusOffsetY)
}

private func hash(_ h: UInt64, _ result: SM64CameraCUpHeadResult) -> UInt64 {
    var x = hi16(h, result.pitch); x = hi16(x, result.modeOffsetYaw)
    x = hi16(x, result.headPitch); return hi16(x, result.headYaw)
}

private func hash(_ h: UInt64, _ result: SM64CameraCUpPlacement) -> UInt64 {
    var x = hash(h, result.focus); x = hash(x, result.position); return hi16(x, result.yaw)
}

private func hash(_ h: UInt64, _ channel: SM64CameraShakeChannel?) -> UInt64 {
    guard let channel else { return h8(h, 0) }
    var x = h8(h, 1); x = hi16(x, channel.amplitude); x = hi16(x, channel.decay)
    return hi16(x, channel.increment)
}

private func hash(_ h: UInt64, _ plan: SM64CameraShakePlan) -> UInt64 {
    var x = hash(h, plan.pitch); x = hash(x, plan.yaw); x = hash(x, plan.roll); x = hash(x, plan.fov)
    x = h8(x, plan.freezesMovement ? 1 : 0); return h8(x, plan.changesFocusSpeed ? 1 : 0)
}

@main
enum SM64ModernCameraCUpSmoke {
    static func main() {
        let inactive = SM64CameraCUpState(
            active: false, startedExiting: false, pitch: 0, modeOffsetYaw: 0,
            headPitch: 0, headYaw: 0, storedPosition: .zero, storedFocusOffsetY: 0
        )
        let entered = SM64CameraCUp.enter(
            state: inactive,
            cameraPosition: .init(x: 10, y: 20, z: 30),
            marioPosition: .zero,
            cameraFocus: .init(x: 10, y: 125, z: 30)
        )!
        precondition(entered.active && entered.storedPosition == .init(x: 10, y: 20, z: 30)
            && entered.storedFocusOffsetY == 125)
        var fingerprint = hash(fnvOffset, entered)

        let head = SM64CameraCUp.updateHead(.init(
            pitch: 0x38E0, modeOffsetYaw: 0x5550, stickX: -1, stickY: 1
        ))!
        precondition(head.pitch == SM64CameraCUp.pitchMax
            && head.modeOffsetYaw == SM64CameraCUp.yawMax)
        fingerprint = hash(fingerprint, head)

        let placement = SM64CameraCUp.update(
            marioPosition: .init(x: -100, y: 20, z: -200),
            marioFaceYaw: Int16(bitPattern: 0x8000), pitch: 0, modeOffsetYaw: 0
        )!
        precondition(placement.yaw == 0)
        precondition(placement.focus == .init(x: -100, y: 145, z: -200))
        precondition(placement.position == .init(x: -100, y: 145, z: 50))
        fingerprint = hash(fingerprint, placement)

        let exited = SM64CameraCUp.requestExit(state: entered)
        precondition(exited.active && exited.startedExiting)
        fingerprint = hash(fingerprint, exited)

        fingerprint = hash(fingerprint, SM64CameraCUp.shake(.attack, waterOrMetalAction: false))
        fingerprint = hash(fingerprint, SM64CameraCUp.shake(.smallDamage, waterOrMetalAction: true))
        fingerprint = hash(fingerprint, SM64CameraCUp.shake(.fallDamage, waterOrMetalAction: false))
        precondition(SM64CameraCUp.updateHead(.init(
            pitch: 0, modeOffsetYaw: 0, stickX: .nan, stickY: 0
        )) == nil)

        print(String(format: "cameraCUpFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera C-up smoke passed")
    }
}
