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

private func append(_ output: SM64TTCRotatingSolidOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.rotationDelay))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.soundTimer))
    fingerprint = hashF32(fingerprint, output.verticalVelocity)
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.numberOfTurns))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.faceRoll)))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.angleVelocityRoll)))
    fingerprint = hashU32(fingerprint, output.playedAlertSound ? 1 : 0)
    fingerprint = hashU32(fingerprint, output.playedClickSound ? 1 : 0)
}

@main
enum SM64ModernTTCRotatingSolidSmoke {
    static func main() {
        let cube = SM64TTCRotatingSolidBehavior.initialize(behaviorByte: 0, speedSetting: 0)
        let prism = SM64TTCRotatingSolidBehavior.initialize(behaviorByte: 1, speedSetting: 1)
        precondition(cube.collisionModelIndex == 0 && cube.numberOfSides == 4 && cube.rotationDelay == 120)
        precondition(prism.collisionModelIndex == 1 && prism.numberOfSides == 3 && prism.rotationDelay == 40)

        let waiting = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(speedSetting: 1, timer: 40, rotationDelay: 40,
                                      soundTimer: 0, verticalVelocity: 0, positionY: 100,
                                      homeY: 100, numberOfTurns: 0, numberOfSides: 4,
                                      faceRoll: 0, randomRotationDelay: 7)
        )
        let dipping = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(speedSetting: 1, timer: 41, rotationDelay: 40,
                                      soundTimer: 0, verticalVelocity: -5, positionY: 100,
                                      homeY: 100, numberOfTurns: 0, numberOfSides: 4,
                                      faceRoll: 0, randomRotationDelay: 7)
        )
        let landing = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(speedSetting: 1, timer: 41, rotationDelay: 40,
                                      soundTimer: 0, verticalVelocity: 0.5, positionY: 99.8,
                                      homeY: 100, numberOfTurns: 0, numberOfSides: 4,
                                      faceRoll: 0, randomRotationDelay: 7)
        )
        let alert = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(speedSetting: 1, timer: 41, rotationDelay: 40,
                                      soundTimer: 1, verticalVelocity: 1, positionY: 100,
                                      homeY: 100, numberOfTurns: 0, numberOfSides: 4,
                                      faceRoll: 0, randomRotationDelay: 7)
        )
        let rotate = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(speedSetting: 1, timer: 41, rotationDelay: 40,
                                      soundTimer: 0, verticalVelocity: 1, positionY: 100,
                                      homeY: 100, numberOfTurns: 1, numberOfSides: 4,
                                      faceRoll: 0, randomRotationDelay: 7)
        )
        let click = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(speedSetting: 2, timer: 41, rotationDelay: 40,
                                      soundTimer: 0, verticalVelocity: 1, positionY: 100,
                                      homeY: 100, numberOfTurns: 0, numberOfSides: 4,
                                      faceRoll: 0, randomRotationDelay: 9)
        )

        precondition(waiting.verticalVelocity == -5)
        precondition(dipping.verticalVelocity == -4.5 && dipping.positionY == 95.5)
        precondition(landing.positionY == 100 && landing.soundTimer == 6)
        precondition(alert.playedAlertSound && alert.soundTimer == 0)
        precondition(rotate.faceRoll == 1200 && rotate.angleVelocityRoll == 1200 && !rotate.playedClickSound)
        precondition(click.playedClickSound && click.numberOfTurns == 1 && click.timer == 0
                     && click.rotationDelay == 9)

        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(dipping, to: &fingerprint)
        append(landing, to: &fingerprint)
        append(alert, to: &fingerprint)
        append(rotate, to: &fingerprint)
        append(click, to: &fingerprint)
        print(String(format: "ttcRotatingSolidFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC rotating-solid smoke passed")
    }
}
