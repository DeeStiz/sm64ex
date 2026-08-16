import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashState(_ initial: UInt64, _ state: SM64YoshiState) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.timer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.chosenHome)))
    hash = hashU64(hash, UInt64(state.homeX.bitPattern))
    hash = hashU64(hash, UInt64(state.homeZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    return hashU64(hash, UInt64(state.blinkTimer))
}

private func hashOutput(_ initial: UInt64, _ output: SM64YoshiOutput) -> UInt64 {
    var hash = hashState(initial, output.state)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.animation)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.dialogID)))
    hash = hashU64(hash, output.dialogRequested ? 1 : 0)
    hash = hashU64(hash, output.activeTimeStop ? 1 : 0)
    hash = hashU64(hash, output.clearTimeStop ? 1 : 0)
    hash = hashU64(hash, output.clearInteraction ? 1 : 0)
    hash = hashU64(hash, output.playWalkSound ? 1 : 0)
    hash = hashU64(hash, output.playPuzzleJingle ? 1 : 0)
    hash = hashU64(hash, output.playAlertSound ? 1 : 0)
    hash = hashU64(hash, output.playExtraLifeSound ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.livesDelta)))
    hash = hashU64(hash, output.specialTripleJump ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.cameraRequest)))
    hash = hashU64(hash, output.respawnerRequested ? 1 : 0)
    return hashU64(hash, output.deactivated ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernYoshiSmoke {
    static func main() {
        var state = SM64YoshiState()
        var fingerprint = fnvOffset

        var output = SM64YoshiBehavior.update(
            SM64YoshiInput(totalStars: 119),
            state: state
        )
        require(output.deactivated, "sub-120-star Yoshi is deactivated at init gate")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64YoshiState()
        output = SM64YoshiBehavior.update(
            SM64YoshiInput(
                timer: 91,
                positionX: 0,
                positionY: 3_174,
                positionZ: -5_625,
                randomChosenHome: 1,
                randomBlinkTimer: 7
            ),
            state: state
        )
        require(output.state.action == SM64YoshiBehavior.walkAction, "idle selects a new home and walks")
        require(output.state.homeX == -1_364 && output.state.homeZ == -5_912, "home table parity")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(animationFrame: 0, timer: 1, angleToMario: 0x4000, randomBlinkTimer: 8),
            state: state
        )
        require(output.playWalkSound && output.state.forwardVelocity == 10, "walk velocity and sound")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(timer: 2, angleToMario: 0x4000, interacted: true, randomBlinkTimer: 9),
            state: state
        )
        require(output.state.action == SM64YoshiBehavior.talkAction, "walk interaction enters talk")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(timer: 3, angleToMario: 0x5000, randomBlinkTimer: 10),
            state: state
        )
        require(output.playPuzzleJingle && output.state.moveYaw != 0x5000, "talk turns with puzzle jingle")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(
                positionX: 0,
                positionZ: -5_625,
                angleToMario: state.moveYaw,
                dialogOpenResult: 2,
                dialogResult: 1,
                randomBlinkTimer: 11
            ),
            state: state
        )
        require(output.dialogID == SM64YoshiBehavior.dialogID && output.dialogRequested, "Yoshi dialog route")
        require(output.state.action == SM64YoshiBehavior.givePresentAction, "dialog enters present action")
        require(output.activeTimeStop && output.clearTimeStop && output.clearInteraction, "dialog time-stop cleanup")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(globalTimer: 4, lives: 3, randomBlinkTimer: 12),
            state: state
        )
        require(output.livesDelta == 1 && output.playExtraLifeSound, "present grants life on four-frame cadence")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(globalTimer: 5, lives: 100, randomBlinkTimer: 13),
            state: state
        )
        require(output.specialTripleJump && output.state.action == SM64YoshiBehavior.walkJumpOffRoofAction, "full lives starts roof jump")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(animationFrame: 0, timer: 0, closeToHome: true, randomBlinkTimer: 14),
            state: state
        )
        require(output.cameraRequest == 1 && output.playAlertSound, "roof jump camera and landing alert")
        require(output.state.action == SM64YoshiBehavior.finishJumpingAndDespawnAction, "roof jump enters finish")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64YoshiBehavior.update(
            SM64YoshiInput(positionY: 2_000, randomBlinkTimer: 15),
            state: state
        )
        require(output.deactivated && output.clearTimeStop, "finish branch despawns below roof")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64YoshiState()
        output = SM64YoshiBehavior.update(
            SM64YoshiInput(endingCameraEvent: true, randomBlinkTimer: 16),
            state: state
        )
        require(output.state.action == SM64YoshiBehavior.creditsAction, "ending event enters credits")
        fingerprint = hashOutput(fingerprint, output)

        print(String(format: "yoshiFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Yoshi smoke passed")
    }
}
