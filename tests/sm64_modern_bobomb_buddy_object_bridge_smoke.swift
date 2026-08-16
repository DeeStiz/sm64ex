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

private func hashIntent(_ initial: UInt64, _ intent: SM64OwnerThreadEffectIntent) -> UInt64 {
    var hash = hashU64(initial, intent.sequence)
    hash = hashID(hash, intent.objectID)
    hash = hashU64(hash, UInt64(intent.kind.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    return hashU64(hash, UInt64(bitPattern: Int64(intent.auxiliary)))
}

private func hashState(_ initial: UInt64, _ state: SM64BobombBuddyState) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.role)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.cannonStatus)))
    hash = hashU64(hash, state.hasTalked ? 1 : 0)
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    return hashU64(hash, UInt64(state.blinkTimer))
}

private func hashOutput(_ initial: UInt64, _ output: SM64BobombBuddyOutput) -> UInt64 {
    var hash = hashState(initial, output.state)
    hash = hashU64(hash, output.playWalkingSound ? 1 : 0)
    hash = hashU64(hash, output.playReadSignSound ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.dialogID)))
    hash = hashU64(hash, output.dialogRequested ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.cameraRequest)))
    hash = hashU64(hash, output.activeTimeStop ? 1 : 0)
    hash = hashU64(hash, output.clearTimeStop ? 1 : 0)
    hash = hashU64(hash, output.clearInteraction ? 1 : 0)
    return hashU64(hash, UInt64(output.visibilityDistance.bitPattern))
}

private func hashEffect(_ initial: UInt64, _ effect: SM64BobombBuddyObjectEffect) -> UInt64 {
    var hash = hashID(initial, effect.objectID)
    hash = hashOutput(hash, effect.output)
    hash = hashID(hash, effect.nearestCannonID)
    hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    for intent in effect.presentedEffects {
        hash = hashIntent(hash, intent)
    }
    return hash
}

private func hashDelivery(
    _ initial: UInt64,
    _ delivery: SM64OwnerThreadEffectDeliveryResult
) -> UInt64 {
    var hash = hashU64(initial, UInt64(delivery.delivered.count))
    for intent in delivery.delivered {
        hash = hashIntent(hash, intent)
    }
    hash = hashU64(hash, UInt64(delivery.presented.count))
    for intent in delivery.presented {
        hash = hashIntent(hash, intent)
    }
    hash = hashU64(hash, UInt64(delivery.spawned.count))
    hash = hashU64(hash, UInt64(delivery.deleted.count))
    return hashU64(hash, UInt64(delivery.rejected.count))
}

private func hashRecord(_ initial: UInt64, _ record: SM64ObjectRecord?) -> UInt64 {
    guard let record else { return hashU64(initial, 0) }
    var hash = hashU64(initial, 1)
    hash = hashID(hash, record.id)
    hash = hashID(hash, record.parent)
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.subAction)))
    hash = hashU64(hash, UInt64(record.activeFlags))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.behaviorParams)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.behaviorParams2ndByte)))
    hash = hashU64(hash, UInt64(record.interactionSubtype))
    return hashU64(hash, UInt64(record.drawingDistance.bitPattern))
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64BobombBuddySchedulerTickResult,
    state: SM64SwiftEngineState,
    buddyID: SM64ObjectID
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    hash = hashU64(hash, tick.scheduler.timeStopWasActive ? 1 : 0)
    hash = hashU64(hash, tick.scheduler.timeStopIsActive ? 1 : 0)
    hash = hashU64(hash, UInt64(tick.scheduler.skippedByTimeStop.count))
    for id in tick.scheduler.skippedByTimeStop {
        hash = hashID(hash, id)
    }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded {
        hash = hashID(hash, id)
    }
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashEffect(hash, effect)
    }
    hash = hashU64(hash, UInt64(tick.deliveries.count))
    for delivery in tick.deliveries {
        hash = hashDelivery(hash, delivery)
    }
    return hashRecord(hash, state.objects.record(for: buddyID))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func environment(
    animationFrame: Int16 = 0,
    distanceToMario: Float = 10_000,
    angleToMario: Int16 = 0,
    interacted: Bool = false,
    dialogOpenResult: Int32 = 0,
    adviceDialogResult: Int32 = 0,
    adviceDialogID: Int32 = 0,
    cannonFirstDialogResult: Int32 = 0,
    cannonCutsceneResult: Int32 = 0,
    cannonSecondDialogResult: Int32 = 0,
    courseIsBob: Bool = true,
    randomBlinkTimer: UInt32 = 0,
    nearestCannonID: SM64ObjectID? = nil
) -> SM64BobombBuddyEnvironment {
    SM64BobombBuddyEnvironment(
        input: SM64BobombBuddyInput(
            animationFrame: animationFrame,
            distanceToMario: distanceToMario,
            angleToMario: angleToMario,
            interacted: interacted,
            dialogOpenResult: dialogOpenResult,
            adviceDialogResult: adviceDialogResult,
            adviceDialogID: adviceDialogID,
            cannonFirstDialogResult: cannonFirstDialogResult,
            nearestCannonExists: nearestCannonID != nil,
            cannonCutsceneResult: cannonCutsceneResult,
            cannonSecondDialogResult: cannonSecondDialogResult,
            courseIsBob: courseIsBob,
            randomBlinkTimer: randomBlinkTimer
        ),
        nearestCannonID: nearestCannonID
    )
}

@main
enum SM64ModernBobombBuddyObjectBridgeSmoke {
    static func main() throws {
        let state = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BobombBuddyObjectBridge()
        let buddy = try bridge.spawnBuddy(
            in: state,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            moveYaw: 0
        )
        require(buddy.traceSubject == 1, "stable buddy slot")
        var fingerprint = fnvOffset

        var tick = bridge.tick(
            state: state,
            environments: [buddy: environment(
                animationFrame: 5,
                distanceToMario: 500,
                angleToMario: 0x2000,
                interacted: true,
                randomBlinkTimer: 11
            )]
        )
        require(bridge.state(for: buddy)?.action == SM64BobombBuddyBehavior.turnToTalkAction, "interaction enters turn")
        require(tick.effects.first?.presentedEffects.filter { $0.kind == .sound }.count == 2, "turn sounds presented")
        require(state.objects.record(for: buddy)?.interactionStatus == 0, "interaction status resets")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(animationFrame: 16, angleToMario: 0x2000, randomBlinkTimer: 12)]
        )
        require(bridge.state(for: buddy)?.moveYaw == 0x1140, "turn increments preserve C scalar")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(angleToMario: 0x2000, randomBlinkTimer: 13)]
        )
        require(bridge.state(for: buddy)?.action == SM64BobombBuddyBehavior.talkAction, "turn reaches talk")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(
                dialogOpenResult: 2,
                adviceDialogResult: 1,
                adviceDialogID: 77,
                randomBlinkTimer: 14
            )]
        )
        require(tick.effects.first?.output.dialogID == 77, "advice dialog is routed")
        require(tick.effects.first?.presentedEffects.contains(where: { $0.kind == .dialog && $0.value == 77 }) == true, "advice effect presented")
        require(state.globals.timeStopState.isEmpty, "advice cleanup clears time stop")
        require(state.objects.record(for: buddy)?.activeFlags == 257, "advice cleanup clears initiated flag")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        require(bridge.attach(
            buddy,
            role: SM64BobombBuddyBehavior.cannonRole,
            action: SM64BobombBuddyBehavior.talkAction,
            moveYaw: 0x2000,
            in: state.objects
        ), "cannon role reset")
        let cannon = try state.spawnObject(
            in: .surface,
            behaviorIdentity: SM64BobombBuddyObjectBridge.cannonClosedBehaviorIdentity
        )
        require(cannon.traceSubject == 2, "stable cannon slot")

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(
                dialogOpenResult: 2,
                cannonFirstDialogResult: 1,
                nearestCannonID: cannon
            )]
        )
        require(bridge.state(for: buddy)?.cannonStatus == SM64BobombBuddyBehavior.cannonOpening, "cannon enters opening")
        require(state.globals.timeStopState.contains(.enabled), "cannon enables time stop")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(
                dialogOpenResult: 2,
                cannonCutsceneResult: -1,
                nearestCannonID: cannon
            )]
        )
        require(tick.effects.first?.presentedEffects.contains(where: { $0.kind == .cameraShake && $0.value == 1 }) == true, "prepare-cannon camera request")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(dialogOpenResult: 2, cannonSecondDialogResult: 1, nearestCannonID: cannon)]
        )
        require(tick.effects.first?.output.dialogID == 105, "ready dialog is routed")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        tick = bridge.tick(
            state: state,
            environments: [buddy: environment(dialogOpenResult: 2, nearestCannonID: cannon)]
        )
        require(bridge.state(for: buddy)?.action == SM64BobombBuddyBehavior.idleAction, "cannon returns idle")
        require(state.globals.timeStopState.isEmpty, "cannon cleanup clears time stop")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        _ = state.objects.markForDeletion(buddy)
        tick = bridge.tick(state: state)
        require(tick.scheduler.unloaded == [buddy], "buddy unloads in scheduler order")
        require(bridge.registeredIDs.isEmpty, "generation-safe registry retires buddy")
        require(state.objects.record(for: buddy) == nil, "retired buddy is not addressable")
        fingerprint = hashTick(fingerprint, tick, state: state, buddyID: buddy)

        print(String(format: "bobombBuddyObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bob-omb Buddy object bridge smoke passed")
    }
}
