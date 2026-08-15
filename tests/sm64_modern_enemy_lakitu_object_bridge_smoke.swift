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

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64EnemyLakituSchedulerTickResult,
    lakituRecord: SM64ObjectRecord?,
    spinyRecord: SM64ObjectRecord?
) -> UInt64 {
    let scheduler = tick.scheduler
    var hash = hashU64(initial, scheduler.frame)
    for count in scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(scheduler.objectCounter))
    hash = hashU64(hash, UInt64(scheduler.updated.count))
    for id in scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(scheduler.unloaded.count))
    for id in scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }

    hash = hashU64(hash, UInt64(tick.lakituEffects.count))
    for effect in tick.lakituEffects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.subAction.rawValue))
        hash = hashU64(hash, UInt64(effect.numSpinies))
        hash = hashU64(hash, UInt64(effect.spawnedSpiny?.traceSubject ?? 0))
    }

    hash = hashU64(hash, UInt64(tick.spinyEffects.count))
    for effect in tick.spinyEffects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.parentID?.traceSubject ?? 0))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.attackHandler.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
    }

    if let lakituRecord {
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(lakituRecord.action))
        hash = hashU64(hash, UInt64(lakituRecord.subAction))
        hash = hashU64(hash, UInt64(lakituRecord.behaviorParams2ndByte))
        hash = hashU64(hash, UInt64(lakituRecord.forwardVelocity.bitPattern))
        hash = hashU64(hash, UInt64(lakituRecord.velocity.y.bitPattern))
        hash = hashU64(hash, UInt64(lakituRecord.previousObject?.traceSubject ?? 0))
    } else {
        hash = hashU64(hash, 0)
    }

    if let spinyRecord {
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(spinyRecord.action))
        hash = hashU64(hash, UInt64(spinyRecord.forwardVelocity.bitPattern))
        hash = hashU64(hash, UInt64(spinyRecord.velocity.y.bitPattern))
        hash = hashU64(hash, UInt64(spinyRecord.graphYOffset.bitPattern))
    } else {
        hash = hashU64(hash, 0)
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernEnemyLakituObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64EnemyLakituObjectBridge()
        let lakitu = try bridge.spawnLakitu(in: engineState)
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(lakitu.traceSubject == 1 && mario.traceSubject == 2, "stable Lakitu/Mario slots")

        let far = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 2_500)]
        )
        require(far.scheduler.updated.map(\.traceSubject) == [1, 2], "far Lakitu scheduler order")
        require(far.lakituEffects.count == 1 && far.lakituEffects[0].effects == [.animate], "far animation only")
        require(bridge.state(for: lakitu)?.action == .uninitialized, "far Lakitu remains hidden")
        let farLakituRecord = engineState.objects.record(for: lakitu)

        let reveal = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400)]
        )
        require(reveal.scheduler.updated.map(\.traceSubject) == [1, 2], "reveal scheduler order")
        require(reveal.lakituEffects[0].effects == [.animate, .revealAndCloud], "reveal/cloud effect")
        require(bridge.state(for: lakitu)?.action == .main, "Lakitu main action")
        let revealLakituRecord = engineState.objects.record(for: lakitu)

        let spawned = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400, angleToMario: 0)],
            spinyInputs: [:]
        )
        guard let spiny = spawned.lakituEffects.first?.spawnedSpiny else {
            preconditionFailure("Lakitu did not allocate a Spiny")
        }
        require(spiny.traceSubject == 3, "Spiny appended after Lakitu and Mario")
        require(spawned.scheduler.updated.map(\.traceSubject) == [1, 2, 3], "same-frame child callback")
        require(spawned.lakituEffects[0].effects == [.animate, .spawnSpiny, .beginHold], "spawn/hold effect")
        require(spawned.spinyEffects[0].action == .heldByLakitu, "new Spiny is held")
        guard let spawnedLakituRecord = engineState.objects.record(for: lakitu),
              let spawnedSpinyRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("spawned records missing")
        }
        require(spawnedSpinyRecord.parent == lakitu, "Spiny parent identity")
        require(spawnedLakituRecord.previousObject == spiny, "Lakitu previous-object identity")
        require(spawnedSpinyRecord.objectFlags & SM64ObjectScheduler.objectFlagTransformRelativeToParent != 0, "held relative transform")
        require(spawnedSpinyRecord.parentRelativePosition == SM64ObjectVector3(x: -50, y: 35, z: -100), "held relative position")

        // The C behavior consumes the 30-frame hold cooldown before it can
        // enter the throw action. Keep those deterministic scheduler passes in
        // the qualification run, but hash the event boundaries below.
        for _ in 0..<30 {
            let hold = bridge.tick(
                state: engineState,
                inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400)]
            )
            require(hold.scheduler.updated.map(\.traceSubject) == [1, 2, 3], "hold callback order")
            require(bridge.state(for: lakitu)?.subAction == .holdSpiny, "hold cooldown remains active")
        }

        let beginThrow = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400)]
        )
        require(beginThrow.lakituEffects[0].effects == [.animate, .beginThrow], "begin throw effect")
        require(beginThrow.lakituEffects[0].subAction == .throwSpiny, "throw sub-action")
        require(beginThrow.spinyEffects[0].action == .heldByLakitu, "Spiny waits for animation boundary")
        require(engineState.objects.record(for: lakitu)?.previousObject == spiny, "parent link held until frame two")
        guard let beginThrowLakituRecord = engineState.objects.record(for: lakitu),
              let beginThrowSpinyRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("begin-throw records missing")
        }

        let clearPrevious = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400, animationFrameTwo: true)]
        )
        require(clearPrevious.lakituEffects[0].effects == [.animate, .throwSound, .clearPreviousSpiny], "throw sound/link clear")
        require(clearPrevious.spinyEffects[0].effects == [.animate, .throwFromLakitu], "Spiny throw transition")
        require(clearPrevious.spinyEffects[0].action == .thrownByLakitu, "Spiny thrown action")
        require(engineState.objects.record(for: lakitu)?.previousObject == nil, "previous-object link cleared")
        require(engineState.objects.record(for: spiny)?.action == Int32(SM64SpinyAction.thrownByLakitu.rawValue), "record action copied")
        guard let clearLakituRecord = engineState.objects.record(for: lakitu),
              let clearSpinyRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("clear records missing")
        }

        let attacked = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400)],
            spinyInputs: [spiny: SM64SpinyTickInput(distanceToMario: 400, onGround: false, attack: .punch)]
        )
        require(attacked.spinyEffects[0].effects == [.animate, .decrementParentCount], "thrown attack decrements parent")
        require(bridge.state(for: lakitu)?.numSpinies == 0, "Lakitu count decremented")
        require(engineState.objects.record(for: lakitu)?.behaviorParams2ndByte == 0, "count copied to object record")
        guard let attackedLakituRecord = engineState.objects.record(for: lakitu),
              let attackedSpinyRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("attacked records missing")
        }

        let landed = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400)],
            spinyInputs: [spiny: SM64SpinyTickInput(distanceToMario: 1_000, landed: true)]
        )
        require(landed.spinyEffects[0].effects == [.animate, .landed], "Spiny landing")
        require(landed.spinyEffects[0].action == .walk, "Spiny returns to walk")
        require((engineState.objects.record(for: spiny)?.objectFlags ?? 0) & SM64ObjectScheduler.objectFlagTransformRelativeToParent == 0, "relative transform cleared")
        guard let landedLakituRecord = engineState.objects.record(for: lakitu),
              let landedSpinyRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("landed records missing")
        }

        let unloaded = bridge.tick(
            state: engineState,
            inputs: [lakitu: SM64EnemyLakituTickInput(distanceToMario: 400)],
            spinyInputs: [spiny: SM64SpinyTickInput(distanceToMario: 3_000)]
        )
        require(unloaded.spinyEffects[0].effects == [.animate, .markForDeletion], "Spiny distance deletion")
        require(unloaded.scheduler.unloaded.map(\.traceSubject) == [3], "Spiny unload ordering")
        require(!engineState.objects.contains(spiny) && bridge.spinyState(for: spiny) == nil, "Spiny shadow removed")

        var fingerprint = fnvOffset
        fingerprint = hashTick(fingerprint, far, lakituRecord: farLakituRecord, spinyRecord: nil)
        fingerprint = hashTick(
            fingerprint,
            reveal,
            lakituRecord: revealLakituRecord,
            spinyRecord: nil
        )
        fingerprint = hashTick(
            fingerprint,
            spawned,
            lakituRecord: spawnedLakituRecord,
            spinyRecord: spawnedSpinyRecord
        )

        fingerprint = hashTick(fingerprint, beginThrow, lakituRecord: beginThrowLakituRecord, spinyRecord: beginThrowSpinyRecord)
        fingerprint = hashTick(fingerprint, clearPrevious, lakituRecord: clearLakituRecord, spinyRecord: clearSpinyRecord)
        fingerprint = hashTick(fingerprint, attacked, lakituRecord: attackedLakituRecord, spinyRecord: attackedSpinyRecord)
        fingerprint = hashTick(fingerprint, landed, lakituRecord: landedLakituRecord, spinyRecord: landedSpinyRecord)
        fingerprint = hashTick(fingerprint, unloaded, lakituRecord: engineState.objects.record(for: lakitu), spinyRecord: nil)

        print(String(format: "enemyLakituObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Enemy Lakitu object bridge smoke passed")
    }
}
