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
struct SM64WaterParticleSmoke {
    static func main() {
        let output = SM64WaterParticleBehavior.update(
            SM64WaterParticleInput(
                kind: .small,
                position: SM64ObjectVector3(x: 11, y: 22, z: -1),
                angleX: 0,
                angleZ: 0,
                angleVelocityX: 0x800,
                angleVelocityZ: 0x800,
                timer: 0,
                waterLevel: 100,
                randomStepX: 0.5,
                randomStepZ: -0.5
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 11.5, y: 27, z: -1.5)
                && output.scaleX == 2
                && output.scaleY == 2
                && output.timer == 1
                && !output.spawnObjectSplash
        )
        let bubbles = SM64WaterParticleBehavior.update(
            SM64WaterParticleInput(
                kind: .bubbles,
                position: SM64ObjectVector3(x: 0, y: 100, z: 0),
                angleX: 0,
                angleZ: 0,
                angleVelocityX: 0x800,
                angleVelocityZ: 0x800,
                timer: 1,
                waterLevel: 0,
                randomStepX: 0,
                randomStepZ: 0
            )
        )
        precondition(!bubbles.shouldDelete && !bubbles.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.scaleX.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.scaleY.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.angleX)))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.angleZ)))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
        fingerprint = hash(fingerprint, output.spawnObjectSplash ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "waterParticleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern water particle smoke passed")
    }
}
