import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64VolcanoFallingTrapOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.facePitch)), UInt64(bitPattern: Int64(output.angleVelocityPitch)), UInt64(output.positionY.bitPattern), output.playQuietPound ? 1 : 0, output.playBigPound ? 1 : 0, output.playRiseSound ? 1 : 0, output.shakeCamera ? 1 : 0]
}

@main
struct SM64VolcanoFallingTrapSmoke {
    static func main() {
        let trigger = SM64VolcanoFallingTrapBehavior.update(.init(action: 0, timer: 0, distanceToMario: 900, positionY: 0, homeY: 0, facePitch: 0, angleVelocityPitch: 0, acceleration: 0))
        let impact = SM64VolcanoFallingTrapBehavior.update(.init(action: 1, timer: 0, distanceToMario: 2_000, positionY: 0, homeY: 0, facePitch: -0x3FFF, angleVelocityPitch: 0x100, acceleration: 4))
        let rise = SM64VolcanoFallingTrapBehavior.update(.init(action: 2, timer: 3, distanceToMario: 2_000, positionY: 0, homeY: 100, facePitch: -0x4000, angleVelocityPitch: 0, acceleration: 0))
        let reset = SM64VolcanoFallingTrapBehavior.update(.init(action: 3, timer: 200, distanceToMario: 2_000, positionY: 0, homeY: 0, facePitch: -0x100, angleVelocityPitch: 0, acceleration: 0))
        precondition(trigger.action == 1 && trigger.playQuietPound)
        precondition(impact.action == 2 && impact.facePitch == -0x4000 && impact.playBigPound && impact.shakeCamera)
        precondition(rise.positionY == 100 + SM64CanonicalTrig.sins(0x3000) * 10)
        precondition(reset.action == 0 && reset.angleVelocityPitch == 0x90)
        var fingerprint = offset
        for output in [trigger, impact, rise, reset] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "volcanoFallingTrapFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern volcano falling trap smoke passed")
    }
}
