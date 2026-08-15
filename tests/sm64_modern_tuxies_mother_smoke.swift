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

private func hashOutput(_ initial: UInt64, _ output: SM64TuxiesMotherOutput) -> UInt64 {
    var hash = initial
    hash = hashU32(hash, UInt32(bitPattern: output.action))
    hash = hashU32(hash, UInt32(bitPattern: output.subAction))
    hash = hashF32(hash, output.scale)
    hash = hashU32(hash, UInt32(bitPattern: output.animation))
    hash = hashF32(hash, output.forwardVelocity)
    hash = hashU32(hash, UInt32(UInt16(bitPattern: output.moveYaw)))
    hash = hashU32(hash, UInt32(UInt16(bitPattern: output.angleVelocityYaw)))
    hash = hashU32(hash, UInt32(bitPattern: output.dialogID))
    hash = hashU32(hash, output.dialogRequested ? 1 : 0)
    hash = hashU32(hash, output.childSmallPenguinUnk88 ? 1 : 0)
    hash = hashU32(hash, output.childInteractionSetMask)
    hash = hashU32(hash, output.clearChildDropImmediate ? 1 : 0)
    hash = hashU32(hash, UInt32(bitPattern: output.childBehavior))
    hash = hashU32(hash, output.spawnStar ? 1 : 0)
    if let starHomePosition = output.starHomePosition {
        hash = hashU32(hash, 1)
        hash = hashF32(hash, starHomePosition.x)
        hash = hashF32(hash, starHomePosition.y)
        hash = hashF32(hash, starHomePosition.z)
    } else {
        hash = hashU32(hash, 0)
    }
    hash = hashF32(hash, output.starSpawnYOffset)
    hash = hashU32(hash, output.playWalkingSound ? 1 : 0)
    hash = hashU32(hash, output.playYellSound ? 1 : 0)
    hash = hashU32(hash, output.activeFlagUnk10 ? 1 : 0)
    return hashU32(hash, output.clearInteractionStatus ? 1 : 0)
}

private func input(
    action: Int32,
    subAction: Int32 = SM64TuxiesMotherBehavior.subIdle,
    motherBehaviorParam: UInt8 = 1,
    childBehaviorParam: UInt8 = 1,
    childExists: Bool = true,
    childDistance: Float = 600,
    childHeldState: Int32 = SM64TuxiesMotherBehavior.heldFree,
    nearbyHeldActor: Bool = false,
    lateralDistanceToMarioHome: Float = 0,
    marioOnPlatform: Bool = false,
    canActivateText: Bool = false,
    dialogResult: Int32 = 0,
    angleToMario: Int16 = 0,
    moveYaw: Int16 = 0,
    soundStateID: Int32 = 1,
    animationFrameOne: Bool = false
) -> SM64TuxiesMotherInput {
    SM64TuxiesMotherInput(
        action: action,
        subAction: subAction,
        motherBehaviorParam: motherBehaviorParam,
        childBehaviorParam: childBehaviorParam,
        childExists: childExists,
        childDistance: childDistance,
        childHeldState: childHeldState,
        nearbyHeldActor: nearbyHeldActor,
        lateralDistanceToMarioHome: lateralDistanceToMarioHome,
        marioOnPlatform: marioOnPlatform,
        canActivateText: canActivateText,
        dialogResult: dialogResult,
        angleToMario: angleToMario,
        moveYaw: moveYaw,
        soundStateID: soundStateID,
        animationFrameOne: animationFrameOne
    )
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernTuxiesMotherSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let startsDialog = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.followChild,
            childDistance: 600,
            canActivateText: true
        ))
        require(startsDialog.subAction == SM64TuxiesMotherBehavior.subDialog, "mother arms initial dialog")
        require(!startsDialog.dialogRequested, "initial activation is a one-frame gate")
        fingerprint = hashOutput(fingerprint, startsDialog)

        let initialDialog = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.followChild,
            subAction: SM64TuxiesMotherBehavior.subDialog
        ))
        require(initialDialog.dialogID == SM64TuxiesMotherBehavior.dialogInitial && initialDialog.dialogRequested, "initial dialog id")
        fingerprint = hashOutput(fingerprint, initialDialog)

        let initialAccepted = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.followChild,
            subAction: SM64TuxiesMotherBehavior.subDialog,
            dialogResult: 1
        ))
        require(initialAccepted.subAction == SM64TuxiesMotherBehavior.subWaitForDrop, "initial dialog advances to held-child wait")
        fingerprint = hashOutput(fingerprint, initialAccepted)

        let attachesChild = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.followChild,
            subAction: SM64TuxiesMotherBehavior.subWaitForDrop,
            childDistance: 250,
            childHeldState: 1
        ))
        require(attachesChild.action == SM64TuxiesMotherBehavior.carryingChild, "held child enters mother action")
        require(attachesChild.childSmallPenguinUnk88, "held child receives mother link intent")
        fingerprint = hashOutput(fingerprint, attachesChild)

        let correctDialog = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.carryingChild,
            motherBehaviorParam: 1,
            childBehaviorParam: 1,
            childHeldState: 1
        ))
        require(correctDialog.dialogID == SM64TuxiesMotherBehavior.dialogCorrectChild, "correct-child dialog")
        fingerprint = hashOutput(fingerprint, correctDialog)

        let correctAccepted = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.carryingChild,
            motherBehaviorParam: 1,
            childBehaviorParam: 1,
            childHeldState: 1,
            dialogResult: 1
        ))
        require(correctAccepted.subAction == SM64TuxiesMotherBehavior.subDialog, "correct dialog enters reward branch")
        require(correctAccepted.childInteractionSetMask == SM64TuxiesMotherBehavior.interactionDropImmediately, "drop-immediately mask")
        fingerprint = hashOutput(fingerprint, correctAccepted)

        let reward = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.carryingChild,
            subAction: SM64TuxiesMotherBehavior.subDialog,
            childHeldState: SM64TuxiesMotherBehavior.heldFree
        ))
        require(reward.action == SM64TuxiesMotherBehavior.chaseMario && reward.spawnStar, "correct child reward star")
        require(reward.clearChildDropImmediate && reward.childBehavior == SM64TuxiesMotherBehavior.childUnusedBehavior, "correct child release mutation")
        require(reward.starHomePosition == SM64TuxiesMotherBehavior.starHomePosition, "Tuxie reward target")
        fingerprint = hashOutput(fingerprint, reward)

        let wrongDialog = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.carryingChild,
            motherBehaviorParam: 1,
            childBehaviorParam: 2,
            childHeldState: 1
        ))
        require(wrongDialog.dialogID == SM64TuxiesMotherBehavior.dialogWrongChild, "wrong-child dialog")
        fingerprint = hashOutput(fingerprint, wrongDialog)

        let wrongAccepted = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.carryingChild,
            motherBehaviorParam: 1,
            childBehaviorParam: 2,
            childHeldState: 1,
            dialogResult: 1
        ))
        require(wrongAccepted.subAction == SM64TuxiesMotherBehavior.subWaitForDrop, "wrong dialog enters return branch")
        fingerprint = hashOutput(fingerprint, wrongAccepted)

        let returnChild = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.carryingChild,
            subAction: SM64TuxiesMotherBehavior.subWaitForDrop,
            childHeldState: SM64TuxiesMotherBehavior.heldFree
        ))
        require(returnChild.action == SM64TuxiesMotherBehavior.chaseMario, "wrong child release returns to chase")
        require(returnChild.childBehavior == SM64TuxiesMotherBehavior.childBabyBehavior && !returnChild.spawnStar, "wrong child becomes baby")
        fingerprint = hashOutput(fingerprint, returnChild)

        let chases = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.chaseMario,
            nearbyHeldActor: true,
            lateralDistanceToMarioHome: 900,
            angleToMario: 4_000,
            moveYaw: 0,
            soundStateID: 1
        ))
        require(chases.forwardVelocity == 10 && chases.subAction == SM64TuxiesMotherBehavior.subDialog, "mother chases held actor")
        require(chases.moveYaw == 1_024 && chases.angleVelocityYaw == 1_024, "mother chase yaw")
        fingerprint = hashOutput(fingerprint, chases)

        let stopsChasing = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.chaseMario,
            subAction: SM64TuxiesMotherBehavior.subDialog,
            nearbyHeldActor: true,
            lateralDistanceToMarioHome: 600,
            soundStateID: 1
        ))
        require(stopsChasing.subAction == SM64TuxiesMotherBehavior.subIdle && stopsChasing.animation == SM64TuxiesMotherBehavior.idleAnimation, "mother resumes idle chase")
        fingerprint = hashOutput(fingerprint, stopsChasing)

        let audio = SM64TuxiesMotherBehavior.update(input(
            action: SM64TuxiesMotherBehavior.followChild,
            soundStateID: 0,
            animationFrameOne: true
        ))
        require(audio.playWalkingSound && audio.animation == SM64TuxiesMotherBehavior.walkAnimation, "mother walking audio")
        require(audio.playYellSound, "mother yell frame")
        require(audio.activeFlagUnk10 && audio.clearInteractionStatus, "mother loop flags")
        fingerprint = hashOutput(fingerprint, audio)

        print(String(format: "tuxiesMotherFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Tuxie's mother smoke passed")
    }
}
