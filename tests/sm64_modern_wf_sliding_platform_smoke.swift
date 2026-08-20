import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func append(
    _ initialization: SM64WfSlidingPlatformInitialization,
    to fingerprint: inout UInt64
) {
    fingerprint = hashF32(fingerprint, initialization.positionX)
    fingerprint = hashF32(fingerprint, initialization.homeX)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: initialization.faceYaw))
    fingerprint = hashF32(fingerprint, initialization.speed)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: initialization.timer))
}

private func append(
    _ output: SM64WfSlidingPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashF32(fingerprint, output.positionX)
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashF32(fingerprint, output.positionZ)
    fingerprint = hashF32(fingerprint, output.forwardVelocity)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceYaw))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.moveYaw))
    fingerprint = hashF32(fingerprint, output.velocityX)
    fingerprint = hashF32(fingerprint, output.velocityZ)
}

@main
enum SM64ModernWfSlidingPlatformSmoke {
    static func main() {
        let initialization = SM64WfSlidingPlatformBehavior.initialize(
            position: .zero, faceYaw: 0x8000, moveYaw: 0x4000,
            behaviorByte: 1, initialTimer: 37
        )
        let waiting = SM64WfSlidingPlatformBehavior.update(SM64WfSlidingPlatformInput(
            action: 0, timer: 100, positionX: 2, positionY: 0, positionZ: 0,
            homeX: 2, forwardVelocity: 0, faceYaw: -0x4000, moveYaw: 0x4000, speed: 10
        ))
        let start = SM64WfSlidingPlatformBehavior.update(SM64WfSlidingPlatformInput(
            action: 0, timer: 101, positionX: 2, positionY: 0, positionZ: 0,
            homeX: 2, forwardVelocity: 0, faceYaw: -0x4000, moveYaw: 0x4000, speed: 10
        ))
        let extendEnd = SM64WfSlidingPlatformBehavior.update(SM64WfSlidingPlatformInput(
            action: 1, timer: 50, positionX: 12, positionY: 0, positionZ: 0,
            homeX: 2, forwardVelocity: 10, faceYaw: -0x4000, moveYaw: 0x4000, speed: 10
        ))
        let retractTurn = SM64WfSlidingPlatformBehavior.update(SM64WfSlidingPlatformInput(
            action: 1, timer: 60, positionX: 12, positionY: 0, positionZ: 0,
            homeX: 2, forwardVelocity: 0, faceYaw: -0x4000, moveYaw: 0x4000, speed: 10
        ))
        precondition(initialization == SM64WfSlidingPlatformInitialization(
            positionX: 2, homeX: 2, faceYaw: 0x4000, speed: 10, timer: 37
        ))
        precondition(waiting.action == 0 && waiting.forwardVelocity == 0)
        precondition(start.action == 1 && start.forwardVelocity == 10 && start.positionX == 12)
        precondition(extendEnd.action == 1 && extendEnd.forwardVelocity == 0 && extendEnd.positionX == 512)
        precondition(retractTurn.action == 2 && retractTurn.forwardVelocity == 10 && retractTurn.moveYaw == -0x4000)
        var fingerprint = fnvOffset
        append(initialization, to: &fingerprint)
        append(waiting, to: &fingerprint)
        append(start, to: &fingerprint)
        append(extendEnd, to: &fingerprint)
        append(retractTurn, to: &fingerprint)
        print(String(format: "wfSlidingPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern WF sliding platform smoke passed")
    }
}
