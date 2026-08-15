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

private func hashRecord(_ initial: UInt64, _ record: SM64ObjectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(record.action))
    hash = hashU64(hash, UInt64(record.previousAction))
    hash = hashU64(hash, UInt64(record.objectFlags))
    hash = hashU64(hash, UInt64(record.gravity.bitPattern))
    hash = hashU64(hash, UInt64(record.hitboxRadius.bitPattern))
    hash = hashU64(hash, UInt64(record.velocity.y.bitPattern))
    return hashU64(hash, UInt64(record.scale.x.bitPattern))
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64GoombaSchedulerTickResult,
    regularRecord: SM64ObjectRecord
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
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.attackHandler.rawValue))
        hash = hashU64(hash, effect.attackDropsBlueCoin ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.deathSound.rawValue))
        hash = hashU64(hash, UInt64(effect.numLootCoins))
        hash = hashU64(hash, effect.respawnMarked ? 1 : 0)
    }
    return hashRecord(hash, regularRecord)
}

private func hashTriplet(
    _ initial: UInt64,
    spawner: SM64ObjectID,
    children: [SM64ObjectID],
    spawned: SM64GoombaSchedulerTickResult,
    death: SM64GoombaSchedulerTickResult,
    parentBehaviorParams: Int32
) -> UInt64 {
    var hash = hashU64(initial, UInt64(spawner.traceSubject))
    hash = hashU64(hash, UInt64(SM64GoombaTripletSpawnerAction.loaded.rawValue))
    hash = hashU64(hash, UInt64(children.count))
    for (index, child) in children.enumerated() {
        hash = hashU64(hash, UInt64(child.traceSubject))
        hash = hashU64(hash, UInt64(2 | (4 << index)))
    }
    hash = hashU64(hash, UInt64(spawned.scheduler.updated.count))
    for id in spawned.scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(death.scheduler.unloaded.count))
    for id in death.scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(death.respawnRequests.count))
    for request in death.respawnRequests {
        hash = hashU64(hash, UInt64(request.sourceID.traceSubject))
        hash = hashU64(hash, UInt64(request.parentID?.traceSubject ?? 0))
        hash = hashU64(hash, UInt64(request.tripletFlag ?? 0))
        hash = hashU64(hash, UInt64(request.parentMask))
        hash = hashU64(hash, UInt64(request.respawnBit))
    }
    return hashU64(hash, UInt64(UInt32(bitPattern: parentBehaviorParams)))
}

private func hashAttackTable(_ initial: UInt64) -> UInt64 {
    let sizes: [SM64GoombaSize] = [.regular, .huge, .tiny]
    let attacks: [SM64GoombaAttack] = [
        .none, .weak, .fromAbove, .groundPound,
        .punch, .kickOrTrip, .fastAttack, .fromBelow,
    ]
    var hash = initial
    for size in sizes {
        hash = hashU64(hash, UInt64(size.rawValue))
        for attack in attacks {
            let decision = SM64GoombaAttackTable.decision(size: size, attack: attack)
            hash = hashU64(hash, UInt64(attack.rawValue))
            hash = hashU64(hash, UInt64(decision.handler.rawValue))
            hash = hashU64(hash, decision.accepted ? 1 : 0)
            hash = hashU64(hash, decision.dropsBlueCoin ? 1 : 0)
        }
    }
    return hash
}

private func hashCollisionAdmission(_ initial: UInt64) -> UInt64 {
    let statuses: [UInt32] = [
        0,
        0x8001, 0x8002, 0x8003, 0x8004, 0x8005, 0x8006,
        0xA000,
        0x8007,
    ]
    var hash = initial
    for status in statuses {
        let input = SM64GoombaCollisionKernel.input(
            from: SM64GoombaCollisionSnapshot(interactionStatus: status)
        )
        hash = hashU64(hash, UInt64(status))
        hash = hashU64(hash, UInt64(input.attack.rawValue))
        hash = hashU64(hash, input.attackedMario ? 1 : 0)
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernGoombaObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64GoombaObjectBridge()
        let regular = try bridge.spawnGoomba(
            in: engineState,
            objectList: .spawner,
            size: .regular
        )
        let tiny = try bridge.spawnGoomba(
            in: engineState,
            objectList: .generalActor,
            size: .tiny
        )
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(regular.traceSubject == 1 && tiny.traceSubject == 2 && mario.traceSubject == 3, "stable slot identities")
        require(bridge.registeredIDs.map(\.traceSubject) == [1, 2], "registered Goomba IDs")

        let first = bridge.tick(
            state: engineState,
            inputs: [
                regular: SM64GoombaTickInput(distanceToMario: 400, angleToMario: 0x3000),
                tiny: SM64GoombaTickInput(randomU16: 1, attack: .fromAbove),
            ]
        )
        require(first.scheduler.updated.map(\.traceSubject) == [1, 3, 2], "C object-list callback order")
        require(first.scheduler.unloaded.isEmpty, "attack response is one frame before tiny death")
        require(first.effects.map { $0.objectID.traceSubject } == [1, 2], "Goomba effects follow scheduler order")
        require(first.effects[0].effects == [.animate, .alertSound, .jump], "regular jump effects")
        require(first.effects[0].attackHandler == .nop && !first.effects[0].attackDropsBlueCoin, "regular no-attack handler")
        require(first.effects[1].effects == [.animate, .attackResponse], "tiny attack response effects raw=\(first.effects[1].effects.rawValue)")
        require(first.effects[1].attackHandler == .squished && !first.effects[1].attackDropsBlueCoin, "tiny squish handler")

        guard let firstRecord = engineState.objects.record(for: regular) else {
            preconditionFailure("regular record missing after first tick")
        }
        require(firstRecord.action == Int32(SM64GoombaAction.jump.rawValue), "action copied to object record")
        require(firstRecord.previousAction == Int32(SM64GoombaAction.walk.rawValue), "previous action copied")
        require(firstRecord.objectFlags & (SM64ObjectScheduler.objectFlagBuildTransform | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle) != 0, "graphics transform flags")
        require(firstRecord.gravity == -4 && firstRecord.hitboxRadius == 72 && firstRecord.velocity.y == 25, "Goomba POD constants copied")

        let second = bridge.tick(
            state: engineState,
            inputs: [regular: SM64GoombaTickInput(onGround: false)]
        )
        require(second.scheduler.updated.map(\.traceSubject) == [1, 3, 2], "deletion stays in list until unload")
        require(second.scheduler.unloaded.map(\.traceSubject) == [2], "tiny unload follows full callback pass")
        require(second.effects.map { $0.objectID.traceSubject } == [1, 2], "death effects retain callback order")
        require(second.effects[1].effects == [.animate, .death, .coinDrop, .markRespawn], "tiny death effects")
        require(!engineState.objects.contains(tiny), "tiny removed after scheduler unload")
        require(bridge.state(for: tiny) == nil, "shadow removed after slot unload")

        guard let secondRecord = engineState.objects.record(for: regular) else {
            preconditionFailure("regular record missing after second tick")
        }
        require(secondRecord.previousAction == Int32(SM64GoombaAction.jump.rawValue), "second action boundary")

        var fingerprint = fnvOffset
        fingerprint = hashTick(fingerprint, first, regularRecord: firstRecord)
        fingerprint = hashTick(fingerprint, second, regularRecord: secondRecord)

        let tripletEngine = SM64SwiftEngineState(objectCapacity: 12)
        let tripletBridge = SM64GoombaObjectBridge()
        let spawner = try tripletBridge.spawnTripletSpawner(
            in: tripletEngine,
            size: .tiny
        )
        _ = try tripletEngine.spawnObject(in: .player, isMario: true)
        let spawned = tripletBridge.tick(
            state: tripletEngine,
            spawnerInputs: [spawner: SM64GoombaSpawnerTickInput(distanceToMario: 1_000)]
        )
        let children = tripletBridge.goombaIDs(parent: spawner)
        require(children.count == 3, "triplet spawner creates three children")
        require(tripletBridge.spawnerState(for: spawner)?.action == .loaded, "triplet spawner loaded action")
        require(spawned.scheduler.updated.map(\.traceSubject) == [1, 2, 3, 4, 5], "spawned children join live list")
        require(tripletEngine.objects.record(for: spawner)?.behaviorParams2ndByte == Int32(SM64GoombaSize.tiny.rawValue), "spawner size parameter")
        require(children.enumerated().allSatisfy { index, child in
            tripletEngine.objects.record(for: child)?.parent == spawner &&
            tripletEngine.objects.record(for: child)?.behaviorParams2ndByte == Int32(
                SM64GoombaSize.tiny.rawValue | UInt8(4 << index)
            )
        }, "child parent and triplet flags")

        _ = tripletBridge.tick(
            state: tripletEngine,
            inputs: [children[0]: SM64GoombaTickInput(randomU16: 1, attack: .fromAbove)],
            spawnerInputs: [spawner: SM64GoombaSpawnerTickInput(distanceToMario: 1_000)]
        )
        let death = tripletBridge.tick(
            state: tripletEngine,
            inputs: [:],
            spawnerInputs: [spawner: SM64GoombaSpawnerTickInput(distanceToMario: 1_000)]
        )
        require(death.scheduler.unloaded.map(\.traceSubject) == [3], "triplet child unload actual=\(death.scheduler.unloaded.map { $0.traceSubject }) effects=\(death.effects.map { [$0.objectID.traceSubject, UInt32($0.effects.rawValue), UInt32($0.action.rawValue), UInt32($0.numLootCoins), $0.respawnMarked ? 1 : 0] })")
        require(death.respawnRequests.count == 1, "triplet respawn request")
        require(death.respawnRequests[0].parentID == spawner && death.respawnRequests[0].tripletFlag == 4, "triplet respawn identity")
        require(death.respawnRequests[0].parentMask == 0x100 && death.respawnRequests[0].respawnBit == 1, "triplet respawn masks")
        require(tripletEngine.objects.record(for: spawner)?.behaviorParams == 0x100, "parent dead flag")
        fingerprint = hashTriplet(
            fingerprint,
            spawner: spawner,
            children: children,
            spawned: spawned,
            death: death,
            parentBehaviorParams: tripletEngine.objects.record(for: spawner)?.behaviorParams ?? 0
        )
        fingerprint = hashAttackTable(fingerprint)

        let collisionEngine = SM64SwiftEngineState(objectCapacity: 6)
        let collisionBridge = SM64GoombaObjectBridge()
        let huge = try collisionBridge.spawnGoomba(
            in: collisionEngine,
            objectList: .generalActor,
            size: .huge
        )
        _ = try collisionEngine.spawnObject(in: .player, isMario: true)
        let collisionTick = collisionBridge.tick(
            state: collisionEngine,
            collisionInputs: [
                huge: SM64GoombaCollisionSnapshot(
                    randomU16: 1,
                    interactionStatus: 0x8001
                ),
            ]
        )
        require(collisionTick.effects.count == 1, "collision adapter effect")
        require(collisionTick.effects[0].attackHandler == .hugeWeaklyAttacked, "huge punch handler admission")
        require(!collisionTick.effects[0].attackDropsBlueCoin, "weak huge attack has no blue coin")
        fingerprint = hashCollisionAdmission(fingerprint)

        print(String(format: "goombaObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Goomba object bridge smoke passed")
    }
}
