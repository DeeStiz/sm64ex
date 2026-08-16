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
    hash = hashU64(hash, UInt64(record.heldState))
    hash = hashU64(hash, UInt64(record.graphFlags))
    hash = hashU64(hash, UInt64(record.interactionType))
    hash = hashU64(hash, UInt64(record.interactionSubtype))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.intangibleTimer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.previousAction)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.subAction)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.timer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.animationState)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.health)))
    hash = hashFloat(hash, record.drawingDistance)
    hash = hashFloat(hash, record.gravity)
    hash = hashFloat(hash, record.position.y)
    return hashFloat(hash, record.homePosition.y)
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64KingBobombSchedulerTickResult,
    record: SM64ObjectRecord?
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
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        for intent in effect.presentedEffects { hash = hashIntent(hash, intent) }
    }
    hash = hashU64(hash, UInt64(tick.deliveries.count))
    for delivery in tick.deliveries { hash = hashDelivery(hash, delivery) }
    return hashRecord(hash, record)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernKingBobombObjectBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64KingBobombObjectBridge()
        var fingerprint = fnvOffset

        let id = try bridge.spawnKingBobomb(in: engine, homeY: 100, positionY: 100)
        require(id == SM64ObjectID(slot: 0, generation: 1), "first King Bob-omb ID is stable")

        var tick = bridge.tick(state: engine, environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
            positionY: 100,
            dialogCanActivate: true
        ))])
        require(tick.effects.first?.output.state.subAction == 1, "intro activation advances subaction")
        require(tick.deliveries.first?.presented.contains(where: { $0.kind == .music && $0.value == 1 }) == true,
                "boss music is owner-presented")
        require(engine.objects.record(for: id)?.interactionSubtype == 0, "pre-dialog boss is not holdable")
        require(engine.objects.record(for: id)?.animationState == 5, "intro animation synchronizes")
        fingerprint = hashTick(fingerprint, tick, record: engine.objects.record(for: id))

        tick = bridge.tick(state: engine, environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
            positionY: 100,
            dialogComplete: true
        ))])
        require(tick.effects.first?.output.state.action == SM64KingBobombBehavior.grabbedAction,
                "intro dialog enters grabbed action")
        require(tick.effects.first?.output.dialogID == SM64KingBobombBehavior.dialogIntro,
                "intro dialog reaches owner bridge")
        require(tick.deliveries.first?.presented.contains(where: { $0.kind == .dialog && $0.value == 17 }) == true,
                "intro dialog is presented")
        require(engine.objects.record(for: id)?.interactionSubtype == SM64KingBobombObjectBridge.interactionSubtypeGrabsMario,
                "holdable interaction synchronizes")
        fingerprint = hashTick(fingerprint, tick, record: engine.objects.record(for: id))

        require(bridge.attach(id, homeY: 100, positionY: 100, action: SM64KingBobombBehavior.thrownAction, in: engine.objects),
                "thrown action reattaches")
        tick = bridge.tick(state: engine, environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
            positionY: 100,
            landed: true
        ))])
        require(tick.effects.first?.output.state.action == SM64KingBobombBehavior.damagedAction,
                "thrown landing enters damaged action")
        require(tick.effects.first?.presentedEffects.contains(where: { $0.kind == .sound }) == true,
                "landing sound is owner-presented")
        require(engine.objects.record(for: id)?.health == 2, "landing damage synchronizes")
        fingerprint = hashTick(fingerprint, tick, record: engine.objects.record(for: id))

        require(bridge.attach(id, homeY: 100, positionY: 100, action: SM64KingBobombBehavior.deathAction, in: engine.objects),
                "death action reattaches")
        tick = bridge.tick(state: engine, environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
            positionY: 100,
            dialogComplete: true
        ))])
        require(tick.effects.first?.output.state.action == SM64KingBobombBehavior.bossWaitAction,
                "death dialog enters boss wait")
        require(tick.effects.first?.output.starPosition != nil, "death emits star position")
        require(tick.deliveries.first?.presented.contains(where: { $0.kind == .star && $0.value == 1 }) == true,
                "star is owner-presented")
        require(tick.deliveries.first?.presented.contains(where: { $0.kind == .cameraShake && $0.value == 1 }) == true,
                "death shake is owner-presented")
        require(engine.objects.record(for: id)?.graphFlags == 0x30, "death hides graph")
        fingerprint = hashTick(fingerprint, tick, record: engine.objects.record(for: id))

        require(engine.objects.markForDeletion(id), "deletion remains owner-authoritative")
        tick = bridge.tick(state: engine, environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(positionY: 200))])
        require(tick.scheduler.unloaded == [id], "deletion unloads at scheduler boundary")
        require(bridge.registeredIDs.isEmpty, "unloaded generation is retired")
        fingerprint = hashTick(fingerprint, tick, record: engine.objects.record(for: id))

        let heldID = try bridge.spawnKingBobomb(in: engine)
        require(heldID == SM64ObjectID(slot: 0, generation: 2), "slot generation rejects stale identity")
        tick = bridge.tick(state: engine, environments: [heldID: SM64KingBobombEnvironment(input: SM64KingBobombInput(
            positionY: 0,
            heldState: .held
        ))])
        require(tick.effects.first?.output.effects.contains(.unrenderHeld) == true, "held branch is value-driven")
        require(engine.objects.record(for: heldID)?.heldState == 1, "held state reaches owner record")
        require(engine.objects.record(for: heldID)?.graphFlags == 0x30, "held branch hides graph")
        fingerprint = hashTick(fingerprint, tick, record: engine.objects.record(for: heldID))

        print(String(format: "kingBobombObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb object bridge smoke passed")
    }
}
