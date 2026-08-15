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
    _ tick: SM64SpinySchedulerTickResult,
    record: SM64ObjectRecord
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.attackHandler.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
    }
    hash = hashU64(hash, UInt64(record.action))
    hash = hashU64(hash, UInt64(record.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(record.velocity.y.bitPattern))
    return hashU64(hash, UInt64(record.graphYOffset.bitPattern))
}

private func hashAttackTable(_ initial: UInt64) -> UInt64 {
    let attacks: [SM64SpinyAttack] = [
        .none, .punch, .kickOrTrip, .fromAbove,
        .groundPound, .fastAttack, .fromBelow,
    ]
    var hash = initial
    for attack in attacks {
        let handler = SM64SpinyAttackTable.decision(attack)
        hash = hashU64(hash, UInt64(attack.rawValue))
        hash = hashU64(hash, UInt64(handler.rawValue))
        hash = hashU64(hash, handler != .nop ? 1 : 0)
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSpinyEnemySmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64SpinyObjectBridge()
        let parent = try engineState.spawnObject(in: .spawner)
        let spiny = try bridge.spawnSpiny(
            in: engineState,
            action: .heldByLakitu,
            parent: parent
        )
        _ = try engineState.spawnObject(in: .player, isMario: true)
        require(spiny.traceSubject == 2, "stable Spiny slot")

        let thrown = bridge.tick(
            state: engineState,
            inputs: [spiny: SM64SpinyTickInput()]
        )
        require(thrown.scheduler.updated.map(\.traceSubject) == [1, 3, 2], "Spiny scheduler order")
        require(thrown.effects[0].effects == [.animate, .throwFromLakitu], "Lakitu throw effect")
        require(thrown.effects[0].action == .thrownByLakitu, "thrown action")
        guard let thrownRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("Spiny record missing after throw")
        }
        require(thrownRecord.forwardVelocity == 10 && thrownRecord.velocity.y == 30, "throw velocity")
        require(thrownRecord.graphYOffset == 15, "held/thrown graph offset")

        let landed = bridge.tick(
            state: engineState,
            inputs: [spiny: SM64SpinyTickInput(distanceToMario: 1_000, landed: true)]
        )
        require(landed.effects[0].effects == [.animate, .landed], "landing effect raw=\(landed.effects[0].effects.rawValue)")
        require(landed.effects[0].action == .walk, "landing action")
        guard let landedRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("Spiny record missing after landing")
        }

        let attacked = bridge.tick(
            state: engineState,
            inputs: [spiny: SM64SpinyTickInput(distanceToMario: 1_000, attack: .punch)]
        )
        require(attacked.effects[0].attackHandler == .knockback, "Spiny punch handler")
        require(attacked.effects[0].effects == [.animate, .turn, .attackResponse], "reduced knockback effect raw=\(attacked.effects[0].effects.rawValue)")
        guard let attackedRecord = engineState.objects.record(for: spiny) else {
            preconditionFailure("Spiny record missing after attack")
        }
        require(abs(attackedRecord.forwardVelocity - 0.9) < 0.0001 && attackedRecord.velocity.y == 21, "reduced knockback values forward=\(attackedRecord.forwardVelocity) velocity=\(attackedRecord.velocity.y)")

        let unloaded = bridge.tick(
            state: engineState,
            inputs: [spiny: SM64SpinyTickInput(distanceToMario: 3_000)]
        )
        require(unloaded.effects[0].effects == [.animate, .markForDeletion], "parent-distance unload effect")
        require(unloaded.scheduler.unloaded.map(\.traceSubject) == [2], "Spiny end-of-frame unload")
        require(!engineState.objects.contains(spiny) && bridge.state(for: spiny) == nil, "Spiny shadow removed")

        var fingerprint = fnvOffset
        fingerprint = hashTick(fingerprint, thrown, record: thrownRecord)
        fingerprint = hashTick(fingerprint, landed, record: landedRecord)
        fingerprint = hashTick(fingerprint, attacked, record: attackedRecord)
        // The final record was unloaded, so hash its pre-unload POD from the
        // attack result and the scheduler/effect values directly.
        let unloadedRecord = attackedRecord
        fingerprint = hashTick(fingerprint, unloaded, record: unloadedRecord)
        fingerprint = hashAttackTable(fingerprint)

        print(String(format: "spinyEnemyFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Spiny enemy smoke passed")
    }
}
