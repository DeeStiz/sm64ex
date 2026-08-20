import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64FlamethrowerSmoke {
    static func main() {
        let output = SM64FlamethrowerBehavior.update(.init(position: .zero, action: 0, timer: 0, behaviorParam: 0, distanceToMario: 1000, activationAllowed: true))
        precondition(output.action == 1 && output.timer == 0 && output.spawnFlame == false && output.flameVelocity == 95)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.action)); fingerprint=hash(fingerprint,UInt64(output.timer)); fingerprint=hash(fingerprint,output.spawnFlame ? 1:0); fingerprint=hash(fingerprint,UInt64(output.flameVelocity.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.flameLifetime)); print(String(format:"flamethrowerFingerprint=0x%016llx",fingerprint)); print("SM64 Modern flamethrower smoke passed")
    }
}
