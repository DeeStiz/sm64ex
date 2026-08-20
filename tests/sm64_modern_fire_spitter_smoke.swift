import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64FireSpitterSmoke {
    static func main() {
        let output = SM64FireSpitterBehavior.update(.init(position: .zero, moveYaw: 0, action: 0, timer: 151, scale: 1, scaleVelocity: 0, distanceToMario: 500, targetYaw: 0x2000, inWater: false))
        precondition(output.action == 1 && output.timer == 0 && output.scale == 0.998 && output.scaleVelocity == 0.05 && !output.spawnSmallFlame)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.action)); fingerprint=hash(fingerprint,UInt64(output.timer)); fingerprint=hash(fingerprint,UInt64(output.scale.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.scaleVelocity.bitPattern)); fingerprint=hash(fingerprint,output.spawnSmallFlame ? 1:0); print(String(format:"fireSpitterFingerprint=0x%016llx",fingerprint)); print("SM64 Modern fire spitter smoke passed")
    }
}
