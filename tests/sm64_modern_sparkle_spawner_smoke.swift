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
struct SM64SparkleSpawnerSmoke {
    static func main() {
        let output = SM64SparkleSpawnerBehavior.update(
            .init(
                position: .init(x: 10, y: 20, z: -4),
                timer: 0,
                randomOffset: .init(x: 1, y: 2, z: 3),
                randomScale: 0.5
            )
        )
        precondition(
            output.childPosition == .init(x: 11, y: 22, z: -1)
                && output.childScale == 0.5
                && output.shouldSpawnSparkle
                && !output.shouldDeactivate
        )

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.childPosition.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.childPosition.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.childPosition.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.childScale.bitPattern))
        fingerprint = hash(fingerprint, output.shouldSpawnSparkle ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "sparkleSpawnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern sparkle spawner smoke passed")
    }
}
