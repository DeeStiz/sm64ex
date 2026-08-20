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

private func row(_ output: SM64KoopaFlagOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.timer)), output.pushMarioAway ? 1 : 0]
}

@main
struct SM64KoopaFlagSmoke {
    static func main() {
        let first = SM64KoopaFlagBehavior.update(.init(timer: 0, positionY: 0, hitboxHeight: 700, marioY: 300, marioPunching: false))
        let inside = SM64KoopaFlagBehavior.update(.init(timer: 11, positionY: 0, hitboxHeight: 700, marioY: 300, marioPunching: false))
        let punching = SM64KoopaFlagBehavior.update(.init(timer: 12, positionY: 0, hitboxHeight: 700, marioY: 300, marioPunching: true))
        let outside = SM64KoopaFlagBehavior.update(.init(timer: 13, positionY: 0, hitboxHeight: 700, marioY: 800, marioPunching: false))
        precondition(first.timer == 1 && !first.pushMarioAway)
        precondition(inside.timer == 12 && inside.pushMarioAway)
        precondition(punching.timer == 13 && !punching.pushMarioAway)
        precondition(outside.timer == 14 && !outside.pushMarioAway)
        var fingerprint = offset
        for output in [first, inside, punching, outside] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "koopaFlagFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Koopa Flag smoke passed")
    }
}
