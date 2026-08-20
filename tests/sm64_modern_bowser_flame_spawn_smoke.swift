import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64BowserFlameSpawnSmoke {
    static func main() {
        let output = SM64BowserFlameSpawnBehavior.update(.init(objectPosition: .zero, bowserPosition: .init(x: 10, y: 20, z: -4), bowserYaw: 0, bowserSoundState: 6, animationFrame: 49, animationEndFrame: 100, sampleX: 1, sampleY: 2, sampleZ: 3, samplePitch: 4, sampleYaw: 5))
        precondition(output.position == .init(x: 11, y: 22, z: -1) && output.moveYaw == 5 && output.movePitch == 0xC04 && output.shouldSpawnFlame)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.position.x.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.y.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.z.bitPattern)); fingerprint=hash(fingerprint,UInt64(bitPattern:Int64(output.moveYaw))); fingerprint=hash(fingerprint,UInt64(bitPattern:Int64(output.movePitch))); fingerprint=hash(fingerprint,output.shouldSpawnFlame ? 1:0); print(String(format:"bowserFlameSpawnFingerprint=0x%016llx",fingerprint)); print("SM64 Modern Bowser flame spawn smoke passed")
    }
}
