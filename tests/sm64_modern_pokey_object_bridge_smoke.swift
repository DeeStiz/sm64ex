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

private func hashKernel(_ initial: UInt64, _ state: SM64PokeyState, effects: SM64PokeyEffect) -> UInt64 {
    var hash = hashU64(initial, UInt64(effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.turningAwayFromWall))
    hash = hashU64(hash, UInt64(state.changeTargetTimer))
    hash = hashU64(hash, UInt64(state.aliveBodyPartFlags))
    hash = hashU64(hash, UInt64(state.numAliveBodyParts))
    hash = hashU64(hash, UInt64(state.bottomBodyPartSize.bitPattern))
    hash = hashU64(hash, state.headWasKilled ? 1 : 0)
    hash = hashU64(hash, UInt64(state.deathDelayAfterHeadKilled))
    hash = hashU64(hash, UInt64(state.scale.bitPattern))
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBridge(
    _ initial: UInt64,
    _ tick: SM64PokeySchedulerTickResult,
    record: SM64ObjectRecord?
) -> UInt64 {
    let scheduler = tick.scheduler
    var hash = hashU64(initial, scheduler.frame)
    for count in scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(scheduler.objectCounter))
    hash = hashU64(hash, UInt64(scheduler.updated.count))
    for id in scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(scheduler.unloaded.count))
    for id in scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(UInt8(bitPattern: effect.bodyIndex)))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedParts.count))
        for id in effect.spawnedParts { hash = hashU64(hash, UInt64(id.traceSubject)) }
        hash = hashU64(hash, UInt64(effect.numAliveBodyParts))
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    guard let record else { return hashU64(hash, 0) }
    hash = hashU64(hash, 1)
    hash = hashU64(hash, UInt64(record.action))
    hash = hashU64(hash, UInt64(record.previousAction))
    hash = hashU64(hash, UInt64(record.timer))
    hash = hashU64(hash, UInt64(record.position.x.bitPattern))
    hash = hashU64(hash, UInt64(record.position.y.bitPattern))
    hash = hashU64(hash, UInt64(record.position.z.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: record.moveAngles.yaw)))
    hash = hashU64(hash, UInt64(record.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(record.behaviorParams))
    hash = hashU64(hash, UInt64(record.behaviorParams2ndByte))
    return hashU64(hash, UInt64(record.interactionType))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernPokeyObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var parent = SM64PokeyState(kind: .parent, homeX: 10, homeY: 100, homeZ: -20)

        let spawn = SM64PokeyKernel.tickParent(
            SM64PokeyParentTickInput(distanceToMario: 1_000),
            state: &parent
        )
        require(spawn.state.action == .wander && spawn.state.numAliveBodyParts == 5, "pokey spawn parts")
        fingerprint = hashKernel(fingerprint, spawn.state, effects: spawn.effects)

        let wander = SM64PokeyKernel.tickParent(
            SM64PokeyParentTickInput(distanceToMario: 100, moveFlags: 0x2),
            state: &parent
        )
        require(wander.state.forwardVelocity == 5, "pokey wander speed")
        fingerprint = hashKernel(fingerprint, wander.state, effects: wander.effects)

        parent.numAliveBodyParts = 4
        parent.aliveBodyPartFlags = 0x0F
        parent.timer = 101
        let replenish = SM64PokeyKernel.tickParent(
            SM64PokeyParentTickInput(distanceToMario: 100),
            state: &parent
        )
        require(replenish.effects.contains(.replenishPart) && replenish.state.numAliveBodyParts == 5, "pokey replenish")
        fingerprint = hashKernel(fingerprint, replenish.state, effects: replenish.effects)

        let unload = SM64PokeyKernel.tickParent(
            SM64PokeyParentTickInput(distanceToMario: 3_000),
            state: &parent
        )
        require(unload.state.action == .unloadParts, "pokey unload admission")
        fingerprint = hashKernel(fingerprint, unload.state, effects: unload.effects)

        var body = SM64PokeyState(
            kind: .bodyPart,
            bodyIndex: 0,
            homeX: 10,
            homeY: 100,
            homeZ: -20,
            positionX: 10,
            positionY: 580,
            positionZ: -20
        )
        let bodyTick = SM64PokeyKernel.tickBody(
            SM64PokeyBodyTickInput(
                parentX: 10,
                parentY: 100,
                parentZ: -20,
                globalFrame: 1
            ),
            state: &body
        )
        require(bodyTick.state.positionY == 580 && bodyTick.state.positionX > 15, "pokey body transform")
        fingerprint = hashKernel(fingerprint, bodyTick.state, effects: bodyTick.effects)

        let bodyAttack = SM64PokeyKernel.tickBody(
            SM64PokeyBodyTickInput(parentX: 10, parentY: 100, parentZ: -20, attacked: true),
            state: &body
        )
        require(bodyAttack.killedHead && bodyAttack.state.markedForDeletion, "pokey head attack")
        fingerprint = hashKernel(fingerprint, bodyAttack.state, effects: bodyAttack.effects)

        let engineState = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64PokeyObjectBridge()
        let pokeyID = try bridge.spawnPokey(in: engineState, homeX: 10, homeY: 100, homeZ: -20)
        let playerID = try engineState.spawnObject(in: .player, isMario: true)
        let bridgeTick = bridge.tick(
            state: engineState,
            parentInputs: [pokeyID: SM64PokeyParentTickInput(distanceToMario: 1_000)]
        )
        require(bridgeTick.effects.count == 6, "pokey parent plus five parts")
        require(bridgeTick.effects.first?.spawnedParts.count == 5, "pokey body children")
        require(bridgeTick.scheduler.updated.first?.traceSubject == playerID.traceSubject, "pokey player order")
        guard let record = engineState.objects.record(for: pokeyID) else {
            preconditionFailure("pokey record missing")
        }
        require(record.behaviorParams == 5 && record.behaviorParams2ndByte == 0x1F, "pokey parent counters")
        fingerprint = hashBridge(fingerprint, bridgeTick, record: record)

        print(String(format: "pokeyObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Pokey object bridge smoke passed")
    }
}
