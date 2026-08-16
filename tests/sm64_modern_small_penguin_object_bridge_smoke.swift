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

private func hashState(_ initial: UInt64, _ state: SM64SmallPenguinState) -> UInt64 {
    var hash = initial
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.timer)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.unknown104.bitPattern))
    hash = hashU64(hash, UInt64(state.unknown108.bitPattern))
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

private func hashIntent(_ initial: UInt64, _ intent: SM64OwnerThreadEffectIntent) -> UInt64 {
    var hash = hashU64(initial, intent.sequence)
    hash = hashID(hash, intent.objectID)
    hash = hashU64(hash, UInt64(intent.kind.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    return hashU64(hash, UInt64(bitPattern: Int64(intent.auxiliary)))
}

private func hashRecord(_ initial: UInt64, _ record: SM64ObjectRecord?) -> UInt64 {
    guard let record else { return hashU64(initial, 0) }
    var hash = hashU64(initial, 1)
    hash = hashID(hash, record.id)
    hash = hashID(hash, record.parent)
    hash = hashU64(hash, record.behaviorIdentity)
    hash = hashU64(hash, record.currentBehaviorCommandIdentity)
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.previousAction)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.timer)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record.animationState)))
    hash = hashU64(hash, UInt64(record.heldState))
    hash = hashU64(hash, UInt64(record.activeFlags))
    return hash
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64SmallPenguinSchedulerTickResult,
    state: SM64SwiftEngineState,
    id: SM64ObjectID
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for unloaded in tick.scheduler.unloaded {
        hash = hashID(hash, unloaded)
    }
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashID(hash, effect.objectID)
        hash = hashOutput(hash, effect.output)
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        for intent in effect.presentedEffects {
            hash = hashIntent(hash, intent)
        }
    }
    hash = hashU64(hash, UInt64(tick.deliveries.count))
    for delivery in tick.deliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        for intent in delivery.delivered {
            hash = hashIntent(hash, intent)
        }
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hashRecord(hash, state.objects.record(for: id))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func environment(
    distanceToMario: Float = 800,
    angleToMario: Int16 = 0x200,
    nearestMotherExists: Bool = false,
    nearestMotherDistance: Float = .greatestFiniteMagnitude,
    angleToMother: Int16 = 0,
    marioDiveSliding: Bool = false,
    marioFarAway: Bool = false,
    marioPosition: SM64ObjectVector3 = .zero,
    soundStateID: Int32 = 1,
    globalTimer: UInt64 = 1,
    hasBabyBehavior: Bool = false,
    heldState: Int32 = SM64SmallPenguinBehavior.heldFree
) -> SM64SmallPenguinInput {
    SM64SmallPenguinInput(
        distanceToMario: distanceToMario,
        angleToMario: angleToMario,
        nearestMotherExists: nearestMotherExists,
        nearestMotherDistance: nearestMotherDistance,
        angleToMother: angleToMother,
        marioDiveSliding: marioDiveSliding,
        marioFarAway: marioFarAway,
        marioPosition: marioPosition,
        soundStateID: soundStateID,
        globalTimer: globalTimer,
        hasBabyBehavior: hasBabyBehavior,
        randomUnknown110: 0x100,
        randomUnknown108: 100,
        randomUnknown104: 0.25,
        heldState: heldState
    )
}

@main
enum SM64ModernSmallPenguinObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64SmallPenguinObjectBridge()
        let id = try bridge.spawnPenguin(
            in: engineState,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30)
        )
        require(id.traceSubject == 1, "stable small-penguin slot")

        var fingerprint = fnvOffset
        let initial = bridge.tick(
            state: engineState,
            environments: [id: environment()]
        )
        require(bridge.state(for: id)?.action == SM64SmallPenguinBehavior.moveAwayAction, "initial bridge action")
        require(engineState.objects.record(for: id)?.timer == 1, "initial timer publication")
        fingerprint = hashTick(fingerprint, initial, state: engineState, id: id)

        let moving = bridge.tick(
            state: engineState,
            environments: [id: environment()]
        )
        require(engineState.objects.record(for: id)?.forwardVelocity == 3.25, "moving speed publication")
        require(engineState.objects.record(for: id)?.moveAngles.yaw == 512, "moving yaw publication")
        fingerprint = hashTick(fingerprint, moving, state: engineState, id: id)

        let close = bridge.tick(
            state: engineState,
            environments: [id: environment(distanceToMario: 300)]
        )
        require(engineState.objects.record(for: id)?.action == SM64SmallPenguinBehavior.idleAction, "close action publication")
        fingerprint = hashTick(fingerprint, close, state: engineState, id: id)

        require(bridge.attach(id, position: SM64ObjectVector3(x: 10, y: 20, z: 30), in: engineState.objects), "held fixture reset")
        let followsMother = bridge.tick(
            state: engineState,
            environments: [id: environment(
                distanceToMario: 500,
                nearestMotherExists: true,
                nearestMotherDistance: 250,
                angleToMother: 0x400
            )]
        )
        require(engineState.objects.record(for: id)?.action == SM64SmallPenguinBehavior.followMotherAction, "mother follow publication")
        fingerprint = hashTick(fingerprint, followsMother, state: engineState, id: id)

        _ = engineState.objects.mutate(id) { record in
            record.heldState = UInt32(SM64SmallPenguinBehavior.heldHeld)
            record.behaviorIdentity = SM64SmallPenguinObjectBridge.babyBehaviorIdentity
            record.currentBehaviorCommandIdentity = SM64SmallPenguinObjectBridge.babyBehaviorIdentity
        }
        let held = bridge.tick(
            state: engineState,
            environments: [id: environment(
                marioPosition: SM64ObjectVector3(x: 100, y: 200, z: 300),
                globalTimer: 30,
                hasBabyBehavior: true,
                heldState: SM64SmallPenguinBehavior.heldHeld
            )]
        )
        require(held.effects.first?.output.copiedToMario == true, "held copy route")
        require(engineState.objects.record(for: id)?.position == SM64ObjectVector3(x: 100, y: 200, z: 300), "held position publication")
        require(engineState.objects.record(for: id)?.behaviorIdentity == SM64SmallPenguinObjectBridge.defaultBehaviorIdentity, "baby behavior switches to small")
        require(held.effects.first?.presentedEffects.contains(where: { $0.value == SM64SmallPenguinObjectBridge.heldYellSoundValue }) == true, "held yell presentation")
        fingerprint = hashTick(fingerprint, held, state: engineState, id: id)

        let released = bridge.tick(
            state: engineState,
            environments: [id: environment(
                distanceToMario: 500,
                nearestMotherExists: true,
                nearestMotherDistance: 250,
                angleToMother: 0x400,
                heldState: SM64SmallPenguinBehavior.heldFree
            )]
        )
        require(engineState.objects.record(for: id)?.heldState == 0, "release held state")
        fingerprint = hashTick(fingerprint, released, state: engineState, id: id)

        _ = engineState.objects.markForDeletion(id)
        let retired = bridge.tick(state: engineState)
        require(retired.scheduler.unloaded.contains(id), "small penguin unload")
        require(bridge.registeredIDs.isEmpty, "bridge clears retired small penguin")
        fingerprint = hashTick(fingerprint, retired, state: engineState, id: id)

        print(String(format: "smallPenguinObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern small penguin object bridge smoke passed")
    }
}
