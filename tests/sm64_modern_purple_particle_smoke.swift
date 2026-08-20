import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64PurpleParticleSmoke {
    static func main() {
        let output = SM64PurpleParticleBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), timer: 0, moveYaw: 0x4000, forwardVelocity: 0, velocityY: 0, randomForwardUnit: 0.5, randomVerticalUnit: 0.25))
        precondition(output.forwardVelocity == 30 && output.velocityY == 25 && output.position.x > 30 && output.position.z < -3 && !output.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.forwardVelocity.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.velocityY.bitPattern)); fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "purpleParticleFingerprint=0x%016llx", fingerprint)); print("SM64 Modern purple particle smoke passed")
    }
}
