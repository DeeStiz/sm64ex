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

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashState(_ initial: UInt64, _ state: SM64SmallPenguinState) -> UInt64 {
    var hash = initial
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.timer)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashF32(hash, state.forwardVelocity)
    hash = hashF32(hash, state.unknown104)
    hash = hashF32(hash, state.unknown108)
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.unknown110)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.diveReturnAction)))
    hash = hashU64(hash, UInt64(state.linkFlag))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.animation)))
    return hashU64(hash, UInt64(bitPattern: Int64(state.heldState)))
}

private func hashOutput(_ initial: UInt64, _ output: SM64SmallPenguinOutput) -> UInt64 {
    var hash = hashState(initial, output.state)
    hash = hashU64(hash, UInt64(UInt16(bitPattern: output.angleVelocityYaw)))
    hash = hashU64(hash, output.resetHome ? 1 : 0)
    hash = hashU64(hash, output.playWalkingSound ? 1 : 0)
    hash = hashU64(hash, output.playDiveSound ? 1 : 0)
    hash = hashU64(hash, output.playHeldYellSound ? 1 : 0)
    hash = hashU64(hash, output.unrenderHeldObject ? 1 : 0)
    hash = hashU64(hash, output.copiedToMario ? 1 : 0)
    hash = hashU64(hash, output.setSmallPenguinBehavior ? 1 : 0)
    hash = hashU64(hash, output.thrown ? 1 : 0)
    return hashU64(hash, output.dropped ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func tick(
    _ state: inout SM64SmallPenguinState,
    _ input: SM64SmallPenguinInput
) -> SM64SmallPenguinOutput {
    let output = SM64SmallPenguinBehavior.update(input, state: state)
    state = output.state
    return output
}

@main
enum SM64ModernSmallPenguinSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let baseInput = SM64SmallPenguinInput(
            distanceToMario: 800,
            angleToMario: 0x200,
            randomUnknown110: 0x100,
            randomUnknown108: 100,
            randomUnknown104: 0.25
        )

        var idle = SM64SmallPenguinState()
        let initialized = tick(&idle, baseInput)
        require(initialized.state.action == SM64SmallPenguinBehavior.moveAwayAction, "idle distance gate")
        require(initialized.state.timer == 1 && initialized.state.forwardVelocity == 0, "idle initialization timing")
        fingerprint = hashOutput(fingerprint, initialized)

        idle.timer = 1
        let movingAway = tick(&idle, baseInput)
        require(movingAway.state.action == SM64SmallPenguinBehavior.moveAwayAction, "move-away action")
        require(movingAway.state.forwardVelocity == 3.25, "move-away speed")
        require(movingAway.state.moveYaw == 0x200 && movingAway.angleVelocityYaw == 0x200, "move-away yaw")
        fingerprint = hashOutput(fingerprint, movingAway)

        let stopAway = tick(&idle, SM64SmallPenguinInput(distanceToMario: 300, angleToMario: 0x200))
        require(stopAway.state.action == SM64SmallPenguinBehavior.idleAction, "move-away close gate")
        require(stopAway.state.forwardVelocity == 3.25, "direct action transition preserves velocity")
        fingerprint = hashOutput(fingerprint, stopAway)

        var toward = SM64SmallPenguinState(
            action: SM64SmallPenguinBehavior.moveTowardAction,
            timer: 4,
            moveYaw: 0,
            forwardVelocity: 0,
            unknown104: 0.5,
            unknown108: 100,
            unknown110: 0x100,
            diveReturnAction: 0,
            linkFlag: 0,
            animation: SM64SmallPenguinBehavior.idleAnimation,
            heldState: SM64SmallPenguinBehavior.heldFree
        )
        let movingToward = tick(
            &toward,
            SM64SmallPenguinInput(distanceToMario: 500, angleToMario: 0)
        )
        require(movingToward.state.moveYaw == -1792 && movingToward.angleVelocityYaw == -1792, "move-toward opposite yaw")
        require(movingToward.state.forwardVelocity == 3.5, "move-toward speed")
        fingerprint = hashOutput(fingerprint, movingToward)

        let stopToward = tick(
            &toward,
            SM64SmallPenguinInput(distanceToMario: 700, angleToMario: 0)
        )
        require(stopToward.state.action == SM64SmallPenguinBehavior.idleAction, "move-toward far gate")
        fingerprint = hashOutput(fingerprint, stopToward)

        var diving = SM64SmallPenguinState(
            action: SM64SmallPenguinBehavior.moveAwayAction,
            timer: 5,
            moveYaw: 0,
            unknown104: 0.25,
            unknown108: 100,
            unknown110: 0x100,
            heldState: SM64SmallPenguinBehavior.heldFree
        )
        let diveStart = tick(
            &diving,
            SM64SmallPenguinInput(distanceToMario: 800, angleToMario: 0, marioDiveSliding: true)
        )
        require(diveStart.state.action == SM64SmallPenguinBehavior.diveAction, "dive starts from movement")
        require(diveStart.state.diveReturnAction == SM64SmallPenguinBehavior.moveAwayAction, "dive return action")
        fingerprint = hashOutput(fingerprint, diveStart)

        diving.timer = 6
        let diveSound = tick(
            &diving,
            SM64SmallPenguinInput(marioDiveSliding: true)
        )
        require(diveSound.state.animation == SM64SmallPenguinBehavior.diveAnimation && diveSound.playDiveSound, "dive animation and sound")
        fingerprint = hashOutput(fingerprint, diveSound)

        diving.timer = 26
        let diveComplete = tick(&diving, SM64SmallPenguinInput())
        require(diveComplete.state.action == SM64SmallPenguinBehavior.recoverAction, "dive recovery transition")
        fingerprint = hashOutput(fingerprint, diveComplete)

        diving.timer = 21
        let recover = tick(&diving, SM64SmallPenguinInput())
        require(recover.state.forwardVelocity == 0 && recover.state.animation == SM64SmallPenguinBehavior.recoverAnimation, "recovery animation")
        fingerprint = hashOutput(fingerprint, recover)

        diving.timer = 41
        let returnAction = tick(&diving, SM64SmallPenguinInput())
        require(returnAction.state.action == SM64SmallPenguinBehavior.moveAwayAction, "dive returns to source action")
        fingerprint = hashOutput(fingerprint, returnAction)

        var following = SM64SmallPenguinState(
            action: SM64SmallPenguinBehavior.followMotherAction,
            timer: 3,
            moveYaw: 0,
            heldState: SM64SmallPenguinBehavior.heldFree
        )
        let follow = tick(
            &following,
            SM64SmallPenguinInput(
                distanceToMario: 500,
                nearestMotherExists: true,
                nearestMotherDistance: 250,
                angleToMother: 0x400
            )
        )
        require(follow.state.forwardVelocity == 2 && follow.state.moveYaw == 0x400, "follow mother route")
        fingerprint = hashOutput(fingerprint, follow)

        following.linkFlag = 1
        following.action = SM64SmallPenguinBehavior.idleAction
        let linked = tick(
            &following,
            SM64SmallPenguinInput(
                distanceToMario: 500,
                nearestMotherExists: true,
                nearestMotherDistance: 250,
                angleToMother: 0x400
            )
        )
        require(linked.state.action == SM64SmallPenguinBehavior.followMotherAction && linked.state.linkFlag == 0, "mother link flag")
        fingerprint = hashOutput(fingerprint, linked)

        var held = SM64SmallPenguinState(heldState: SM64SmallPenguinBehavior.heldHeld)
        let heldTick = tick(
            &held,
            SM64SmallPenguinInput(globalTimer: 30, hasBabyBehavior: true)
        )
        require(heldTick.unrenderHeldObject && heldTick.copiedToMario && heldTick.setSmallPenguinBehavior, "held child route")
        require(heldTick.playHeldYellSound, "held child yell cadence")
        fingerprint = hashOutput(fingerprint, heldTick)

        var thrown = SM64SmallPenguinState(heldState: SM64SmallPenguinBehavior.heldThrown)
        let thrownTick = tick(&thrown, SM64SmallPenguinInput())
        require(thrownTick.thrown, "thrown child route")
        fingerprint = hashOutput(fingerprint, thrownTick)

        var dropped = SM64SmallPenguinState(heldState: SM64SmallPenguinBehavior.heldDropped)
        let droppedTick = tick(&dropped, SM64SmallPenguinInput())
        require(droppedTick.dropped, "dropped child route")
        fingerprint = hashOutput(fingerprint, droppedTick)

        var farAway = SM64SmallPenguinState(timer: 1)
        let reset = tick(
            &farAway,
            SM64SmallPenguinInput(distanceToMario: 10_000, marioFarAway: true)
        )
        require(reset.resetHome, "far-away home reset")
        fingerprint = hashOutput(fingerprint, reset)

        print(String(format: "smallPenguinFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern small penguin smoke passed")
    }
}
