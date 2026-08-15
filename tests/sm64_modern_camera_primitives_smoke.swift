import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ result: (value: Float, moving: Bool)) -> UInt64 {
    let x = hf(h, result.value); return h8(x, result.moving ? 1 : 0)
}
private func hash(_ h: UInt64, _ result: (value: Int16, moving: Bool)) -> UInt64 {
    let x = h16(h, UInt16(bitPattern: result.value)); return h8(x, result.moving ? 1 : 0)
}
private func hash(_ h: UInt64, _ angles: SM64CameraAngles) -> UInt64 {
    var x = hf(h, angles.distance); x = h16(x, UInt16(bitPattern: angles.pitch)); return h16(x, UInt16(bitPattern: angles.yaw))
}
private func hash(_ h: UInt64, _ vector: SM64ObjectVector3) -> UInt64 {
    var x = hf(h, vector.x); x = hf(x, vector.y); return hf(x, vector.z)
}
private func hash(_ h: UInt64, _ clamp: SM64CameraPitchClampResult) -> UInt64 {
    var x = hash(h, clamp.position); x = h16(x, UInt16(bitPattern: clamp.pitch)); x = h16(x, UInt16(bitPattern: clamp.yaw)); x = hf(x, clamp.distance); return h8(x, clamp.outOfRange)
}

@main
enum SM64ModernCameraPrimitivesSmoke {
    static func main() {
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, SM64CameraPrimitives.approachF32Asymptotic(current: 10, target: 20, multiplier: 2))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.approachF32Asymptotic(current: 20, target: 10, multiplier: 0.25))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.approachS16Asymptotic(current: 100, target: 0, divisor: 4))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.approachS16Asymptotic(current: -100, target: 20, divisor: 0))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.cameraApproachS16Symmetric(current: 0, target: 0x1000, increment: 0x400))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.cameraApproachS16Symmetric(current: 0x1000, target: 0, increment: -0x400))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.cameraApproachF32Symmetric(current: 0, target: 10, increment: 3))
        fingerprint = hash(fingerprint, SM64CameraPrimitives.cameraApproachF32Symmetric(current: 10, target: 0, increment: 3))

        let cButtons = SM64CameraPrimitives.findCButtonsPressed(
            currentState: 0, buttonsPressed: 0x0002 | 0x0008,
            buttonsDown: 0x0002 | 0x0008
        )
        precondition(cButtons == 0x000A)
        fingerprint = h16(fingerprint, cButtons)
        let cleared = SM64CameraPrimitives.findCButtonsPressed(
            currentState: cButtons, buttonsPressed: 0, buttonsDown: 0
        )
        precondition(cleared == 0)
        fingerprint = h16(fingerprint, cleared)

        let angles = SM64CameraPrimitives.calculateAngles(
            from: .init(x: 10, y: 20, z: -30), to: .init(x: -40, y: 80, z: 50)
        )!
        precondition(angles.distance.isFinite)
        fingerprint = hash(fingerprint, angles)
        let rotated = SM64CameraPrimitives.rotateInXZ(.init(x: 3, y: 4, z: 5), yaw: 0x2000)!
        fingerprint = hash(fingerprint, rotated)
        let clampedHigh = SM64CameraPrimitives.clampPitch(
            from: .zero, to: .init(x: 0, y: 100, z: 0), maxPitch: 0x2000, minPitch: -0x2000
        )!
        precondition(clampedHigh.outOfRange == 1 && clampedHigh.pitch == 0x2000)
        fingerprint = hash(fingerprint, clampedHigh)
        let clampedLow = SM64CameraPrimitives.clampPitch(
            from: .zero, to: .init(x: 0, y: -100, z: 0), maxPitch: 0x2000, minPitch: -0x2000
        )!
        precondition(clampedLow.outOfRange == 1 && clampedLow.pitch == -0x2000)
        fingerprint = hash(fingerprint, clampedLow)

        precondition(SM64CameraPrimitives.calculateAngles(
            from: .init(x: .infinity, y: 0, z: 0), to: .zero
        ) == nil)
        precondition(SM64CameraPrimitives.rotateInXZ(
            .init(x: .nan, y: 0, z: 0), yaw: 0
        ) == nil)
        print(String(format: "cameraPrimitivesFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera primitives smoke passed")
    }
}
