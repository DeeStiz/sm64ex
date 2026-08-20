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
struct SM64StrongWindParticleSmoke {
    static func main() {
        let output = SM64StrongWindParticleBehavior.update(
            SM64StrongWindParticleInput(
                kind: .visible,
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                moveYaw: 0,
                movePitch: 0,
                forwardVelocity: 0,
                velocityY: 0,
                timer: 0,
                initialRandomX: 1,
                initialRandomY: 2,
                initialRandomZ: 3,
                initialYawJitter: 0,
                windSpread: 0,
                penguinCollisionPosition: nil
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 111, y: 22, z: -1)
                && output.forwardVelocity == 100
                && output.velocityY == 0
                && output.opacity == 100
                && !output.shouldDelete
        )
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.forwardVelocity.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.velocityY.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.opacity)))
        fingerprint = hash(fingerprint, output.intangible ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        print(String(format: "strongWindParticleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern strong wind particle smoke passed")
    }

}
