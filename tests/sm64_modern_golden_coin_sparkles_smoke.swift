import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64GoldenCoinSparklesSmoke {
    static func main() {
        let output = SM64GoldenCoinSparklesBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), randomOffsets: [.init(x: 1, y: 0, z: 2), .init(x: -3, y: 0, z: 4), .init(x: 5, y: 0, z: -6)]))
        precondition(output.childPositions == [.init(x: 11, y: 20, z: -2), .init(x: 7, y: 20, z: 0), .init(x: 15, y: 20, z: -10)] && output.childPositions.count == 3 && output.shouldSpawnChildren && output.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.childPositions.count))
        for position in output.childPositions { fingerprint = hash(fingerprint, UInt64(position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(position.z.bitPattern)) }
        fingerprint = hash(fingerprint, output.shouldSpawnChildren ? 1 : 0); fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "goldenCoinSparklesFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern golden coin sparkles smoke passed")
    }
}
