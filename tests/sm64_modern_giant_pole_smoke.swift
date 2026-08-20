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

private func row(_ output: SM64GiantPoleOutput) -> [UInt64] {
    [
        UInt64(bitPattern: Int64(output.timer)),
        UInt64(output.hitboxRadius.bitPattern),
        UInt64(output.hitboxHeight.bitPattern),
        output.spawnTopBall ? 1 : 0,
        UInt64(output.topBallPosition.y.bitPattern),
    ]
}

@main
struct SM64GiantPoleSmoke {
    static func main() {
        let first = SM64GiantPoleBehavior.update(.init(timer: 0, position: .init(x: 10, y: 20, z: 30), hitboxHeight: 2_100, topBallPresent: false))
        let later = SM64GiantPoleBehavior.update(.init(timer: 1, position: .init(x: 10, y: 20, z: 30), hitboxHeight: 2_100, topBallPresent: true))
        precondition(first.timer == 1 && first.spawnTopBall && first.topBallPosition == .init(x: 10, y: 2_170, z: 30))
        precondition(later.timer == 2 && !later.spawnTopBall)
        var fingerprint = offset
        for output in [first, later] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "giantPoleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Giant Pole smoke passed")
    }
}
