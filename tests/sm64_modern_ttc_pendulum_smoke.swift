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

private func append(_ output: SM64TTCPendulumOutput, to fingerprint: inout UInt64) {
    fingerprint = hashF32(fingerprint, output.angle)
    fingerprint = hashF32(fingerprint, output.angleVelocity)
    fingerprint = hashF32(fingerprint, output.angleAcceleration)
    fingerprint = hashF32(fingerprint, output.accelerationDirection)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.delay))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.soundTimer))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceRoll))
    fingerprint = hashU32(fingerprint, output.playsSwingSound ? 1 : 0)
}

@main
enum SM64ModernTTCPendulumSmoke {
    static func main() {
        let slowInit = SM64TTCPendulumBehavior.initialize(speedSetting: 0)
        let stoppedInit = SM64TTCPendulumBehavior.initialize(speedSetting: 3)
        precondition(slowInit.angleAcceleration == 13 && slowInit.angle == 6500)
        precondition(stoppedInit.angleAcceleration == 0 && stoppedInit.angle == 6371.5557)

        let accelerating = SM64TTCPendulumBehavior.update(
            SM64TTCPendulumInput(speedSetting: 0, angle: 6500, angleVelocity: 0,
                                  angleAcceleration: 13, accelerationDirection: 1,
                                  delay: 0, soundTimer: 0, randomAccelerationUses13: true,
                                  randomDelayIsEven: false, randomDelay: 0)
        )
        let delayed = SM64TTCPendulumBehavior.update(
            SM64TTCPendulumInput(speedSetting: 0, angle: -100, angleVelocity: 5,
                                  angleAcceleration: 13, accelerationDirection: 1,
                                  delay: 2, soundTimer: 0, randomAccelerationUses13: true,
                                  randomDelayIsEven: false, randomDelay: 0)
        )
        let sound = SM64TTCPendulumBehavior.update(
            SM64TTCPendulumInput(speedSetting: 0, angle: 0, angleVelocity: 0,
                                  angleAcceleration: 13, accelerationDirection: 1,
                                  delay: 0, soundTimer: 1, randomAccelerationUses13: true,
                                  randomDelayIsEven: false, randomDelay: 0)
        )
        let randomZero = SM64TTCPendulumBehavior.update(
            SM64TTCPendulumInput(speedSetting: 2, angle: 0, angleVelocity: -13,
                                  angleAcceleration: 13, accelerationDirection: 1,
                                  delay: 0, soundTimer: 0, randomAccelerationUses13: false,
                                  randomDelayIsEven: true, randomDelay: 7)
        )
        let stopped = SM64TTCPendulumBehavior.update(
            SM64TTCPendulumInput(speedSetting: 3, angle: 6371.5557, angleVelocity: 99,
                                  angleAcceleration: 22, accelerationDirection: -1,
                                  delay: 4, soundTimer: 2, randomAccelerationUses13: true,
                                  randomDelayIsEven: true, randomDelay: 8)
        )

        precondition(accelerating.angle == 6487 && accelerating.angleVelocity == -13
                     && accelerating.accelerationDirection == -1 && accelerating.faceRoll == 6487)
        precondition(delayed.angle == -100 && delayed.angleVelocity == 5 && delayed.delay == 1)
        precondition(sound.playsSwingSound && sound.soundTimer == 0 && sound.angle == 13)
        precondition(randomZero.angleVelocity == 0 && randomZero.angleAcceleration == 42
                     && randomZero.delay == 7 && randomZero.soundTimer == 22)
        precondition(stopped.angle == 6371.5557 && stopped.angleVelocity == 99
                     && stopped.delay == 4 && !stopped.playsSwingSound)

        var fingerprint = fnvOffset
        append(accelerating, to: &fingerprint)
        append(delayed, to: &fingerprint)
        append(sound, to: &fingerprint)
        append(randomZero, to: &fingerprint)
        append(stopped, to: &fingerprint)
        print(String(format: "ttcPendulumFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC pendulum smoke passed")
    }
}
