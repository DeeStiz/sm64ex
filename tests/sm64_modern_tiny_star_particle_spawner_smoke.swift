import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64TinyStarParticleSpawnerSmoke {
    static func main() {
        let seeds = [SM64TinyStarParticleSeed(moveYaw: 0, forwardVelocity: 25, velocityY: 10), SM64TinyStarParticleSeed(moveYaw: 0x4000, forwardVelocity: 20, velocityY: 15)]
        let output = SM64TinyStarParticleSpawnerBehavior.update(.init(kind: .vertical, position: .zero, timer: 0, activeParticleFlags: 0x2000, particleFlag: 0x2000, seeds: seeds))
        precondition(output.seeds == seeds && output.clearParticleFlag && output.shouldSpawnChildren && !output.shouldDeactivate)
        var fingerprint = fnvOffset; fingerprint = hash(fingerprint, UInt64(output.seeds.count)); fingerprint = hash(fingerprint, output.clearParticleFlag ? 1 : 0); fingerprint = hash(fingerprint, output.shouldSpawnChildren ? 1 : 0); fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "tinyStarParticleSpawnerFingerprint=0x%016llx", fingerprint)); print("SM64 Modern tiny star particle spawner smoke passed")
    }
}
