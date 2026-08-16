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
    hash = hashU64(hash, UInt64(tick.ampEffects.count))
    for effect in tick.ampEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, effect.tangible ? 1 : 0)
        hash = hashU64(hash, effect.invisible ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.respawnerDeliveries.count))
    for delivery in tick.respawnerDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.booEffects.count))
    for effect in tick.booEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.opacity)))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.booDeliveries.count))
    for delivery in tick.booDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.bobombEffects.count))
    for effect in tick.bobombEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.subtype.rawValue))
        hash = hashU64(hash, UInt64(effect.heldState.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.bobombDeliveries.count))
    for delivery in tick.bobombDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.birdEffects.count))
    for effect in tick.birdEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.birdDeliveries.count))
    for delivery in tick.birdDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.swoopEffects.count))
    for effect in tick.swoopEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.swoopDeliveries.count))
    for delivery in tick.swoopDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.piranhaPlantEffects.count))
    for effect in tick.piranhaPlantEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.piranhaPlantDeliveries.count))
    for delivery in tick.piranhaPlantDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.bigBooEffects.count))
    for effect in tick.bigBooEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.variant.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.health)))
        hash = hashU64(hash, effect.starPosition == nil ? 0 : 1)
        hash = hashU64(hash, effect.collision == nil ? 0 : 1)
        hash = hashU64(hash, effect.movement == nil ? 0 : 1)
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.bigBooDeliveries.count))
    for delivery in tick.bigBooDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.flyGuyEffects.count))
    for effect in tick.flyGuyEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        if let action = effect.action {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(action.rawValue))
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.flyGuyDeliveries.count))
    for delivery in tick.flyGuyDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.bulletBillEffects.count))
    for effect in tick.bulletBillEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        if let smoke = effect.spawnedSmoke {
            hash = hashU64(hash, 1)
            hash = hashID(hash, smoke)
        } else {
            hash = hashU64(hash, 0)
        }
    }
    hash = hashU64(hash, UInt64(tick.bulletBillDeliveries.count))
    for delivery in tick.bulletBillDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.goombaEffects.count))
    for effect in tick.goombaEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.attackHandler.rawValue))
        hash = hashU64(hash, effect.attackDropsBlueCoin ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.deathSound.rawValue))
        hash = hashU64(hash, UInt64(effect.numLootCoins))
        hash = hashU64(hash, effect.respawnMarked ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.goombaRespawnRequests.count))
    for request in tick.goombaRespawnRequests {
        hash = hashID(hash, request.sourceID)
        if let parent = request.parentID {
            hash = hashU64(hash, 1)
            hash = hashID(hash, parent)
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, UInt64(request.tripletFlag ?? 0xff))
        hash = hashU64(hash, UInt64(request.parentMask))
        hash = hashU64(hash, UInt64(request.respawnBit))
    }
    hash = hashU64(hash, UInt64(tick.goombaDeliveries.count))
    for delivery in tick.goombaDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.spinyEffects.count))
    for effect in tick.spinyEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.attackHandler.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.spinyDeliveries.count))
    for delivery in tick.spinyDeliveries {
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
        let engine = SM64SwiftEngineState(objectCapacity: 20)
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
        let amp = try bridge.spawnAmp(
            in: engine,
            kind: .fixed,
            homeX: 100,
            homeY: 200,
            homeZ: 300
        )
        let boo = try bridge.spawnBoo(in: engine, homeX: 400, homeY: 500, homeZ: 600)
        require(bridge.boo.setInput(
            SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0, randomValue: 3),
            for: boo
        ), "Boo dispatch input attaches")
        let bobomb = try bridge.spawnBobomb(in: engine, homeY: 700)
        require(bridge.bobomb.setInput(
            SM64BobombTickInput(distanceFromHome: 0, facingTowardMario: true),
            for: bobomb
        ), "Bob-omb dispatch input attaches")
        let bird = try bridge.spawnBird(in: engine, kind: .spawned, homeX: 800, homeY: 900, homeZ: 1_000)
        require(bridge.bird.setInput(
            SM64BirdTickInput(initialMoveYaw: 0x1000, initialMovePitch: 3_000),
            for: bird
        ), "Bird dispatch input attaches")
        let swoop = try bridge.spawnSwoop(in: engine, positionY: 1_100)
        let piranhaPlant = try bridge.spawnPiranhaPlant(in: engine)
        require(bridge.piranhaPlant.setInput(
            SM64PiranhaPlantTickInput(distanceToMario: 2_000),
            for: piranhaPlant
        ), "Piranha Plant dispatch input attaches")
        let bigBoo = try bridge.spawnBigBoo(in: engine)
        let flyGuy = try bridge.spawnFlyGuy(in: engine)
        let bulletBill = try bridge.spawnBulletBill(in: engine)
        let goomba = try bridge.spawnGoomba(in: engine, size: .regular, moveAngleYaw: 0x100)
        require(bridge.goomba.setInput(
            SM64GoombaTickInput(distanceToMario: 1_000, randomU16: 1),
            for: goomba
        ), "Goomba dispatch input attaches")
        let spiny = try bridge.spawnSpiny(in: engine, action: .walk)
        require(bridge.spiny.setInput(
            SM64SpinyTickInput(distanceToMario: 1_000, randomU16: 1),
            for: spiny
        ), "Spiny dispatch input attaches")

        var fingerprint = fnvOffset
        var tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 3, "mixed default routes preserve live list traversal")
        require(tick.scheduler.objectCounter == 15, "mixed lists preserve object counter")
        require(tick.scheduler.updated == [amp, boo, bobomb, bird, swoop, piranhaPlant, bigBoo, flyGuy, bulletBill, goomba, spiny, pendulum, respawner, SM64ObjectID(slot: 14, generation: 1), SM64ObjectID(slot: 13, generation: 1)], "children are visited in live list order")
        require(tick.events.map(\.route) == [.amp, .boo, .bobomb, .bird, .swoop, .piranhaPlant, .bigBoo, .flyGuy, .bulletBill, .goomba, .spiny, .decorativePendulum, .respawner, .unmigrated, .unmigrated], "identity dispatch order")
        require(tick.decorativePendulumEffects.first?.output.faceRoll == 124, "pendulum route executes")
        require(tick.respawnerEffects.first?.effects == [.spawnObject, .markForDeletion], "respawner route executes")
        require(tick.ampEffects.first?.effects == [.animate, .setHitbox], "Amp route executes")
        require(tick.ampEffects.first?.action == .active, "Amp state is synchronized")
        require(tick.booEffects.first?.objectID == boo && tick.booEffects.first?.effects == [.animate, .chase], "Boo route executes")
        require(tick.booEffects.first?.action == .chase, "Boo state is synchronized")
        require(tick.bobombEffects.first?.objectID == bobomb && tick.bobombEffects.first?.effects == [.fuseSmoke, .fuseLit, .chase], "Bob-omb route executes")
        require(tick.bobombEffects.first?.action == .chase, "Bob-omb state is synchronized")
        require(tick.bobombEffects.first?.spawnedChildren == [SM64ObjectID(slot: 13, generation: 1)], "Bob-omb smoke child is visible")
        require(tick.birdEffects.first?.objectID == bird && tick.birdEffects.first?.effects == [.animate, .reveal, .flight], "Bird route executes")
        require(tick.birdEffects.first?.action == .fly, "Bird state is synchronized")
        require(tick.swoopEffects.first?.objectID == swoop && tick.swoopEffects.first?.effects == [.animate], "Swoop route executes")
        require(tick.swoopEffects.first?.action == .idle, "Swoop state is synchronized")
        require(tick.piranhaPlantEffects.first?.objectID == piranhaPlant && tick.piranhaPlantEffects.first?.effects == [.shown, .idle, .intangible], "Piranha Plant route executes")
        require(tick.piranhaPlantEffects.first?.action == .idle, "Piranha Plant state is synchronized")
        require(tick.bigBooEffects.first?.objectID == bigBoo && tick.bigBooEffects.first?.effects == [.initialize], "Big Boo route executes")
        require(tick.bigBooEffects.first?.action == .initialize, "Big Boo state is synchronized")
        require(tick.bigBooDeliveries.count == 1 && tick.bigBooDeliveries.first?.deleted.isEmpty == true, "Big Boo owner delivery is explicit")
        require(tick.flyGuyEffects.first?.objectID == flyGuy && tick.flyGuyEffects.first?.effects == [.animate, .oscillate, .idle], "Fly Guy route executes")
        require(tick.flyGuyEffects.first?.action == .idle, "Fly Guy state is synchronized")
        require(tick.flyGuyDeliveries.isEmpty, "Fly Guy idle route has no delivery")
        require(tick.bulletBillEffects.first?.objectID == bulletBill && tick.bulletBillEffects.first?.effects == [.animate, .resetToHome, .tangible], "Bullet Bill route executes")
        require(tick.bulletBillEffects.first?.action == .waiting, "Bullet Bill state is synchronized")
        require(tick.bulletBillEffects.first?.spawnedSmoke == nil && tick.bulletBillDeliveries.isEmpty, "Bullet Bill reset has no smoke delivery")
        require(tick.goombaEffects.first?.objectID == goomba && tick.goombaEffects.first?.effects == [.animate], "Goomba route executes")
        require(tick.goombaEffects.first?.action == .walk && tick.goombaEffects.first?.attackHandler == .nop, "Goomba state is synchronized")
        require(tick.goombaRespawnRequests.isEmpty && tick.goombaDeliveries.isEmpty, "Goomba idle route has no respawn delivery")
        require(tick.spinyEffects.first?.objectID == spiny && tick.spinyEffects.first?.effects == [.animate, .turn], "Spiny route executes")
        require(tick.spinyEffects.first?.action == .walk && tick.spinyEffects.first?.attackHandler == .nop, "Spiny state is synchronized")
        require(tick.spinyDeliveries.isEmpty, "Spiny idle route has no deletion delivery")
        require(tick.respawnerDeliveries.first?.deleted == [respawner], "respawner deletion routes through owner sink")
        guard let child = tick.respawnerEffects.first?.spawnedObject,
              let childRecord = engine.objects.record(for: child) else {
            preconditionFailure("dispatch respawner child missing")
        }
        require(child == SM64ObjectID(slot: 14, generation: 1), "dispatch child generation is stable")
        require(childRecord.model == 0x77 && childRecord.behaviorParams == 0x1234, "dispatch child fields transfer")
        fingerprint = hashTick(fingerprint, tick, child: childRecord)

        tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 2, "retired respawner leaves pendulum and child")
        require(tick.scheduler.objectCounter == 13, "Goomba and Spiny remain in the general actor list")
        require(tick.events.map(\.route) == [.amp, .boo, .bobomb, .bird, .swoop, .piranhaPlant, .bigBoo, .flyGuy, .bulletBill, .goomba, .spiny, .decorativePendulum, .unmigrated], "unknown child remains explicitly unmigrated")
        require(tick.respawnerEffects.isEmpty, "retired respawner is not dispatched again")
        require(
            tick.booEffects.first?.effects == [.animate, .chase, .appear, .oscillate],
            "Boo persists across dispatch ticks effects=\(tick.booEffects.first?.effects.rawValue ?? 999)"
        )
        require(tick.bobombEffects.first?.effects == [.fuseLit, .chase], "Bob-omb persists across dispatch ticks")
        require(tick.birdEffects.first?.effects == [.animate], "Bird persists across dispatch ticks effects=\(tick.birdEffects.first?.effects.rawValue ?? 999)")
        require(tick.swoopEffects.first?.effects == [.animate], "Swoop persists across dispatch ticks")
        require(tick.piranhaPlantEffects.first?.effects == [.shown, .idle, .intangible], "Piranha Plant persists across dispatch ticks")
        require(tick.bigBooEffects.first?.effects == [.initialize], "Big Boo persists across dispatch ticks")
        require(tick.bigBooDeliveries.count == 1 && tick.bigBooDeliveries.first?.deleted.isEmpty == true, "Big Boo delivery persists across dispatch ticks")
        require(tick.flyGuyEffects.first?.effects == [.animate, .oscillate, .idle], "Fly Guy persists across dispatch ticks")
        require(tick.flyGuyDeliveries.isEmpty, "Fly Guy delivery remains empty across dispatch ticks")
        require(tick.bulletBillEffects.first?.effects == [.animate], "Bullet Bill persists across dispatch ticks")
        require(tick.bulletBillEffects.first?.action == .waiting && tick.bulletBillDeliveries.isEmpty, "Bullet Bill waiting state persists")
        require(tick.goombaEffects.first?.effects == [.animate], "Goomba persists across dispatch ticks")
        require(tick.goombaEffects.first?.action == .walk && tick.goombaRespawnRequests.isEmpty, "Goomba walk state persists")
        require(tick.spinyEffects.first?.effects == [.animate], "Spiny persists across dispatch ticks")
        require(tick.spinyEffects.first?.action == .walk && tick.spinyDeliveries.isEmpty, "Spiny walk state persists")
        fingerprint = hashTick(fingerprint, tick, child: childRecord)

        print(String(format: "behaviorDispatchBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern behavior dispatch bridge smoke passed")
    }
}
