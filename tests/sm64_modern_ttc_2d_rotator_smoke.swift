import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func append(_ output: SM64TTC2DRotatorOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.minTimeUntilNextTurn))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.targetYaw))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.increment)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.randomDirectionTimer))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.faceYaw)))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.angleVelocityYaw)))
}

@main
enum SM64ModernTTC2DRotatorSmoke {
    static func main() {
        let hand = SM64TTC2DRotatorBehavior.initialize(behaviorByte: 0, speedSetting: 0, faceYaw: 0)
        let cog = SM64TTC2DRotatorBehavior.initialize(behaviorByte: 1, speedSetting: 1, faceYaw: 0x1000)
        precondition(hand.minTimeUntilNextTurn == 40 && hand.increment == -0x444)
        precondition(cog.minTimeUntilNextTurn == 5 && cog.increment == -0xCCC)

        let waiting = SM64TTC2DRotatorBehavior.update(
            SM64TTC2DRotatorInput(speedSetting: 0, behaviorByte: 0, timer: 40,
                                  minTimeUntilNextTurn: 40, targetYaw: 0, increment: -0x444,
                                  speed: -0x444, randomDirectionTimer: 0, faceYaw: 0,
                                  randomUsesSpeed: true, randomSpeedTimer: 90,
                                  randomReverseTimer: 30, randomMinTime: 10)
        )
        let turn = SM64TTC2DRotatorBehavior.update(
            SM64TTC2DRotatorInput(speedSetting: 0, behaviorByte: 0, timer: 41,
                                  minTimeUntilNextTurn: 40, targetYaw: 0, increment: -0x444,
                                  speed: -0x444, randomDirectionTimer: 0, faceYaw: 0,
                                  randomUsesSpeed: true, randomSpeedTimer: 90,
                                  randomReverseTimer: 30, randomMinTime: 10)
        )
        let randomReverse = SM64TTC2DRotatorBehavior.update(
            SM64TTC2DRotatorInput(speedSetting: 2, behaviorByte: 0, timer: 11,
                                  minTimeUntilNextTurn: 10, targetYaw: 0, increment: -0x444,
                                  speed: -0x444, randomDirectionTimer: 0, faceYaw: 0,
                                  randomUsesSpeed: false, randomSpeedTimer: 90,
                                  randomReverseTimer: 30, randomMinTime: 10)
        )
        precondition(waiting.timer == 40 && waiting.targetYaw == 0)
        precondition(turn.timer == 0 && turn.targetYaw == -0x444)
        precondition(randomReverse.increment == 0x444 && randomReverse.randomDirectionTimer == 30)

        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(turn, to: &fingerprint)
        append(randomReverse, to: &fingerprint)
        print(String(format: "ttc2DRotatorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC 2D rotator smoke passed")
    }
}
