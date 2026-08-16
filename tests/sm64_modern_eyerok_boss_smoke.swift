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

private func hashI32(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU32(initial, UInt32(bitPattern: value))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashResult(_ initial: UInt64, _ result: SM64EyerokBossTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU32(initial, UInt32(state.action.rawValue))
    hash = hashI32(hash, state.subAction)
    hash = hashI32(hash, state.numHands)
    hash = hashI32(hash, state.activeHand)
    hash = hashI32(hash, state.busyHand)
    hash = hashI32(hash, state.handSelectionCounter)
    hash = hashI32(hash, state.handSelectionPhase)
    hash = hashFloat(hash, state.handSelectionDirection)
    hash = hashFloat(hash, state.handTargetZ)
    hash = hashFloat(hash, state.handBlend)
    hash = hashFloat(hash, state.positionX)
    hash = hashFloat(hash, state.positionY)
    hash = hashFloat(hash, state.positionZ)
    hash = hashI32(hash, Int32(bitPattern: state.timer))
    hash = hashU32(hash, result.effects.rawValue)
    hash = hashI32(hash, result.dialogID)
    hash = hashU32(hash, UInt32(result.spawnedHands.count))
    for hand in result.spawnedHands {
        hash = hashI32(hash, Int32(hand.side))
        hash = hashU32(hash, hand.model)
        hash = hashFloat(hash, hand.position.x)
        hash = hashFloat(hash, hand.position.y)
        hash = hashFloat(hash, hand.position.z)
        hash = hashI32(hash, Int32(hand.faceYaw))
        hash = hashFloat(hash, hand.scale)
    }
    if let star = result.starPosition {
        hash = hashU32(hash, 1)
        hash = hashFloat(hash, star.x)
        hash = hashFloat(hash, star.y)
        hash = hashFloat(hash, star.z)
    } else {
        hash = hashU32(hash, 0)
    }
    return hashU32(hash, state.markedForDeletion ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernEyerokBossSmoke {
    static func main() {
        var fingerprint = fnvOffset

        var spawnState = SM64EyerokBossState(
            homeX: 100,
            homeY: 50,
            homeZ: -200,
            faceYaw: 0x100
        )
        let spawned = SM64EyerokBossKernel.tick(.init(), state: &spawnState)
        require(spawned.effects == .spawnHands, "Eyerok sleep hand spawn effect")
        require(spawned.spawnedHands.count == 2, "Eyerok hand count")
        require(spawned.spawnedHands[0] == SM64EyerokHandSpawn(
            side: -1,
            model: SM64EyerokBossKernel.leftHandModel,
            position: SM64ObjectVector3(x: 600, y: 50, z: 100),
            faceYaw: 0x4100,
            scale: 1.5
        ), "Eyerok left hand source transform")
        require(spawned.spawnedHands[1] == SM64EyerokHandSpawn(
            side: 1,
            model: SM64EyerokBossKernel.rightHandModel,
            position: SM64ObjectVector3(x: -400, y: 50, z: 100),
            faceYaw: -0x3F00,
            scale: 1.5
        ), "Eyerok right hand source transform")
        fingerprint = hashResult(fingerprint, spawned)

        spawnState.timer = 1
        let waking = SM64EyerokBossKernel.tick(
            .init(distanceToMario: 400),
            state: &spawnState
        )
        require(waking.state.action == .wakeUp, "Eyerok sleep wake transition")
        require(waking.effects == .explodeSound, "Eyerok wake sound")
        fingerprint = hashResult(fingerprint, waking)

        var introState = SM64EyerokBossState(homeX: 100, homeY: 50, homeZ: -200)
        introState.action = .wakeUp
        introState.timer = 6
        let intro = SM64EyerokBossKernel.tick(
            .init(marioReadyToSpeak: true),
            state: &introState
        )
        require(intro.state.action == .showIntroText, "Eyerok intro action")
        require(intro.state.subAction == 1, "Eyerok boss music subaction")
        require(intro.dialogID == SM64EyerokBossKernel.introDialogID, "Eyerok intro dialog")
        require(intro.effects.contains([.bossMusic, .dialog]), "Eyerok intro effects")
        fingerprint = hashResult(fingerprint, intro)

        let fight = SM64EyerokBossKernel.tick(
            .init(dialogComplete: true),
            state: &introState
        )
        require(fight.state.action == .fight, "Eyerok fight transition")
        fingerprint = hashResult(fingerprint, fight)

        var selectState = SM64EyerokBossState(homeZ: 100, positionZ: 100)
        selectState.action = .fight
        let select = SM64EyerokBossKernel.tick(
            .init(marioRelativeZ: 100),
            state: &selectState
        )
        require(select.state.handSelectionPhase == -8, "Eyerok Mario-near phase")
        require(select.state.handBlend == 1, "Eyerok Mario-near blend")
        fingerprint = hashResult(fingerprint, select)

        var doubleState = SM64EyerokBossState(homeZ: 100, positionZ: 100)
        doubleState.action = .fight
        doubleState.handSelectionCounter = 5
        let doublePound = SM64EyerokBossKernel.tick(
            .init(marioRelativeZ: 1_000, marioPositionZ: 10_000, randomLowBit: true),
            state: &doubleState
        )
        require(doublePound.state.handSelectionPhase == 8, "Eyerok double-pound phase")
        require(doublePound.state.handSelectionCounter == 1, "Eyerok random counter")
        require(doublePound.state.handSelectionDirection == -1, "Eyerok random direction")
        require(doublePound.state.handTargetZ == 1_700, "Eyerok target clamp")
        require(doublePound.effects == .selectDoublePound, "Eyerok double-pound effect")
        fingerprint = hashResult(fingerprint, doublePound)

        var deathState = SM64EyerokBossState()
        deathState.action = .fight
        deathState.numHands = 0
        let death = SM64EyerokBossKernel.tick(.init(), state: &deathState)
        require(death.state.action == .die, "Eyerok die transition")
        fingerprint = hashResult(fingerprint, death)

        deathState.timer = 60
        let rewardWait = SM64EyerokBossKernel.tick(.init(), state: &deathState)
        require(rewardWait.dialogID == SM64EyerokBossKernel.defeatDialogID, "Eyerok defeat dialog")
        require(rewardWait.starPosition == nil, "Eyerok waits for defeat dialog")
        require(deathState.timer == 60, "Eyerok defeat timer holds")
        fingerprint = hashResult(fingerprint, rewardWait)

        let reward = SM64EyerokBossKernel.tick(
            .init(dialogComplete: true),
            state: &deathState
        )
        require(reward.starPosition == SM64EyerokBossKernel.starPosition, "Eyerok star position")
        require(reward.effects.contains(.star), "Eyerok star effect")
        fingerprint = hashResult(fingerprint, reward)

        deathState.timer = 121
        let retired = SM64EyerokBossKernel.tick(.init(), state: &deathState)
        require(retired.effects.contains([.stopBossMusic, .markForDeletion]), "Eyerok retirement effects")
        require(retired.state.markedForDeletion, "Eyerok retirement state")
        fingerprint = hashResult(fingerprint, retired)

        print(String(format: "eyerokBossFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Eyerok boss smoke passed")
    }
}
