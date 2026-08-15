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

private func append(_ output: SM64TTCSpinnerOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.angleVelocityPitch)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.direction))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.changeDirectionTimer))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.facePitch)))
}

@main
enum SM64ModernTTCSpinnerSmoke {
    static func main() {
        let slow = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(speedSetting: 0, timer: 0, changeDirectionTimer: 0,
                                direction: 1, facePitch: 0x1000, randomDirection: -1,
                                randomChangeDirectionTimer: 20)
        )
        let fast = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(speedSetting: 1, timer: 0, changeDirectionTimer: 0,
                                direction: -1, facePitch: 0x1000, randomDirection: 1,
                                randomChangeDirectionTimer: 20)
        )
        let stopped = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(speedSetting: 3, timer: 0, changeDirectionTimer: 0,
                                direction: 1, facePitch: 0x1000, randomDirection: -1,
                                randomChangeDirectionTimer: 20)
        )
        let randomPause = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(speedSetting: 2, timer: 5, changeDirectionTimer: 20,
                                direction: -1, facePitch: 0x1000, randomDirection: 1,
                                randomChangeDirectionTimer: 10)
        )
        let randomMove = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(speedSetting: 2, timer: 6, changeDirectionTimer: 20,
                                direction: -1, facePitch: 0x1000, randomDirection: 1,
                                randomChangeDirectionTimer: 10)
        )
        let randomChange = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(speedSetting: 2, timer: 21, changeDirectionTimer: 20,
                                direction: -1, facePitch: Int16(bitPattern: 0x7FFF), randomDirection: -1,
                                randomChangeDirectionTimer: 30)
        )

        precondition(slow.angleVelocityPitch == 200 && slow.facePitch == 0x10C8)
        precondition(fast.angleVelocityPitch == 600 && fast.facePitch == 0x1258)
        precondition(stopped.angleVelocityPitch == 0 && stopped.facePitch == 0x1000)
        precondition(randomPause.angleVelocityPitch == 0 && randomPause.facePitch == 0x1000)
        precondition(randomMove.angleVelocityPitch == -200 && randomMove.facePitch == 0x0F38)
        precondition(randomChange.angleVelocityPitch == 200 && randomChange.direction == -1
                     && randomChange.changeDirectionTimer == 30 && randomChange.timer == 0
                     && randomChange.facePitch == Int16(bitPattern: 0x7FFF + 200))

        var fingerprint = fnvOffset
        append(slow, to: &fingerprint)
        append(fast, to: &fingerprint)
        append(stopped, to: &fingerprint)
        append(randomPause, to: &fingerprint)
        append(randomMove, to: &fingerprint)
        append(randomChange, to: &fingerprint)
        print(String(format: "ttcSpinnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC spinner smoke passed")
    }
}
