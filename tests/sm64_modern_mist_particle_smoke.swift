import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64MistParticleSmoke {
    static func main() {
        let puff1 = SM64MistParticleBehavior.update(.init(kind: .puff1, position: .init(x: 10, y: 20, z: -4), timer: 0, animationState: 0, initialOffsetX: 1, initialOffsetZ: 2, moveYaw: 0, forwardVelocity: 0, velocityY: 0))
        precondition(puff1.position == .init(x: 11, y: 50, z: -2) && puff1.scale == 0.1 && puff1.opacity == 50 && !puff1.shouldDelete)
        let spawner = SM64MistParticleSpawnerBehavior.update(.init(position: .zero, timer: 0, activeParticleFlags: 1, particleFlag: 1))
        precondition(spawner.spawnPuff1 && spawner.spawnPuff2 && spawner.clearParticleFlag && !spawner.shouldDeactivate)
        var fingerprint = fnvOffset; fingerprint = hash(fingerprint, UInt64(puff1.position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(puff1.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(puff1.position.z.bitPattern)); fingerprint = hash(fingerprint, UInt64(puff1.scale.bitPattern)); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(puff1.opacity))); fingerprint = hash(fingerprint, spawner.spawnPuff1 ? 1 : 0); fingerprint = hash(fingerprint, spawner.spawnPuff2 ? 1 : 0); print(String(format: "mistParticleFingerprint=0x%016llx", fingerprint)); print("SM64 Modern mist particle smoke passed")
    }
}
