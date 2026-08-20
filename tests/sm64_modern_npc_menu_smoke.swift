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

private func hashInt(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU64(initial, UInt64(bitPattern: Int64(value)))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashUkiki(_ initial: UInt64, _ output: SM64UkikiOutput) -> UInt64 {
    var hash = hashInt(initial, output.action)
    hash = hashInt(hash, output.subAction)
    hash = hashInt(hash, output.textState)
    hash = hashInt(hash, output.animState)
    hash = hashFloat(hash, output.forwardVelocity)
    hash = hashInt(hash, output.dialogID)
    return hashU64(hash, output.interactionMask == 0 ? 0 : 1)
}

private func hashCage(_ initial: UInt64, _ output: SM64UkikiCageOutput) -> UInt64 {
    var hash = hashInt(initial, output.action)
    hash = hashInt(hash, output.nextAction)
    hash = hashInt(hash, output.faceYaw)
    hash = hashFloat(hash, output.positionY)
    hash = hashU64(hash, output.markForDeletion ? 1 : 0)
    return hashU64(hash, output.spawnStar ? 1 : 0)
}

private func hashMips(_ initial: UInt64, _ output: SM64MipsOutput) -> UInt64 {
    var hash = hashInt(initial, output.action)
    hash = hashInt(hash, output.heldState)
    hash = hashInt(hash, output.starStatus)
    hash = hashFloat(hash, output.forwardVelocity)
    hash = hashInt(hash, output.dialogID)
    hash = hashU64(hash, output.dialogRequested ? 1 : 0)
    return hashU64(hash, output.interactionMask == 0 ? 0 : 1)
}

private func hashToad(_ initial: UInt64, _ output: SM64ToadMessageOutput) -> UInt64 {
    var hash = hashInt(initial, output.state)
    hash = hashInt(hash, output.dialogID)
    hash = hashInt(hash, output.opacity)
    hash = hashU64(hash, output.dialogJingle ? 1 : 0)
    return hashU64(hash, output.spawnStar ? 1 : 0)
}

private func hashMenu(_ initial: UInt64, _ output: SM64MenuButtonOutput) -> UInt64 {
    var hash = hashInt(initial, output.state)
    hash = hashInt(hash, output.timer)
    hash = hashFloat(hash, output.relativeX)
    hash = hashFloat(hash, output.relativeZ)
    hash = hashInt(hash, output.faceYaw)
    return hashFloat(hash, output.scale)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernNpcMenuSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        let ukikiRun = SM64UkikiBehavior.update(.init(
            action: SM64UkikiBehavior.actionIdle,
            subAction: SM64UkikiBehavior.tauntNone,
            behaviorParam: SM64UkikiBehavior.cageParam,
            textState: SM64UkikiBehavior.textDefault,
            hasHat: false,
            heldState: SM64UkikiBehavior.heldFree,
            distanceToMario: 250,
            angleToMario: 0,
            moveYaw: 0,
            positionY: 0,
            marioHasHat: false,
            marioFarAway: false,
            floorAhead: false,
            wallHit: false,
            edgeHit: false,
            marioMovingFastOrInAir: false,
            animationNearEnd: false,
            dialogResult: 0,
            canActivateText: false,
            cageDistance: .greatestFiniteMagnitude,
            cageYaw: 0,
            timer: 0,
            tauntCounter: 0,
            tauntsToBeDone: 2
        ))
        require(ukikiRun.action == SM64UkikiBehavior.actionRun, "Ukiki proximity enters run")
        fingerprint = hashUkiki(fingerprint, ukikiRun)

        let ukikiDialog = SM64UkikiBehavior.update(.init(
            action: SM64UkikiBehavior.actionIdle,
            subAction: SM64UkikiBehavior.tauntNone,
            behaviorParam: SM64UkikiBehavior.cageParam,
            textState: SM64UkikiBehavior.textDefault,
            hasHat: false,
            heldState: SM64UkikiBehavior.heldHeld,
            distanceToMario: 0,
            angleToMario: 0,
            moveYaw: 0,
            positionY: 0,
            marioHasHat: false,
            marioFarAway: false,
            floorAhead: false,
            wallHit: false,
            edgeHit: false,
            marioMovingFastOrInAir: false,
            animationNearEnd: false,
            dialogResult: 0,
            canActivateText: true,
            cageDistance: 0,
            cageYaw: 0,
            timer: 0,
            tauntCounter: 0,
            tauntsToBeDone: 2
        ))
        require(ukikiDialog.dialogID == 79 && ukikiDialog.dialogRequested, "Ukiki cage dialog request")
        fingerprint = hashUkiki(fingerprint, ukikiDialog)

        let cageStar = SM64UkikiCageBehavior.updateStar(.init(
            action: SM64UkikiCageBehavior.starInCage,
            nextAction: 0,
            parentAction: SM64UkikiCageBehavior.cageHide,
            parentPositionX: 2500,
            parentPositionY: -1200,
            parentPositionZ: 1300,
            parentBehaviorParams: 0x0102_0304,
            moveYaw: 0,
            faceYaw: 0,
            landedOrWater: false,
            timer: 0
        ))
        require(cageStar.markForDeletion && cageStar.spawnStar && cageStar.faceYaw == 0x400, "Ukiki cage star release")
        fingerprint = hashCage(fingerprint, cageStar)

        let mipsInit = SM64MipsBehavior.initialize(starCount: 15, starFlags: 0)
        require(mipsInit.active && mipsInit.encounter == 0 && mipsInit.forwardVelocity == 40, "MIPS first encounter gate")
        fingerprint = hashInt(fingerprint, mipsInit.active ? 1 : 0)
        fingerprint = hashInt(fingerprint, mipsInit.encounter)
        fingerprint = hashFloat(fingerprint, mipsInit.forwardVelocity)

        let mipsHeld = SM64MipsBehavior.update(.init(
            action: SM64MipsBehavior.waitForNearbyMario,
            heldState: SM64MipsBehavior.heldHeld,
            encounter: 0,
            starStatus: SM64MipsBehavior.starNotSpawned,
            forwardVelocity: 40,
            nearbyMario: false,
            waypointAvailable: false,
            pathReachedEnd: false,
            animationNearEnd: false,
            grounded: false,
            underwater: false,
            dialogReady: true,
            dialogCompleted: true,
            timer: 0
        ))
        require(mipsHeld.dialogID == 84 && mipsHeld.starStatus == SM64MipsBehavior.starShouldSpawn, "MIPS dialog/reward gate")
        fingerprint = hashMips(fingerprint, mipsHeld)

        let toadInit = SM64ToadMessageBehavior.initialize(dialogID: 82, starCount: 12, saveFlags: 0)
        require(toadInit.active && toadInit.opacity == 81, "Toad star gate")
        fingerprint = hashInt(fingerprint, toadInit.active ? 1 : 0)
        fingerprint = hashInt(fingerprint, toadInit.dialogID)
        fingerprint = hashInt(fingerprint, toadInit.opacity)
        let toadVisible = SM64ToadMessageBehavior.update(.init(
            state: SM64ToadMessageBehavior.faded,
            dialogID: toadInit.dialogID,
            recentlyTalked: false,
            opacity: toadInit.opacity,
            distanceToMario: 500,
            interacted: false,
            dialogCompleted: false,
            renderActive: true
        ))
        require(toadVisible.state == SM64ToadMessageBehavior.opacifying, "Toad fade-in gate")
        fingerprint = hashToad(fingerprint, toadVisible)

        var menu = SM64MenuButtonBehavior.initialize(relativeX: 160, relativeY: 80)
        menu = SM64MenuButtonBehavior.update(.init(
            state: SM64MenuButtonBehavior.growing,
            timer: 0,
            menuLevel: SM64MenuButtonBehavior.mainMenu,
            originalX: menu.originalX,
            originalY: menu.originalY,
            originalZ: 0,
            relativeX: menu.relativeX,
            relativeY: menu.relativeY,
            relativeZ: menu.relativeZ,
            facePitch: 0,
            faceYaw: 0,
            scale: 1,
            legacyDomainAdvances: true
        ))
        require(menu.timer == 1 && menu.faceYaw == 0x800 && menu.relativeZ == 1112.5, "Menu button grow step")
        fingerprint = hashMenu(fingerprint, menu)

        let manager = SM64MenuButtonManagerBehavior.initialize()
        require(manager.selectedButtonID == -1 && manager.initializedChildCount == 8, "Menu manager initialization")
        fingerprint = hashInt(fingerprint, manager.selectedButtonID)
        fingerprint = hashInt(fingerprint, manager.initializedChildCount)

        // Owner smoke: verify generation-safe registration and record updates
        // without requiring central dispatch integration.
        let state = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64UkikiObjectBridge()
        let id = try bridge.spawn(in: state, position: .zero)
        bridge.setEnvironment(.init(), for: id)
        _ = bridge.tick(state: state, environments: [id: .init()])
        require(bridge.registeredIDs == [id], "Ukiki owner registration")
        _ = state.objects.markForDeletion(id)
        let retired = bridge.tick(state: state)
        require(retired.unloaded.contains(id) && bridge.registeredIDs.isEmpty, "Ukiki owner retirement")

        print(String(format: "npcMenuFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern NPC/menu Swift smoke passed")
    }
}
