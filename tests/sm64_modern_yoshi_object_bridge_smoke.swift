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

private func hashID(_ initial: UInt64, _ id: SM64ObjectID?) -> UInt64 {
    guard let id else { return hashU64(initial, 0) }
    var hash = hashU64(initial, 1)
    hash = hashU64(hash, UInt64(id.slot))
    return hashU64(hash, UInt64(id.generation))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashIntent(_ initial: UInt64, _ intent: SM64OwnerThreadEffectIntent) -> UInt64 {
    var hash = hashU64(initial, intent.sequence)
    hash = hashID(hash, intent.objectID)
    hash = hashU64(hash, UInt64(intent.kind.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    return hashU64(hash, UInt64(bitPattern: Int64(intent.auxiliary)))
}

private func hashState(_ initial: UInt64, _ state: SM64YoshiState) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.timer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.chosenHome)))
    hash = hashFloat(hash, state.homeX)
    hash = hashFloat(hash, state.homeZ)
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashFloat(hash, state.forwardVelocity)
    hash = hashFloat(hash, state.velocityY)
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

private func hashIDs(_ initial: UInt64, _ ids: [SM64ObjectID]) -> UInt64 {
    var hash = hashU64(initial, UInt64(ids.count))
    for id in ids { hash = hashID(hash, id) }
    return hash
}

private func hashDelivery(
    _ initial: UInt64,
    _ delivery: SM64OwnerThreadEffectDeliveryResult
) -> UInt64 {
    var hash = hashU64(initial, UInt64(delivery.delivered.count))
    for intent in delivery.delivered { hash = hashIntent(hash, intent) }
    hash = hashU64(hash, UInt64(delivery.presented.count))
    for intent in delivery.presented { hash = hashIntent(hash, intent) }
    hash = hashIDs(hash, delivery.spawned)
    hash = hashIDs(hash, delivery.deleted)
    hash = hashU64(hash, UInt64(delivery.rejected.count))
    for intent in delivery.rejected { hash = hashIntent(hash, intent) }
    return hash
}

private func hashRecord(_ initial: UInt64, _ record: SM64ObjectRecord?) -> UInt64 {
    guard let record else { return hashU64(initial, 0) }
    var hash = hashU64(initial, 1)
    hash = hashID(hash, record.id)
    hash = hashU64(hash, UInt64(record.objectList.rawValue))
    hash = hashU64(hash, UInt64(record.activeFlags))
    hash = hashU64(hash, UInt64(record.objectFlags))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.previousAction)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.timer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.behaviorParams)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.behaviorParams2ndByte)))
    hash = hashU64(hash, UInt64(record.interactionSubtype))
    hash = hashFloat(hash, record.drawingDistance)
    hash = hashFloat(hash, record.gravity)
    hash = hashFloat(hash, record.friction)
    hash = hashFloat(hash, record.buoyancy)
    hash = hashFloat(hash, record.position.x)
    hash = hashFloat(hash, record.position.y)
    hash = hashFloat(hash, record.position.z)
    hash = hashFloat(hash, record.homePosition.x)
    hash = hashFloat(hash, record.homePosition.z)
    hash = hashU64(hash, UInt64(record.respawnInfoType))
    return hashU64(hash, record.respawnInfoIdentity)
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64YoshiSchedulerTickResult,
    records: [SM64ObjectRecord?]
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    hash = hashU64(hash, UInt64(tick.scheduler.listCounts.count))
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashIDs(hash, tick.scheduler.updated)
    hash = hashIDs(hash, tick.scheduler.skippedByTimeStop)
    hash = hashIDs(hash, tick.scheduler.unloaded)
    hash = hashU64(hash, tick.scheduler.timeStopWasActive ? 1 : 0)
    hash = hashU64(hash, tick.scheduler.timeStopIsActive ? 1 : 0)
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashID(hash, effect.objectID)
        hash = hashOutput(hash, effect.output)
        hash = hashIDs(hash, effect.spawnedRespawners)
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        for intent in effect.presentedEffects { hash = hashIntent(hash, intent) }
    }
    hash = hashU64(hash, UInt64(tick.deliveries.count))
    for delivery in tick.deliveries { hash = hashDelivery(hash, delivery) }
    for record in records { hash = hashRecord(hash, record) }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func environment(
    totalStars: Int32 = 120,
    timer: Int32 = 0,
    positionY: Float = 3_174,
    animationFrame: Int16 = 0,
    angleToMario: Int16 = 0,
    interacted: Bool = false,
    dialogOpenResult: Int32 = 0,
    dialogResult: Int32 = 0,
    closeToHome: Bool = false,
    endingCameraEvent: Bool = false,
    globalTimer: UInt64 = 0,
    lives: Int32 = 3
) -> SM64YoshiEnvironment {
    SM64YoshiEnvironment(input: SM64YoshiInput(
        totalStars: totalStars,
        animationFrame: animationFrame,
        timer: timer,
        positionY: positionY,
        closeToHome: closeToHome,
        angleToMario: angleToMario,
        interacted: interacted,
        dialogOpenResult: dialogOpenResult,
        dialogResult: dialogResult,
        endingCameraEvent: endingCameraEvent,
        globalTimer: globalTimer,
        lives: lives
    ))
}

@main
enum SM64ModernYoshiObjectBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64YoshiObjectBridge()
        var fingerprint = fnvOffset

        let gated = try bridge.spawnYoshi(in: engine)
        var tick = bridge.tick(state: engine, environments: [gated: environment(totalStars: 119)])
        require(tick.scheduler.unloaded == [gated], "star gate unloads Yoshi")
        require(tick.effects.first?.output.deactivated == true, "star gate emits deactivation")
        require(tick.deliveries.first?.deleted == [gated], "deactivation is owner-deleted")
        fingerprint = hashTick(fingerprint, tick, records: [engine.objects.record(for: gated)])

        let buddy = try bridge.spawnYoshi(in: engine, action: SM64YoshiBehavior.talkAction)
        require(buddy.generation == 2, "pool generation advances after gate unload")
        tick = bridge.tick(state: engine, environments: [buddy: environment(
            dialogOpenResult: 2,
            dialogResult: 1
        )])
        require(tick.effects.first?.output.dialogID == SM64YoshiBehavior.dialogID, "dialog reaches owner bridge")
        require(tick.effects.first?.presentedEffects.contains(where: { $0.kind == .dialog && $0.value == 161 }) == true, "dialog is presented")
        require(engine.globals.timeStopState.isEmpty, "dialog cleanup leaves no stale time stop")
        require(engine.objects.record(for: buddy)?.activeFlags == 257, "dialog cleanup clears initiated flag")
        fingerprint = hashTick(fingerprint, tick, records: [engine.objects.record(for: buddy)])

        tick = bridge.tick(state: engine, environments: [buddy: environment(globalTimer: 4, lives: 3)])
        require(tick.effects.first?.output.livesDelta == 1, "present cadence grants life")
        require(tick.effects.first?.presentedEffects.first?.value == SM64YoshiObjectBridge.gainLifeSoundValue, "life sound is routed")
        fingerprint = hashTick(fingerprint, tick, records: [engine.objects.record(for: buddy)])

        require(bridge.attach(
            buddy,
            action: SM64YoshiBehavior.walkJumpOffRoofAction,
            in: engine.objects
        ), "roof jump reattaches")
        tick = bridge.tick(state: engine, environments: [buddy: environment(
            animationFrame: 0,
            closeToHome: true
        )])
        require(tick.effects.first?.output.cameraRequest == 1, "roof jump requests camera")
        require(tick.effects.first?.presentedEffects.count == 3, "walk, alert, and camera effects present")
        require(bridge.state(for: buddy)?.action == SM64YoshiBehavior.finishJumpingAndDespawnAction, "roof jump enters finish")
        fingerprint = hashTick(fingerprint, tick, records: [engine.objects.record(for: buddy)])

        tick = bridge.tick(state: engine, environments: [buddy: environment(positionY: 2_000)])
        require(tick.scheduler.unloaded == [buddy], "finish unloads Yoshi")
        require(tick.deliveries.first?.deleted == [buddy], "finish routes deletion")
        fingerprint = hashTick(fingerprint, tick, records: [engine.objects.record(for: buddy)])

        let respawnSource = try bridge.spawnYoshi(in: engine, action: SM64YoshiBehavior.walkAction)
        require(respawnSource.generation == 3, "second reuse generation")
        tick = bridge.tick(state: engine, environments: [respawnSource: environment(
            positionY: 1_000,
            animationFrame: 1
        )])
        let respawner = tick.effects.first?.spawnedRespawners.first
        require(respawner != nil, "roof failure spawns respawner")
        require(tick.scheduler.unloaded == [respawnSource, respawner!], "roof failure orders source and respawner unload")
        require(respawner?.slot == 1 && respawner?.generation == 1, "respawner has stable second slot")
        require(tick.respawnerEffects.count == 1, "respawner callback executes in default-list order")
        guard let respawnerEffect = tick.respawnerEffects.first,
              let respawnedYoshi = respawnerEffect.spawnedObject else {
            preconditionFailure("respawner child is missing")
        }
        require(tick.respawnerDeliveries.first?.deleted == [respawner!], "respawner owner deletion is delivered")
        require(engine.objects.record(for: respawnedYoshi)?.behaviorIdentity == SM64YoshiObjectBridge.defaultBehaviorIdentity, "respawned behavior identity transfers")
        require(engine.objects.record(for: respawnedYoshi)?.position == SM64ObjectVector3(x: 0, y: 3_174, z: -5_625), "respawned transform transfers")
        fingerprint = hashTick(fingerprint, tick, records: [
            engine.objects.record(for: respawnSource),
            engine.objects.record(for: respawner!)
        ])

        let credits = try bridge.spawnYoshi(in: engine)
        require(credits.slot == 1 && credits.generation == 2, "respawner slot generation advances")
        tick = bridge.tick(state: engine, environments: [credits: environment(endingCameraEvent: true)])
        require(bridge.state(for: credits)?.action == SM64YoshiBehavior.creditsAction, "ending event enters credits")
        require(engine.objects.record(for: credits)?.position == SM64ObjectVector3(x: -1_798, y: 3_174, z: -3_644), "credits position is owner synchronized")
        fingerprint = hashTick(fingerprint, tick, records: [
            engine.objects.record(for: credits),
            engine.objects.record(for: respawnedYoshi)
        ])
        print(String(format: "yoshiObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Yoshi object bridge smoke passed")
    }
}
