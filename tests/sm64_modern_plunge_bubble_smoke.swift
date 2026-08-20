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
struct SM64PlungeBubbleSmoke {
    static func main() {
        let output = SM64PlungeBubbleBehavior.update(
            SM64PlungeBubbleInput(
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                activeParticleFlags: 1 << 9,
                particleFlag: 1 << 9
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 10, y: 20, z: -4)
                && output.spawnParticleCount == 3
                && output.clearParticleFlag
                && output.shouldDeactivate
        )
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.spawnParticleCount)))
        fingerprint = hash(fingerprint, output.clearParticleFlag ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "plungeBubbleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern plunge bubble smoke passed")
    }
}
