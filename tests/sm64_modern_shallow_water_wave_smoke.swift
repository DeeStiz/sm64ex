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
struct SM64ShallowWaterWaveSmoke {
    static func main() {
        let output = SM64ShallowWaterWaveBehavior.update(
            SM64ShallowWaterWaveInput(
                kind: .wave,
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                timer: 0,
                activeParticleFlags: 1 << 10,
                particleFlag: 1 << 10,
                waterLevel: 100
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 10, y: 20, z: -4)
                && output.spawnDropletCount == 5
                && output.clearParticleFlag
                && !output.shouldDeactivate
        )
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.spawnDropletCount)))
        fingerprint = hash(fingerprint, output.clearParticleFlag ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        let splash = SM64ShallowWaterWaveBehavior.update(
            SM64ShallowWaterWaveInput(
                kind: .splash,
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                timer: 0,
                activeParticleFlags: 1 << 12,
                particleFlag: 1 << 12,
                waterLevel: 100
            )
        )
        precondition(splash.spawnDropletCount == 18 && splash.clearParticleFlag && !splash.shouldDeactivate)
        fingerprint = hash(fingerprint, UInt64(splash.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(splash.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(splash.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(splash.spawnDropletCount)))
        fingerprint = hash(fingerprint, splash.clearParticleFlag ? 1 : 0)
        fingerprint = hash(fingerprint, splash.shouldDeactivate ? 1 : 0)
        print(String(format: "shallowWaterWaveFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern shallow-water-wave smoke passed")
    }
}
