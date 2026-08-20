import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64KickableBoardOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.phase)), UInt64(output.rockSpeed.bitPattern), UInt64(bitPattern: Int64(output.facePitch)), UInt64(bitPattern: Int64(output.angleVelocityPitch)), output.tangible ? 1 : 0, output.fellModel ? 1 : 0, output.shouldDelete ? 1 : 0, output.playImpactSound ? 1 : 0, output.playFallSound ? 1 : 0] }

@main
struct SM64KickableBoardSmoke {
    static func main() {
        let idle = SM64KickableBoardBehavior.update(.init(action: 0, timer: 0, phase: 0, rockSpeed: 0, facePitch: 0, angleVelocityPitch: 0, attacked: true, attackType: 1, attackAboveBoard: false))
        let trigger = SM64KickableBoardBehavior.update(.init(action: 1, timer: 31, phase: 0, rockSpeed: 1000, facePitch: 0, angleVelocityPitch: 0, attacked: true, attackType: 2, attackAboveBoard: true))
        let fall = SM64KickableBoardBehavior.update(.init(action: 2, timer: 0, phase: 0, rockSpeed: 0, facePitch: 0, angleVelocityPitch: 0, attacked: false, attackType: 0, attackAboveBoard: false))
        let landed = SM64KickableBoardBehavior.update(.init(action: 2, timer: 10, phase: 0, rockSpeed: 0, facePitch: -0x3FFF, angleVelocityPitch: -0x80, attacked: false, attackType: 0, attackAboveBoard: false))
        precondition(idle.action == 1 && idle.timer == 0 && idle.rockSpeed == 1600)
        precondition(trigger.action == 2 && trigger.timer == 0 && trigger.playImpactSound)
        precondition(fall.facePitch == -0x80 && !fall.tangible)
        precondition(landed.action == 3 && landed.facePitch == -0x4000 && landed.playFallSound)
        var fingerprint = offset
        for output in [idle, trigger, fall, landed] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "kickableBoardFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Kickable Board smoke passed")
    }
}
