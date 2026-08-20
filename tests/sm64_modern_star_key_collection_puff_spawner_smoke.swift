import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64StarKeyCollectionPuffSpawnerSmoke {
    static func main() {
        let seeds = Array(repeating: SM64StarKeyPuffSeed(velocity: .init(x: 0, y: 20, z: 1), scale: 3), count: 20)
        let output = SM64StarKeyCollectionPuffSpawnerBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), timer: 0, seeds: seeds))
        precondition(output.position == .init(x: 10, y: 20, z: -4) && output.seeds.count == 20 && output.spawnPuffs && output.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.seeds.count))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, output.spawnPuffs ? 1 : 0)
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "starKeyPuffSpawnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern star-key puff spawner smoke passed")
    }
}
