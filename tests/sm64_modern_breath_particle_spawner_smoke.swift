import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

@main
struct SM64BreathParticleSpawnerSmoke {
    static func main() {
        let output = SM64BreathParticleSpawnerBehavior.update(
            SM64BreathParticleSpawnerInput(
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                timer: 0,
                activeParticleFlags: 1 << 17,
                particleFlag: 1 << 17
            )
        )
        precondition(output.position == .init(x: 10, y: 20, z: -4) && output.spawnMist && output.clearParticleFlag && !output.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, output.spawnMist ? 1 : 0)
        fingerprint = hash(fingerprint, output.clearParticleFlag ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "breathParticleSpawnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern breath particle spawner smoke passed")
    }
}
