import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
private func hash(_ seed: UInt64, _ output: SM64ThwompOutput) -> UInt64 {
    var result = hash(seed, UInt64(output.variant.rawValue)); result = hash(result, UInt64(output.action.rawValue)); result = hash(result, output.timer); result = hash(result, output.positionY); result = hash(result, output.velocityY); result = hash(result, UInt64(output.sound ? 1 : 0)); return hash(result, UInt64(output.shake ? 1 : 0))
}

@main
struct SM64ThwompSmoke {
    static func main() {
        let rows = [
            SM64ThwompBehavior.update(.init(variant: .grindel, action: .wait, timer: 40, behaviorByte: 0, positionY: 100, homeY: 100, velocityY: 0, distanceToMario: 2000, randomWaitTimer: 20, randomPauseTimer: 20)),
            SM64ThwompBehavior.update(.init(variant: .thwomp, action: .wait, timer: 41, behaviorByte: 0, positionY: 100, homeY: 100, velocityY: 0, distanceToMario: 2000, randomWaitTimer: 20, randomPauseTimer: 20)),
            SM64ThwompBehavior.update(.init(variant: .thwomp2, action: .startFall, timer: 21, behaviorByte: 0, positionY: 105, homeY: 100, velocityY: 0, distanceToMario: 2000, randomWaitTimer: 20, randomPauseTimer: 20)),
            SM64ThwompBehavior.update(.init(variant: .thwomp, action: .falling, timer: 0, behaviorByte: 0, positionY: 100, homeY: 100, velocityY: 0, distanceToMario: 2000, randomWaitTimer: 20, randomPauseTimer: 20)),
            SM64ThwompBehavior.update(.init(variant: .thwomp, action: .landed, timer: 0, behaviorByte: 0, positionY: 100, homeY: 100, velocityY: 0, distanceToMario: 1000, randomWaitTimer: 20, randomPauseTimer: 20)),
        ]
        precondition(rows[0].action == .wait && rows[0].positionY == 110 && rows[0].timer == 41)
        precondition(rows[1].action == .startFall && rows[1].positionY == 105 && rows[1].timer == 0)
        precondition(rows[2].action == .falling && rows[2].timer == 0)
        precondition(rows[3].action == .landed && rows[3].positionY == 100 && rows[3].velocityY == 0 && rows[3].timer == 0)
        precondition(rows[4].sound && rows[4].shake && rows[4].action == .landed && rows[4].timer == 1)
        var fingerprint = offset; for row in rows { fingerprint = hash(fingerprint, row) }
        print(String(format: "thwompFingerprint=0x%016llx", fingerprint)); print("SM64 Modern Thwomp smoke passed")
    }
}
