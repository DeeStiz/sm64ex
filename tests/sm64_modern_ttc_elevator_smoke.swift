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

private func append(_ output: SM64TTCElevatorOutput, to fingerprint: inout UInt64) {
    fingerprint = hashF32(fingerprint, output.velocityY)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.direction))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.moveTime))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashU32(fingerprint, output.clampedAtEndpoint ? 1 : 0)
}

@main
enum SM64ModernTTCElevatorSmoke {
    static func main() {
        precondition(SM64TTCElevatorBehavior.initialize(positionY: 100, behaviorParameterHigh: 0).peakY == 600)
        precondition(SM64TTCElevatorBehavior.initialize(positionY: 100, behaviorParameterHigh: 4).peakY == 500)

        let slow = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(speedSetting: 0, timer: 10, direction: 1, moveTime: 0,
                                  positionY: 100, homeY: 0, peakY: 600, gravity: 0,
                                  randomSign: -1, randomMoveTime: 20)
        )
        let fast = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(speedSetting: 1, timer: 10, direction: -1, moveTime: 0,
                                  positionY: 100, homeY: 0, peakY: 600, gravity: 0,
                                  randomSign: 1, randomMoveTime: 20)
        )
        let stopped = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(speedSetting: 3, timer: 10, direction: 1, moveTime: 0,
                                  positionY: 100, homeY: 0, peakY: 600, gravity: 0,
                                  randomSign: -1, randomMoveTime: 20)
        )
        let randomPause = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(speedSetting: 2, timer: 3, direction: 1, moveTime: 10,
                                  positionY: 100, homeY: 0, peakY: 600, gravity: 0,
                                  randomSign: -1, randomMoveTime: 20)
        )
        let randomChange = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(speedSetting: 2, timer: 11, direction: 1, moveTime: 10,
                                  positionY: 100, homeY: 0, peakY: 600, gravity: 0,
                                  randomSign: -1, randomMoveTime: 20)
        )
        let endpoint = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(speedSetting: 0, timer: 10, direction: 1, moveTime: 0,
                                  positionY: 598, homeY: 0, peakY: 600, gravity: 0,
                                  randomSign: -1, randomMoveTime: 20)
        )

        precondition(slow.velocityY == 6 && slow.positionY == 106 && slow.direction == 1)
        precondition(fast.velocityY == -10 && fast.positionY == 90)
        precondition(stopped.velocityY == 0 && stopped.positionY == 100)
        precondition(randomPause.velocityY == 0 && randomPause.positionY == 100)
        precondition(randomChange.velocityY == 6 && randomChange.direction == -1
                     && randomChange.moveTime == 20 && randomChange.timer == 0)
        precondition(endpoint.positionY == 600 && endpoint.direction == -1 && endpoint.clampedAtEndpoint)

        var fingerprint = fnvOffset
        append(slow, to: &fingerprint)
        append(fast, to: &fingerprint)
        append(stopped, to: &fingerprint)
        append(randomPause, to: &fingerprint)
        append(randomChange, to: &fingerprint)
        append(endpoint, to: &fingerprint)
        print(String(format: "ttcElevatorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC elevator smoke passed")
    }
}
