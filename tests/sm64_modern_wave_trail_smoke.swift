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
struct SM64WaveTrailSmoke {
    static func main() {
        let output = SM64WaveTrailBehavior.update(
            SM64WaveTrailInput(
                kind: .mario,
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                waterLevel: 100,
                timer: 0,
                globalFrame: 0,
                animationState: -1,
                waveTrailSize: 1,
                initialScale: 1
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 10, y: 105, z: -4)
                && output.animationState == 0
                && output.waveTrailSize == 1
                && !output.shouldDelete
                && !output.shouldDeactivate
        )
        let odd = SM64WaveTrailBehavior.update(
            SM64WaveTrailInput(
                kind: .object,
                position: .zero,
                waterLevel: 100,
                timer: 0,
                globalFrame: 1,
                animationState: -1,
                waveTrailSize: 1,
                initialScale: 1
            )
        )
        precondition(odd.shouldDelete && odd.kind == .object)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.animationState)))
        fingerprint = hash(fingerprint, UInt64(output.waveTrailSize.bitPattern))
        fingerprint = hash(fingerprint, output.clearParticleFlag ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "waveTrailFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern wave trail smoke passed")
    }
}
