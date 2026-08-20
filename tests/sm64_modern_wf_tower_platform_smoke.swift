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
    _ output: SM64WfTowerPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashF32(fingerprint, output.positionX)
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashF32(fingerprint, output.positionZ)
    fingerprint = hashF32(fingerprint, output.forwardVelocity)
    fingerprint = hashF32(fingerprint, output.velocityX)
    fingerprint = hashF32(fingerprint, output.velocityZ)
    fingerprint = hashU32(fingerprint, output.shouldDelete ? 1 : 0)
    fingerprint = hashU32(fingerprint, output.playedSound ? 1 : 0)
}

@main
enum SM64ModernWfTowerPlatformSmoke {
    static func main() {
        let elevatorIdle = SM64WfTowerPlatformBehavior.update(SM64WfTowerPlatformInput(
            kind: .elevator, action: 0, timer: 0, positionX: 0, positionY: 100,
            positionZ: 0, moveYaw: 0, distance: 0, speed: 0,
            marioOnPlatform: false, parentAction: 0
        ))
        let elevatorStart = SM64WfTowerPlatformBehavior.update(SM64WfTowerPlatformInput(
            kind: .elevator, action: 0, timer: 0, positionX: 0, positionY: 100,
            positionZ: 0, moveYaw: 0, distance: 0, speed: 0,
            marioOnPlatform: true, parentAction: 0
        ))
        let elevatorUp = SM64WfTowerPlatformBehavior.update(SM64WfTowerPlatformInput(
            kind: .elevator, action: 1, timer: 140, positionX: 0, positionY: 100,
            positionZ: 0, moveYaw: 0, distance: 0, speed: 0,
            marioOnPlatform: true, parentAction: 0
        ))
        let slidingBack = SM64WfTowerPlatformBehavior.update(SM64WfTowerPlatformInput(
            kind: .sliding, action: 0, timer: 0, positionX: 0, positionY: 100,
            positionZ: 0, moveYaw: 0, distance: 380, speed: 3,
            marioOnPlatform: false, parentAction: 0
        ))
        let slidingTurn = SM64WfTowerPlatformBehavior.update(SM64WfTowerPlatformInput(
            kind: .sliding, action: 0, timer: 127, positionX: 0, positionY: 100,
            positionZ: 0, moveYaw: 0, distance: 380, speed: 3,
            marioOnPlatform: false, parentAction: 3
        ))
        precondition(elevatorIdle.action == 0 && elevatorIdle.positionY == 100)
        precondition(elevatorStart.action == 1 && !elevatorStart.playedSound)
        precondition(elevatorUp.action == 1 && elevatorUp.positionY == 105 && elevatorUp.playedSound)
        precondition(slidingBack.action == 0 && slidingBack.forwardVelocity == -3 && slidingBack.positionZ == -3)
        precondition(slidingTurn.action == 1 && slidingTurn.forwardVelocity == -3 && slidingTurn.shouldDelete)
        var fingerprint = fnvOffset
        append(elevatorIdle, to: &fingerprint)
        append(elevatorStart, to: &fingerprint)
        append(elevatorUp, to: &fingerprint)
        append(slidingBack, to: &fingerprint)
        append(slidingTurn, to: &fingerprint)
        print(String(format: "wfTowerPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern WF tower platform smoke passed")
    }
}
