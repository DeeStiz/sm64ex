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

private func hashOutput(_ initial: UInt64, _ output: SM64TuxiesMotherOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(output.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.subAction)))
    hash = hashU64(hash, UInt64(output.scale.bitPattern))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.animation)))
    hash = hashU64(hash, UInt64(output.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: output.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: output.angleVelocityYaw)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.dialogID)))
    hash = hashU64(hash, output.dialogRequested ? 1 : 0)
    hash = hashU64(hash, output.childSmallPenguinUnk88 ? 1 : 0)
    hash = hashU64(hash, UInt64(output.childInteractionSetMask))
    hash = hashU64(hash, output.clearChildDropImmediate ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.childBehavior)))
    hash = hashU64(hash, output.spawnStar ? 1 : 0)
    hash = hashID(hash, nil)
    if let home = output.starHomePosition {
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(home.x.bitPattern))
        hash = hashU64(hash, UInt64(home.y.bitPattern))
        hash = hashU64(hash, UInt64(home.z.bitPattern))
    }
    hash = hashU64(hash, UInt64(output.starSpawnYOffset.bitPattern))
    hash = hashU64(hash, output.playWalkingSound ? 1 : 0)
    hash = hashU64(hash, output.playYellSound ? 1 : 0)
    return hashU64(hash, output.activeFlagUnk10 ? 1 : 0)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64TuxiesMotherObjectEffect) -> UInt64 {
    var hash = hashID(initial, effect.objectID)
    hash = hashID(hash, effect.childID)
    hash = hashOutput(hash, effect.output)
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashID(hash, child)
    }
    hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    for intent in effect.presentedEffects {
        hash = hashIntent(hash, intent)
    }
    return hash
}

private func hashRecord(_ initial: UInt64, _ record: SM64ObjectRecord?) -> UInt64 {
    guard let record else { return hashU64(initial, 0) }
    var hash = hashU64(initial, 1)
    hash = hashID(hash, record.id)
    hash = hashID(hash, record.parent)
    hash = hashU64(hash, record.behaviorIdentity)
    hash = hashU64(hash, record.currentBehaviorCommandIdentity)
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.subAction)))
    hash = hashU64(hash, UInt64(record.interactionSubtype))
    hash = hashU64(hash, UInt64(record.activeFlags))
    return hash
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64TuxiesMotherSchedulerTickResult,
    state: SM64SwiftEngineState,
    motherID: SM64ObjectID,
    childID: SM64ObjectID
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
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
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        for intent in delivery.delivered {
            hash = hashIntent(hash, intent)
        }
        hash = hashU64(hash, UInt64(delivery.presented.count))
        for intent in delivery.presented {
            hash = hashIntent(hash, intent)
        }
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    hash = hashRecord(hash, state.objects.record(for: motherID))
    return hashRecord(hash, state.objects.record(for: childID))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func environment(
    childDistance: Float = 600,
    childHeldState: Int32 = SM64TuxiesMotherBehavior.heldFree,
    motherBehaviorParam: UInt8 = 1,
    childBehaviorParam: UInt8 = 1,
    canActivateText: Bool = false,
    dialogResult: Int32 = 0,
    marioOnPlatform: Bool = false
) -> SM64TuxiesMotherEnvironment {
    SM64TuxiesMotherEnvironment(
        motherBehaviorParam: motherBehaviorParam,
        childBehaviorParam: childBehaviorParam,
        childExists: true,
        childDistance: childDistance,
        childHeldState: childHeldState,
        marioOnPlatform: marioOnPlatform,
        canActivateText: canActivateText,
        dialogResult: dialogResult
    )
}

@main
enum SM64ModernTuxiesMotherObjectBridgeSmoke {
    static func main() throws {
        let state = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64TuxiesMotherObjectBridge()
        let mother = try bridge.spawnMother(
            in: state,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            moveYaw: 0x200
        )
        let child = try bridge.spawnSmallPenguin(in: state, parent: mother)
        require(mother.traceSubject == 1 && child.traceSubject == 2, "stable mother and child slots")
        require(bridge.attachChild(child, to: mother, in: state.objects), "child attachment")
        _ = state.objects.mutate(mother) { record in
            record.behaviorParams2ndByte = 1
        }
        _ = state.objects.mutate(child) { record in
            record.behaviorParams2ndByte = 1
        }

        var fingerprint = fnvOffset
        let initialGate = bridge.tick(
            state: state,
            environments: [mother: environment(canActivateText: true)]
        )
        require(bridge.state(for: mother)?.subAction == SM64TuxiesMotherBehavior.subDialog, "initial dialog gate")
        require(initialGate.effects.first?.presentedEffects.isEmpty == true, "initial gate has no presentation")
        fingerprint = hashTick(fingerprint, initialGate, state: state, motherID: mother, childID: child)

        let initialDialog = bridge.tick(
            state: state,
            environments: [mother: environment()]
        )
        require(initialDialog.effects.first?.output.dialogID == SM64TuxiesMotherBehavior.dialogInitial, "initial dialog route")
        require(initialDialog.effects.first?.presentedEffects.contains(where: {
            $0.kind == .dialog && $0.value == SM64TuxiesMotherBehavior.dialogInitial
        }) == true, "initial dialog presented")
        fingerprint = hashTick(fingerprint, initialDialog, state: state, motherID: mother, childID: child)

        let accepted = bridge.tick(
            state: state,
            environments: [mother: environment(dialogResult: 1)]
        )
        require(bridge.state(for: mother)?.subAction == SM64TuxiesMotherBehavior.subWaitForDrop, "initial dialog accepted")
        fingerprint = hashTick(fingerprint, accepted, state: state, motherID: mother, childID: child)

        // Reset the fixture to the source action-0 entry point before the
        // held-child path. The C behavior preserves subAction across the
        // action-0 -> action-1 handoff, so this keeps the two authored routes
        // independently observable without inventing a bridge-side reset.
        require(bridge.attachMother(
            mother,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            moveYaw: 0x200,
            childID: child,
            in: state.objects
        ), "carry route fixture reset")
        _ = state.objects.mutate(child) { record in
            record.heldState = 1
        }
        let carried = bridge.tick(
            state: state,
            environments: [mother: environment(childDistance: 250, childHeldState: 1)]
        )
        require(bridge.state(for: mother)?.action == SM64TuxiesMotherBehavior.carryingChild, "held child enters carry action")
        require(state.objects.record(for: child)?.parent == mother, "held child remains linked")
        fingerprint = hashTick(fingerprint, carried, state: state, motherID: mother, childID: child)

        let correctDialog = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 1)]
        )
        require(correctDialog.effects.first?.output.dialogID == SM64TuxiesMotherBehavior.dialogCorrectChild, "correct child dialog")
        require(correctDialog.effects.first?.presentedEffects.contains(where: {
            $0.kind == .dialog && $0.value == SM64TuxiesMotherBehavior.dialogCorrectChild
        }) == true, "correct child dialog presented")
        fingerprint = hashTick(fingerprint, correctDialog, state: state, motherID: mother, childID: child)

        let correctAccepted = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 1, dialogResult: 1)]
        )
        require(state.objects.record(for: child)?.interactionSubtype == SM64TuxiesMotherBehavior.interactionDropImmediately, "drop-immediately interaction mask")
        require(bridge.state(for: mother)?.subAction == SM64TuxiesMotherBehavior.subDialog, "correct dialog enters reward branch")
        fingerprint = hashTick(fingerprint, correctAccepted, state: state, motherID: mother, childID: child)

        _ = state.objects.mutate(child) { record in
            record.heldState = 0
        }
        let reward = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 0)]
        )
        guard let effect = reward.effects.first,
              let star = effect.spawnedChildren.first else {
            preconditionFailure("reward star missing")
        }
        require(effect.output.spawnStar, "reward output owns star")
        require(effect.presentedEffects.contains(where: { $0.kind == .star }), "reward progression presented")
        require(state.objects.record(for: child)?.behaviorIdentity == SM64TuxiesMotherObjectBridge.unusedChildBehaviorIdentity, "correct child becomes unused")
        require(state.objects.record(for: child)?.interactionSubtype == 0, "drop-immediately flag is cleared")
        require(state.objects.record(for: star)?.position == SM64ObjectVector3(x: 100, y: 400, z: 300), "star source position")
        require(state.objects.record(for: star)?.homePosition == SM64TuxiesMotherBehavior.starHomePosition, "star home position")
        fingerprint = hashTick(fingerprint, reward, state: state, motherID: mother, childID: child)

        _ = state.objects.markForDeletion(mother)
        let retired = bridge.tick(state: state)
        require(retired.scheduler.unloaded.contains(mother), "mother unloads")
        require(state.objects.record(for: child) == nil, "owned child retires with mother")
        require(bridge.registeredIDs.isEmpty, "bridge clears retired owner")
        fingerprint = hashTick(fingerprint, retired, state: state, motherID: mother, childID: child)

        print(String(format: "tuxiesMotherObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Tuxie's mother object bridge smoke passed")
    }
}
