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

private func hashI16(_ initial: UInt64, _ value: Int16) -> UInt64 {
    hashU32(initial, UInt32(UInt16(bitPattern: value)))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashOptionalFloat(_ initial: UInt64, _ value: Float?) -> UInt64 {
    hashU32(initial, value?.bitPattern ?? 0)
}

private func hashOutput(_ initial: UInt64, _ output: SM64RacingPenguinOutput) -> UInt64 {
    var hash = initial
    hash = hashI32(hash, output.action)
    hash = hashI32(hash, output.initTextCooldown)
    hash = hashFloat(hash, output.forwardVelocity)
    hash = hashFloat(hash, output.weightedTargetSpeed)
    hash = hashI16(hash, output.moveYaw)
    hash = hashI16(hash, output.angleVelocityYaw)
    hash = hashI32(hash, output.animation)
    hash = hashFloat(hash, output.animationSpeed)
    hash = hashI32(hash, output.finalTextbox)
    hash = hashU32(hash, output.marioWon ? 1 : 0)
    hash = hashU32(hash, output.marioCheated ? 1 : 0)
    hash = hashU32(hash, output.reachedBottom ? 1 : 0)
    hash = hashU32(hash, output.resetTimer ? 1 : 0)
    hash = hashOptionalFloat(hash, output.setVelocityY)
    hash = hashU32(hash, output.attachRaceObjects ? 1 : 0)
    hash = hashU32(hash, output.initializePath ? 1 : 0)
    hash = hashU32(hash, output.playRoughSlideSound ? 1 : 0)
    hash = hashU32(hash, output.playWalkingSound ? 1 : 0)
    hash = hashU32(hash, output.playPoundingSound ? 1 : 0)
    hash = hashU32(hash, output.cameraShakeSmall ? 1 : 0)
    hash = hashU32(hash, output.spawnSmoke ? 1 : 0)
    hash = hashU32(hash, output.spawnStar ? 1 : 0)
    return hashU32(hash, output.finalDialogCompleted ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func input(
    action: Int32,
    timer: Int32 = 0,
    positionY: Float = 0,
    marioPositionY: Float = 0,
    initTextCooldown: Int32 = 0,
    canActivateInitialText: Bool = false,
    initialDialogResponse: Int32 = 0,
    raceBeginComplete: Bool = false,
    pathStatus: Int32 = SM64RacingPenguinBehavior.pathNone,
    pathWaypointFlags: UInt32 = 0,
    pathTargetYaw: Int16 = 0,
    moveFlags: UInt32 = 0,
    animationAtEnd: Bool = false,
    finalAnimationAtEnd: Bool = false,
    canActivateFinalText: Bool = false,
    finalDialogResult: Int32 = 0,
    finalTextbox: Int32 = 0,
    marioWon: Bool = false,
    marioCheated: Bool = false,
    weightedTargetSpeed: Float = 0,
    forwardVelocity: Float = 0,
    moveYaw: Int16 = 0,
    marioInAirAction: Bool = false
) -> SM64RacingPenguinInput {
    SM64RacingPenguinInput(
        action: action,
        timer: timer,
        positionY: positionY,
        marioPositionY: marioPositionY,
        initTextCooldown: initTextCooldown,
        canActivateInitialText: canActivateInitialText,
        initialDialogResponse: initialDialogResponse,
        raceBeginComplete: raceBeginComplete,
        pathStatus: pathStatus,
        pathWaypointFlags: pathWaypointFlags,
        pathTargetYaw: pathTargetYaw,
        moveFlags: moveFlags,
        animationAtEnd: animationAtEnd,
        finalAnimationAtEnd: finalAnimationAtEnd,
        canActivateFinalText: canActivateFinalText,
        finalDialogResult: finalDialogResult,
        finalTextbox: finalTextbox,
        marioWon: marioWon,
        marioCheated: marioCheated,
        weightedTargetSpeed: weightedTargetSpeed,
        forwardVelocity: forwardVelocity,
        moveYaw: moveYaw,
        marioInAirAction: marioInAirAction
    )
}

@main
enum SM64ModernRacingPenguinSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let waiting = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.waitForMario,
            timer: 11,
            positionY: 0,
            marioPositionY: 100,
            initTextCooldown: 10,
            canActivateInitialText: true
        ))
        require(waiting.action == SM64RacingPenguinBehavior.showInitText, "penguin enters init dialog")
        fingerprint = hashOutput(fingerprint, waiting)

        let accepted = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showInitText,
            initialDialogResponse: 1
        ))
        require(accepted.action == SM64RacingPenguinBehavior.prepareForRace, "accepted race proposal prepares")
        require(accepted.attachRaceObjects && accepted.initializePath, "race children and path are initialized")
        require(accepted.setVelocityY == 60, "race start jump velocity")
        fingerprint = hashOutput(fingerprint, accepted)

        let preparing = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.prepareForRace,
            moveYaw: 0
        ))
        require(preparing.moveYaw == 2_500 && preparing.angleVelocityYaw == 2_500, "prepare turn increment")
        fingerprint = hashOutput(fingerprint, preparing)

        let started = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.prepareForRace,
            raceBeginComplete: true,
            moveYaw: preparing.moveYaw
        ))
        require(started.action == SM64RacingPenguinBehavior.race && started.forwardVelocity == 20, "race begins after start gate")
        fingerprint = hashOutput(fingerprint, started)

        let racing = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.race,
            positionY: 500,
            marioPositionY: 300,
            pathWaypointFlags: 0x20,
            pathTargetYaw: 6_000,
            forwardVelocity: started.forwardVelocity,
            moveYaw: started.moveYaw
        ))
        require(racing.forwardVelocity == 20.4, "race speed approaches the computed target")
        require(racing.weightedTargetSpeed == 30, "race weighted target approaches uphill")
        require(racing.resetTimer, "grounded Mario clears cheat timer")
        fingerprint = hashOutput(fingerprint, racing)

        let lowWaypoint = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.race,
            timer: 61,
            positionY: 110,
            marioPositionY: 100,
            pathWaypointFlags: 35,
            pathTargetYaw: 6_000,
            moveFlags: SM64RacingPenguinBehavior.moveOnGround,
            animationAtEnd: true,
            weightedTargetSpeed: racing.weightedTargetSpeed,
            forwardVelocity: racing.forwardVelocity,
            moveYaw: racing.moveYaw,
            marioInAirAction: true
        ))
        require(lowWaypoint.weightedTargetSpeed == -70, "race weighted target approaches downhill")
        require(lowWaypoint.forwardVelocity == 20.8, "race minimum speed remains approached")
        require(lowWaypoint.marioCheated && lowWaypoint.spawnSmoke, "airborne shortcut and landing smoke intents")
        fingerprint = hashOutput(fingerprint, lowWaypoint)

        let reachedEnd = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.race,
            pathStatus: SM64RacingPenguinBehavior.pathReachedEnd,
            forwardVelocity: lowWaypoint.forwardVelocity,
            marioInAirAction: false
        ))
        require(reachedEnd.action == SM64RacingPenguinBehavior.finishRace && reachedEnd.reachedBottom, "path end enters finish")
        fingerprint = hashOutput(fingerprint, reachedEnd)

        let wallStop = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.finishRace,
            timer: 6,
            moveFlags: SM64RacingPenguinBehavior.moveHitWall,
            forwardVelocity: lowWaypoint.forwardVelocity
        ))
        require(wallStop.forwardVelocity == 0 && wallStop.playPoundingSound && wallStop.cameraShakeSmall, "finish wall stop")
        fingerprint = hashOutput(fingerprint, wallStop)

        let finalAction = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.finishRace,
            finalAnimationAtEnd: true,
            forwardVelocity: 0
        ))
        require(finalAction.action == SM64RacingPenguinBehavior.showFinalText, "finish animation enters final dialog")
        fingerprint = hashOutput(fingerprint, finalAction)

        let turningHome = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showFinalText,
            marioWon: true,
            marioCheated: true,
            moveYaw: 1_000
        ))
        require(turningHome.moveYaw == 800 && turningHome.forwardVelocity == 4, "final presentation turns and walks")
        fingerprint = hashOutput(fingerprint, turningHome)

        let cheatedDialog = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showFinalText,
            canActivateFinalText: true,
            marioWon: true,
            marioCheated: true,
            moveYaw: 0
        ))
        require(cheatedDialog.finalTextbox == SM64RacingPenguinBehavior.dialogCheatedWin && !cheatedDialog.marioWon, "cheated win dialog clears reward")
        fingerprint = hashOutput(fingerprint, cheatedDialog)

        let completedDialog = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showFinalText,
            finalDialogResult: 1,
            finalTextbox: cheatedDialog.finalTextbox
        ))
        require(completedDialog.finalTextbox == -1 && completedDialog.finalDialogCompleted, "dialog completion sentinel")
        fingerprint = hashOutput(fingerprint, completedDialog)

        let cleanWinDialog = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showFinalText,
            canActivateFinalText: true,
            marioWon: true,
            moveYaw: 0
        ))
        require(cleanWinDialog.finalTextbox == SM64RacingPenguinBehavior.dialogWin, "clean win dialog")
        fingerprint = hashOutput(fingerprint, cleanWinDialog)

        let cleanWinCompleted = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showFinalText,
            finalDialogResult: 1,
            finalTextbox: cleanWinDialog.finalTextbox,
            marioWon: true
        ))
        require(cleanWinCompleted.finalTextbox == -1 && cleanWinCompleted.marioWon, "clean win preserves reward")
        fingerprint = hashOutput(fingerprint, cleanWinCompleted)

        let reward = SM64RacingPenguinBehavior.update(input(
            action: SM64RacingPenguinBehavior.showFinalText,
            finalTextbox: -1,
            marioWon: cleanWinCompleted.marioWon
        ))
        require(reward.spawnStar && !reward.marioWon, "clean win spawns star once")
        fingerprint = hashOutput(fingerprint, reward)

        print(String(format: "racingPenguinFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin smoke passed")
    }
}
