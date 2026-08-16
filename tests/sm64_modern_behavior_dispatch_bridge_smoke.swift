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

private func hashID(_ initial: UInt64, _ id: SM64ObjectID) -> UInt64 {
    let hash = hashU64(initial, UInt64(id.slot))
    return hashU64(hash, UInt64(id.generation))
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult,
    child: SM64ObjectRecord?
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    hash = hashU64(hash, UInt64(tick.scheduler.listCounts[SM64ObjectList.default.rawValue]))
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.decorativePendulumEffects.count))
    for effect in tick.decorativePendulumEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.faceRoll)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.angleVelocityRoll)))
        hash = hashU64(hash, effect.output.playsClockSound ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.respawnerEffects.count))
    for effect in tick.respawnerEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        if let spawned = effect.spawnedObject {
            hash = hashID(hash, spawned)
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, UInt64(effect.timer))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.respawnerDeliveries.count))
    for delivery in tick.respawnerDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    if let child {
        hash = hashU64(hash, UInt64(child.model))
        hash = hashU64(hash, child.behaviorIdentity)
        hash = hashU64(hash, UInt64(bitPattern: Int64(child.behaviorParams)))
        hash = hashU64(hash, UInt64(child.objectList.rawValue))
    } else {
        hash = hashU64(hash, 0)
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBehaviorDispatchBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BehaviorDispatchBridge()
        let pendulum = try bridge.spawnPendulum(
            in: engine,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            faceRoll: 100
        )
        _ = engine.objects.mutate(pendulum) { record in
            record.angleVelocity.roll = 0x20
        }
        let respawner = try bridge.spawnRespawner(
            in: engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30),
            modelToRespawn: 0x77,
            behaviorToRespawn: 0x6268_765F_746573,
            minSpawnDistance: 100,
            behaviorParams: 0x1234
        )

        var fingerprint = fnvOffset
        var tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 3, "mixed default routes preserve live list traversal")
        require(tick.scheduler.updated == [pendulum, respawner, SM64ObjectID(slot: 2, generation: 1)], "child is visited after respawner")
        require(tick.events.map(\.route) == [.decorativePendulum, .respawner, .unmigrated], "identity dispatch order")
        require(tick.decorativePendulumEffects.first?.output.faceRoll == 124, "pendulum route executes")
        require(tick.respawnerEffects.first?.effects == [.spawnObject, .markForDeletion], "respawner route executes")
        require(tick.respawnerDeliveries.first?.deleted == [respawner], "respawner deletion routes through owner sink")
        guard let child = tick.respawnerEffects.first?.spawnedObject,
              let childRecord = engine.objects.record(for: child) else {
            preconditionFailure("dispatch respawner child missing")
        }
        require(child == SM64ObjectID(slot: 2, generation: 1), "dispatch child generation is stable")
        require(childRecord.model == 0x77 && childRecord.behaviorParams == 0x1234, "dispatch child fields transfer")
        fingerprint = hashTick(fingerprint, tick, child: childRecord)

        tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 2, "retired respawner leaves pendulum and child")
        require(tick.events.map(\.route) == [.decorativePendulum, .unmigrated], "unknown child remains explicitly unmigrated")
        require(tick.respawnerEffects.isEmpty, "retired respawner is not dispatched again")
        fingerprint = hashTick(fingerprint, tick, child: childRecord)

        print(String(format: "behaviorDispatchBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern behavior dispatch bridge smoke passed")
    }
}
