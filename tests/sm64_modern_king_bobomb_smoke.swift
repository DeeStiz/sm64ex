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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashState(_ initial: UInt64, _ state: SM64KingBobombState) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.subAction)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.health)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.animationPhase)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.grabTurnTimer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.grabEscapeCount)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.releaseCooldown)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.interactionMode)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashFloat(hash, state.forwardVelocity)
    hash = hashFloat(hash, state.velocityY)
    hash = hashFloat(hash, state.gravity)
    hash = hashFloat(hash, state.homeY)
    hash = hashFloat(hash, state.positionY)
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.tangible ? 1 : 0)
    hash = hashU64(hash, state.hidden ? 1 : 0)
    hash = hashU64(hash, state.holdable ? 1 : 0)
    hash = hashU64(hash, state.usingHomeMovement ? 1 : 0)
    return hashU64(hash, state.interactionGrabCleared ? 1 : 0)
}

private func hashOutput(_ initial: UInt64, _ output: SM64KingBobombOutput) -> UInt64 {
    var hash = hashState(initial, output.state)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.animation)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.dialogID)))
    hash = hashU64(hash, output.dialogRequested ? 1 : 0)
    hash = hashU64(hash, UInt64(output.effects.rawValue))
    hash = hashU64(hash, UInt64(output.soundValues.count))
    for value in output.soundValues { hash = hashU64(hash, UInt64(bitPattern: Int64(value))) }
    hash = hashU64(hash, UInt64(output.soundSpawnerValues.count))
    for value in output.soundSpawnerValues { hash = hashU64(hash, UInt64(bitPattern: Int64(value))) }
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.cameraShake)))
    guard let star = output.starPosition else { return hashU64(hash, 0) }
    hash = hashU64(hash, 1)
    hash = hashFloat(hash, star.x)
    hash = hashFloat(hash, star.y)
    return hashFloat(hash, star.z)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernKingBobombSmoke {
    static func main() {
        var fingerprint = fnvOffset

        var state = SM64KingBobombState()
        var output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(dialogCanActivate: true), state: state
        )
        require(output.state.subAction == 1 && output.effects.contains(.bossMusic), "intro activation")
        fingerprint = hashOutput(fingerprint, output)

        state = output.state
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(dialogComplete: true), state: state
        )
        require(output.state.action == SM64KingBobombBehavior.grabbedAction, "intro dialog enters chase")
        require(output.dialogID == SM64KingBobombBehavior.dialogIntro && output.state.holdable, "intro dialog and holdable")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.grabbedAction
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, animationFrame: 15, animationNearEnd: true), state: state
        )
        require(output.state.animationPhase == 1 && output.cameraShake == 1, "grabbed animation transition")
        fingerprint = hashOutput(fingerprint, output)

        state = output.state
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(angleToMario: 0x2000, positionY: 0), state: state
        )
        require(output.animation == 11 && output.state.forwardVelocity == 3, "grabbed chase")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.heldAction
        state.subAction = 1
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, playerEscapeDelta: 11), state: state
        )
        require(output.state.action == SM64KingBobombBehavior.grabbedAction && output.state.releaseCooldown == 35,
                "grab escape release")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.thrownAction
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, landed: true), state: state
        )
        require(output.state.action == SM64KingBobombBehavior.damagedAction && output.state.health == 2,
                "first thrown hit damages boss")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.damagedAction
        state.grabTurnTimer = 3
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, animationNearEnd: true), state: state
        )
        require(output.state.subAction == 1 && output.state.grabTurnTimer == 4, "damage animation phase")
        fingerprint = hashOutput(fingerprint, output)

        state = output.state
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, animationNearEnd: true), state: state
        )
        require(output.state.subAction == 2 && !output.state.tangible, "damage recovery intangible phase")
        fingerprint = hashOutput(fingerprint, output)

        state = output.state
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(angleToMario: 0, positionY: 0), state: state
        )
        require(output.state.action == SM64KingBobombBehavior.grabbedAction, "damage recovery returns to chase")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.deathAction
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, dialogComplete: true), state: state
        )
        require(output.state.action == SM64KingBobombBehavior.bossWaitAction && output.starPosition != nil,
                "death dialog awards star")
        fingerprint = hashOutput(fingerprint, output)

        state = output.state
        state.timer = 60
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: state.positionY), state: state
        )
        require(output.effects.contains(.stopBossMusic), "boss wait stops music")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.grabbedAction
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, heldState: .held), state: state
        )
        require(output.effects.contains(.unrenderHeld) && !output.state.tangible, "held object branch")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64KingBobombState(positionY: 0)
        state.action = SM64KingBobombBehavior.thrownAction
        output = SM64KingBobombBehavior.update(
            SM64KingBobombInput(positionY: 0, heldState: .thrown), state: state
        )
        require(output.state.positionY == 20 && output.effects.contains(.thrownOrDropped), "thrown object branch")
        fingerprint = hashOutput(fingerprint, output)

        print(String(format: "kingBobombFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb smoke passed")
    }
}
