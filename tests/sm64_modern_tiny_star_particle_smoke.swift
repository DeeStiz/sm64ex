import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64TinyStarParticleSmoke {
    static func main() {
        let wall = SM64TinyStarParticleBehavior.update(.init(kind: .wall, position: .zero, marioPosition: .init(x: 100, y: 50, z: -20), marioYaw: 0, timer: 0, moveYaw: 0, forwardVelocity: 25, velocityY: 10, gravity: 0, scale: 1))
        let pound = SM64TinyStarParticleBehavior.update(.init(kind: .pound, position: .init(x: 10, y: 20, z: -4), marioPosition: .zero, marioYaw: 0, timer: 0, moveYaw: 0, forwardVelocity: 0, velocityY: 0, gravity: 0, scale: 1))
        precondition(wall.position == .init(x: 100, y: 90, z: 115) && wall.scale == 0.28 && wall.animationState == 4 && pound.position == .init(x: 10, y: 14, z: 21) && pound.forwardVelocity == 25 && pound.velocityY == 14)
        var fingerprint = fnvOffset
        for output in [wall, pound] { fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.animationState)) }
        print(String(format: "tinyStarParticleFingerprint=0x%016llx", fingerprint)); print("SM64 Modern tiny star particle smoke passed")
    }
}
