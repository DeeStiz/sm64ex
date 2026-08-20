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

private func row(_ output: SM64TrackBallOutput) -> [UInt64] {
    [
        UInt64(bitPattern: Int64(output.relativeIndex)),
        output.shouldDelete ? 1 : 0,
    ]
}

@main
struct SM64TrackBallSmoke {
    static func main() {
        let active = SM64TrackBallBehavior.update(.init(behaviorByte: 6, parentBaseBallIndex: 0))
        let first = SM64TrackBallBehavior.update(.init(behaviorByte: 1, parentBaseBallIndex: -1))
        let stale = SM64TrackBallBehavior.update(.init(behaviorByte: 0, parentBaseBallIndex: 0))
        let wrapped = SM64TrackBallBehavior.update(.init(behaviorByte: 0x1_0001, parentBaseBallIndex: 0))
        precondition(active.relativeIndex == 5 && !active.shouldDelete)
        precondition(first.relativeIndex == 1 && !first.shouldDelete)
        precondition(stale.relativeIndex == -1 && stale.shouldDelete)
        precondition(wrapped.relativeIndex == 0 && wrapped.shouldDelete)

        var fingerprint = offset
        for output in [active, first, stale, wrapped] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "trackBallFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern track ball smoke passed")
    }
}
