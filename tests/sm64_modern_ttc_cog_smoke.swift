import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }

private func append(_ output: SM64TTCCogOutput, to fingerprint: inout UInt64) {
    fingerprint = hashF32(fingerprint, output.speed)
    fingerprint = hashF32(fingerprint, output.targetSpeed)
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.angleVelocityYaw)))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.faceYaw)))
}

@main
enum SM64ModernTTCCogSmoke {
    static func main() {
        let slow = SM64TTCCogBehavior.update(SM64TTCCogInput(
            speedSetting: 0, direction: 1, speed: 0, targetSpeed: 0,
            faceYaw: 0, randomTargetSpeed: 0, randomApproachReached: false
        ))
        let fast = SM64TTCCogBehavior.update(SM64TTCCogInput(
            speedSetting: 1, direction: -1, speed: 0, targetSpeed: 0,
            faceYaw: 0x1000, randomTargetSpeed: 0, randomApproachReached: false
        ))
        let randomApproach = SM64TTCCogBehavior.update(SM64TTCCogInput(
            speedSetting: 2, direction: 1, speed: 0, targetSpeed: 200,
            faceYaw: 0, randomTargetSpeed: -400, randomApproachReached: false
        ))
        let randomChange = SM64TTCCogBehavior.update(SM64TTCCogInput(
            speedSetting: 2, direction: -1, speed: 200, targetSpeed: 200,
            faceYaw: 0, randomTargetSpeed: -400, randomApproachReached: true
        ))
        let stopped = SM64TTCCogBehavior.update(SM64TTCCogInput(
            speedSetting: 3, direction: 1, speed: 400, targetSpeed: 0,
            faceYaw: 0, randomTargetSpeed: 0, randomApproachReached: false
        ))
        precondition(slow.speed == 200 && slow.faceYaw == 200)
        precondition(fast.speed == 400 && fast.angleVelocityYaw == -400 && fast.faceYaw == 0x0E70)
        precondition(randomApproach.speed == 50 && randomApproach.targetSpeed == 200)
        precondition(randomChange.speed == 200 && randomChange.targetSpeed == -400 && randomChange.faceYaw == -200)
        precondition(stopped.speed == 400 && stopped.angleVelocityYaw == 400)
        var fingerprint = fnvOffset
        append(slow, to: &fingerprint); append(fast, to: &fingerprint)
        append(randomApproach, to: &fingerprint); append(randomChange, to: &fingerprint)
        append(stopped, to: &fingerprint)
        print(String(format: "ttcCogFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC cog smoke passed")
    }
}
