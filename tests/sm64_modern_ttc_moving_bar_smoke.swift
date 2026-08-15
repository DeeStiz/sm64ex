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

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func append(_ output: SM64TTCMovingBarOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.delay))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.stoppedTimer))
    fingerprint = hashF32(fingerprint, output.offset)
    fingerprint = hashF32(fingerprint, output.speed)
    fingerprint = hashF32(fingerprint, output.startOffset)
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.moveYaw)))
}

@main
enum SM64ModernTTCMovingBarSmoke {
    static func main() {
        let slowInit = SM64TTCMovingBarBehavior.initialize(speedSetting: 0, behaviorByte: 2, faceYaw: 0x1000)
        let stoppedInit = SM64TTCMovingBarBehavior.initialize(speedSetting: 3, behaviorByte: 1, faceYaw: 0x1000)
        precondition(slowInit.delay == 55 && slowInit.offset == 0 && slowInit.stoppedTimer == 20
                     && slowInit.moveYaw == 0x3000)
        precondition(stoppedInit.delay == 0 && stoppedInit.offset == 250 && stoppedInit.moveYaw == 0x3000)

        let waiting = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 0, action: 0, timer: 55, delay: 55,
                                  stoppedTimer: 0, offset: 0, speed: 0, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: false)
        )
        let startsPull = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 0, action: 0, timer: 56, delay: 55,
                                  stoppedTimer: 0, offset: 0, speed: 0, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: false)
        )
        let pull = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 0, action: 1, timer: 0, delay: 55,
                                  stoppedTimer: 0, offset: 0, speed: -8, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: false)
        )
        let pullToExtend = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 0, action: 1, timer: 0, delay: 55,
                                  stoppedTimer: 0, offset: 0, speed: -0.5, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: false)
        )
        let crossed = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 0, action: 2, timer: 0, delay: 55,
                                  stoppedTimer: 0, offset: 249, speed: 2, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: false)
        )
        let fakeout = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 2, action: 2, timer: 0, delay: 55,
                                  stoppedTimer: 0, offset: -1, speed: 2, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: true)
        )
        let reset = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(speedSetting: 0, action: 3, timer: 31, delay: 55,
                                  stoppedTimer: 0, offset: 0, speed: -5, faceYaw: 0x1000,
                                  randomDelay: 12, randomPauseSelected: false,
                                  randomPauseTimer: 0, randomFakeout: false)
        )

        precondition(waiting.action == 0 && waiting.offset == 0)
        precondition(startsPull.action == 1 && startsPull.speed == -8)
        precondition(pull.action == 1 && pull.speed == -7.27)
        precondition(pullToExtend.action == 2 && pullToExtend.speed == 29)
        precondition(crossed.action == 3 && crossed.offset == 251 && crossed.speed == 0)
        precondition(fakeout.action == 0 && fakeout.offset == 0 && fakeout.speed == 0)
        precondition(reset.action == 0 && reset.offset == 0 && reset.speed == 0)

        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(startsPull, to: &fingerprint)
        append(pull, to: &fingerprint)
        append(pullToExtend, to: &fingerprint)
        append(crossed, to: &fingerprint)
        append(fakeout, to: &fingerprint)
        append(reset, to: &fingerprint)
        print(String(format: "ttcMovingBarFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC moving bar smoke passed")
    }
}
