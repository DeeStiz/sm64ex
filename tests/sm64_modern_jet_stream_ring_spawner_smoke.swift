import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

private func row(_ output: SM64JetStreamRingSpawnerOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.nextRingIndex)), output.spawnRing ? 1 : 0, UInt64(bitPattern: Int64(output.ringIndex)), output.spawnStar ? 1 : 0]
}

@main
struct SM64JetStreamRingSpawnerSmoke {
    static func main() {
        let first = SM64JetStreamRingSpawnerBehavior.update(.init(action: 0, timer: 0, nextRingIndex: 0, ringsCollected: 0))
        let second = SM64JetStreamRingSpawnerBehavior.update(.init(action: 0, timer: 50, nextRingIndex: 1, ringsCollected: 0))
        let solved = SM64JetStreamRingSpawnerBehavior.update(.init(action: 0, timer: 10, nextRingIndex: 2, ringsCollected: 5))
        precondition(first.spawnRing && first.ringIndex == 0 && first.nextRingIndex == 1 && first.timer == 1)
        precondition(second.spawnRing && second.ringIndex == 1 && second.nextRingIndex == 2 && second.timer == 51)
        precondition(solved.action == 1 && solved.spawnStar)
        var fingerprint = offset
        for output in [first, second, solved] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "jetStreamRingSpawnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Jet Stream ring spawner smoke passed")
    }
}
