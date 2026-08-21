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

private func decorativePendulumProgram() throws -> SM64BehaviorScriptProgram {
    var data = Data()
    func appendWord(_ word: UInt32) {
        data.append(UInt8(truncatingIfNeeded: word))
        data.append(UInt8(truncatingIfNeeded: word >> 8))
        data.append(UInt8(truncatingIfNeeded: word >> 16))
        data.append(UInt8(truncatingIfNeeded: word >> 24))
    }
    appendWord(0x0008_0000) // BEGIN(OBJ_LIST_DEFAULT)
    appendWord(0x1100_0001) // OR_INT(oFlags, update-gfx)
    appendWord(0x0C00_0000) // CALL_NATIVE(init)
    appendWord(0x0000_0001)
    appendWord(0x0800_0000) // BEGIN_LOOP()
    appendWord(0x0C00_0000) // CALL_NATIVE(loop)
    appendWord(0x0000_0002)
    appendWord(0x0900_0000) // END_LOOP()
    return try SM64BehaviorScriptProgram(data: data)
}

private func decorativePendulumCollisionWorld() throws -> SM64SurfaceCollisionWorld {
    try SM64SurfaceCollisionWorld(staticSurfaces: [
        SM64Surface(
            id: 0x44,
            room: 7,
            vertex1: SM64SurfaceVec3s(x: -100, y: 0, z: -100),
            vertex2: SM64SurfaceVec3s(x: -100, y: 0, z: 100),
            vertex3: SM64SurfaceVec3s(x: 100, y: 0, z: -100),
            normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
            originOffset: 0
        )
    ])
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
    hash = hashU64(hash, UInt64(tick.snufitEffects.count))
    for effect in tick.snufitEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        if let action = effect.action {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(action.rawValue))
        } else {
            hash = hashU64(hash, 0)
        }
        if let bulletAction = effect.bulletAction {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(bulletAction.rawValue))
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedBullets.count))
        for child in effect.spawnedBullets { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.snufitDeliveries.count))
    for delivery in tick.snufitDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.whompEffects.count))
    for effect in tick.whompEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.size.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.health)))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
        hash = hashU64(hash, effect.collision == nil ? 0 : 1)
        hash = hashU64(hash, effect.movement == nil ? 0 : 1)
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.whompDeliveries.count))
    for delivery in tick.whompDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.heaveHoEffects.count))
    for effect in tick.heaveHoEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        if let action = effect.action {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(action.rawValue))
        } else {
            hash = hashU64(hash, 0)
        }
        if let heldState = effect.heldState {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(heldState.rawValue))
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, effect.throwConsumed ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.heaveHoDeliveries.count))
    for delivery in tick.heaveHoDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.chuckyaEffects.count))
    for effect in tick.chuckyaEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        if let action = effect.action {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(action.rawValue))
        } else {
            hash = hashU64(hash, 0)
        }
        if let throwState = effect.throwState {
            hash = hashU64(hash, 1)
            hash = hashU64(hash, UInt64(throwState))
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, effect.throwConsumed ? 1 : 0)
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.chuckyaDeliveries.count))
    for delivery in tick.chuckyaDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.skeeterEffects.count))
    for effect in tick.skeeterEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, effect.isWave ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedWaves.count))
        for id in effect.spawnedWaves { hash = hashID(hash, id) }
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(effect.animationState))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.skeeterDeliveries.count))
    for delivery in tick.skeeterDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.bullyEffects.count))
    for effect in tick.bullyEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.size.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.bullyDeliveries.count))
    for delivery in tick.bullyDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
    }
    hash = hashU64(hash, UInt64(tick.enemyLakituEffects.count))
    for effect in tick.enemyLakituEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.subAction.rawValue))
        hash = hashU64(hash, UInt64(effect.numSpinies))
        if let spawnedSpiny = effect.spawnedSpiny {
            hash = hashU64(hash, 1)
            hash = hashID(hash, spawnedSpiny)
        } else {
            hash = hashU64(hash, 0)
        }
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

private func hashChainDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashU64(hash, UInt64(event.objectID.traceSubject))
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.chainChompEffects.count))
    for effect in tick.chainChompEffects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.index))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 255))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.chainChompDeliveries.count))
    for delivery in tick.chainChompDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashU64(hash, UInt64(id.traceSubject)) }
    }
    return hash
}

private func hashChainReleaseDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashU64(hash, UInt64(event.objectID.traceSubject))
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.chainChompReleaseEffects.count))
    for effect in tick.chainChompReleaseEffects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedCoins))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.chainChompReleaseRequests.count))
    for id in tick.chainChompReleaseRequests { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.chainChompReleaseDeliveries.count))
    for delivery in tick.chainChompReleaseDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashU64(hash, UInt64(id.traceSubject)) }
        hash = hashU64(hash, UInt64(delivery.presented.count))
    }
    hash = hashU64(hash, UInt64(tick.chainChompEffects.count))
    for effect in tick.chainChompEffects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.index))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 255))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.chainChompDeliveries.count))
    return hash
}

private func hashPokeyDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashU64(hash, UInt64(event.objectID.traceSubject))
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.pokeyEffects.count))
    for effect in tick.pokeyEffects {
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
    hash = hashU64(hash, UInt64(tick.pokeyDeliveries.count))
    for delivery in tick.pokeyDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashU64(hash, UInt64(id.traceSubject)) }
    }
    return hash
}

private func hashScuttlebugDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.scuttlebugEffects.count))
    for effect in tick.scuttlebugEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 255))
        if let child = effect.spawnedChild {
            hash = hashU64(hash, 1)
            hash = hashID(hash, child)
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.scuttlebugDeliveries.count))
    for delivery in tick.scuttlebugDeliveries {
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        for id in delivery.deleted { hash = hashID(hash, id) }
        hash = hashU64(hash, UInt64(delivery.presented.count))
    }
    return hash
}

private func hashBobombBuddyDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.bobombBuddyEffects.count))
    for effect in tick.bobombBuddyEffects {
        hash = hashID(hash, effect.objectID)
        let state = effect.output.state
        hash = hashU64(hash, UInt64(bitPattern: Int64(state.action)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(state.role)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(state.cannonStatus)))
        hash = hashU64(hash, state.hasTalked ? 1 : 0)
        hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
        hash = hashU64(hash, UInt64(state.blinkTimer))
        hash = hashU64(hash, effect.output.playWalkingSound ? 1 : 0)
        hash = hashU64(hash, effect.output.playReadSignSound ? 1 : 0)
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.dialogID)))
        hash = hashU64(hash, effect.output.dialogRequested ? 1 : 0)
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.cameraRequest)))
        hash = hashU64(hash, effect.output.activeTimeStop ? 1 : 0)
        hash = hashU64(hash, effect.output.clearTimeStop ? 1 : 0)
        hash = hashU64(hash, effect.output.clearInteraction ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.output.visibilityDistance.bitPattern))
        if let cannon = effect.nearestCannonID {
            hash = hashU64(hash, 1)
            hash = hashID(hash, cannon)
        } else {
            hash = hashU64(hash, 0)
        }
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.bobombBuddyDeliveries.count))
    for delivery in tick.bobombBuddyDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashBowserShockWaveDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.bowserShockWaveEffects.count))
    for effect in tick.bowserShockWaveEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.timer))
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.opacity)))
        hash = hashU64(hash, effect.interactedMario ? 1 : 0)
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    return hash
}

private func hashBowserKeyDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.bowserKeyEffects.count))
    for effect in tick.bowserKeyEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.timer))
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(UInt16(bitPattern: effect.faceYaw)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.faceRoll)))
        hash = hashU64(hash, UInt64(effect.graphYOffset.bitPattern))
        hash = hashU64(hash, effect.tangible ? 1 : 0)
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    return hash
}

private func hashBouncingFireballDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.bouncingFireballEffects.count))
    for effect in tick.bouncingFireballEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.action))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, UInt64(effect.flameScale.bitPattern))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    return hash
}

private func hashKingBobombDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.kingBobombEffects.count))
    for effect in tick.kingBobombEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.state.action)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.state.subAction)))
        hash = hashU64(hash, UInt64(effect.output.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.kingBobombDeliveries.count))
    for delivery in tick.kingBobombDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashSLWalkingPenguinDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.slWalkingPenguinEffects.count))
    for effect in tick.slWalkingPenguinEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.action)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.currentStep)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.currentStepTimer)))
        hash = hashU64(hash, UInt64(effect.forwardVelocity.bitPattern))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animation)))
        hash = hashU64(hash, UInt64(effect.animationSpeed.bitPattern))
        hash = hashU64(hash, UInt64(UInt16(bitPattern: effect.angleVelocityYaw)))
        hash = hashU64(hash, UInt64(UInt16(bitPattern: effect.moveYaw)))
        hash = hashU64(hash, effect.completedTurn ? 1 : 0)
        hash = hashU64(hash, effect.collision == nil ? 0 : 1)
        hash = hashU64(hash, effect.movement == nil ? 0 : 1)
    }
    return hash
}

private func hashSmallPenguinDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.smallPenguinEffects.count))
    for effect in tick.smallPenguinEffects {
        hash = hashID(hash, effect.objectID)
        let state = effect.output.state
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
        hash = hashU64(hash, UInt64(bitPattern: Int64(state.heldState)))
        hash = hashU64(hash, UInt64(UInt16(bitPattern: effect.output.angleVelocityYaw)))
        hash = hashU64(hash, effect.output.resetHome ? 1 : 0)
        hash = hashU64(hash, effect.output.playWalkingSound ? 1 : 0)
        hash = hashU64(hash, effect.output.playDiveSound ? 1 : 0)
        hash = hashU64(hash, effect.output.playHeldYellSound ? 1 : 0)
        hash = hashU64(hash, effect.output.unrenderHeldObject ? 1 : 0)
        hash = hashU64(hash, effect.output.copiedToMario ? 1 : 0)
        hash = hashU64(hash, effect.output.setSmallPenguinBehavior ? 1 : 0)
        hash = hashU64(hash, effect.output.thrown ? 1 : 0)
        hash = hashU64(hash, effect.output.dropped ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        hash = hashU64(hash, effect.collision == nil ? 0 : 1)
        hash = hashU64(hash, effect.movement == nil ? 0 : 1)
    }
    hash = hashU64(hash, UInt64(tick.smallPenguinDeliveries.count))
    for delivery in tick.smallPenguinDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashKoopaShellDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.koopaShellEffects.count))
    for effect in tick.koopaShellEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.koopaShellDeliveries.count))
    for delivery in tick.koopaShellDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashBowserKeyCutsceneDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.bowserKeyCutsceneEffects.count))
    for effect in tick.bowserKeyCutsceneEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animationFrame)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animation)))
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(effect.timer))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    return hash
}

private func hashExplosionDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.explosionEffects.count))
    for effect in tick.explosionEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.bubbleCount)))
        hash = hashU64(hash, effect.spawnedSmoke ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.timer))
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.opacity)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animationState)))
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        for intent in effect.presentedEffects {
            hash = hashU64(hash, UInt64(intent.kind.rawValue))
            hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
        }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
    }
    hash = hashU64(hash, UInt64(tick.explosionDeliveries.count))
    for delivery in tick.explosionDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashMoneybagDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.moneybagEffects.count))
    for effect in tick.moneybagEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, effect.kind ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.action))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.moneybagDeliveries.count))
    for delivery in tick.moneybagDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashWaterBombDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.waterBombEffects.count))
    for effect in tick.waterBombEffects {
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
    hash = hashU64(hash, UInt64(tick.waterBombDeliveries.count))
    for delivery in tick.waterBombDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashEyerokDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.eyerokEffects.count))
    for effect in tick.eyerokEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.parentID?.slot ?? UInt16.max))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.side)))
        hash = hashU64(hash, UInt64(effect.bossAction?.rawValue ?? 0xff))
        hash = hashU64(hash, UInt64(effect.handAction?.rawValue ?? 0xff))
        hash = hashU64(hash, UInt64(effect.bossEffects.rawValue))
        hash = hashU64(hash, UInt64(effect.handEffects.rawValue))
        hash = hashU64(hash, effect.starPosition == nil ? 0 : 1)
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        for intent in effect.presentedEffects {
            hash = hashU64(hash, UInt64(intent.kind.rawValue))
            hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
        }
    }
    hash = hashU64(hash, UInt64(tick.eyerokDeliveries.count))
    for delivery in tick.eyerokDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashMrIDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.mrIEffects.count))
    for effect in tick.mrIEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 0xff))
        hash = hashU64(hash, UInt64(effect.particleAction?.rawValue ?? 0xff))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.mrIDeliveries.count))
    for delivery in tick.mrIDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashRacingPenguinDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.racingPenguinEffects.count))
    for effect in tick.racingPenguinEffects {
        let output = effect.output
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.action)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.initTextCooldown)))
        hash = hashU64(hash, UInt64(output.forwardVelocity.bitPattern))
        hash = hashU64(hash, UInt64(output.weightedTargetSpeed.bitPattern))
        hash = hashU64(hash, UInt64(UInt16(bitPattern: output.moveYaw)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.animation)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.finalTextbox)))
        hash = hashU64(hash, output.marioWon ? 1 : 0)
        hash = hashU64(hash, output.marioCheated ? 1 : 0)
        hash = hashU64(hash, output.reachedBottom ? 1 : 0)
        hash = hashU64(hash, output.resetTimer ? 1 : 0)
        hash = hashU64(hash, effect.raceChildren == nil ? 0 : 1)
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.racingPenguinDeliveries.count))
    for delivery in tick.racingPenguinDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashYoshiDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.yoshiEffects.count))
    for effect in tick.yoshiEffects {
        let output = effect.output
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.state.action)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.state.timer)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.animation)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.dialogID)))
        hash = hashU64(hash, output.dialogRequested ? 1 : 0)
        hash = hashU64(hash, output.activeTimeStop ? 1 : 0)
        hash = hashU64(hash, output.clearTimeStop ? 1 : 0)
        hash = hashU64(hash, output.clearInteraction ? 1 : 0)
        hash = hashU64(hash, output.playWalkSound ? 1 : 0)
        hash = hashU64(hash, output.playPuzzleJingle ? 1 : 0)
        hash = hashU64(hash, output.playAlertSound ? 1 : 0)
        hash = hashU64(hash, output.playExtraLifeSound ? 1 : 0)
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.livesDelta)))
        hash = hashU64(hash, output.specialTripleJump ? 1 : 0)
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.cameraRequest)))
        hash = hashU64(hash, output.respawnerRequested ? 1 : 0)
        hash = hashU64(hash, output.deactivated ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.spawnedRespawners.count))
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.yoshiDeliveries.count))
    for delivery in tick.yoshiDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashBowserBombDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.bowserBombEffects.count))
    for effect in tick.bowserBombEffects {
        hash = hashID(hash, effect.objectID)
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren { hash = hashID(hash, child) }
        hash = hashU64(hash, effect.spawnedExplosionRequest ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.timer))
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.opacity)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animationState)))
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    hash = hashU64(hash, UInt64(tick.bowserBombDeliveries.count))
    for delivery in tick.bowserBombDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func hashTuxiesMotherDispatch(
    _ initial: UInt64,
    _ tick: SM64BehaviorDispatchTickResult
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    for count in tick.scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.scheduler.updated.count))
    for id in tick.scheduler.updated { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.scheduler.unloaded.count))
    for id in tick.scheduler.unloaded { hash = hashID(hash, id) }
    hash = hashU64(hash, UInt64(tick.events.count))
    for event in tick.events {
        hash = hashID(hash, event.objectID)
        hash = hashU64(hash, event.behaviorIdentity)
        hash = hashU64(hash, UInt64(event.route.rawValue))
    }
    hash = hashU64(hash, UInt64(tick.tuxiesMotherEffects.count))
    for effect in tick.tuxiesMotherEffects {
        hash = hashID(hash, effect.objectID)
        if let child = effect.childID {
            hash = hashID(hash, child)
        } else {
            hash = hashU64(hash, 0)
        }
        let output = effect.output
        hash = hashU64(hash, UInt64(bitPattern: Int64(output.action)))
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
        hash = hashU64(hash, output.starHomePosition == nil ? 0 : 1)
        hash = hashU64(hash, UInt64(output.starSpawnYOffset.bitPattern))
        hash = hashU64(hash, output.playWalkingSound ? 1 : 0)
        hash = hashU64(hash, output.playYellSound ? 1 : 0)
        hash = hashU64(hash, output.activeFlagUnk10 ? 1 : 0)
        hash = hashU64(hash, output.clearInteractionStatus ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    }
    hash = hashU64(hash, UInt64(tick.tuxiesMotherDeliveries.count))
    for delivery in tick.tuxiesMotherDeliveries {
        hash = hashU64(hash, UInt64(delivery.delivered.count))
        hash = hashU64(hash, UInt64(delivery.presented.count))
        hash = hashU64(hash, UInt64(delivery.spawned.count))
        hash = hashU64(hash, UInt64(delivery.deleted.count))
        hash = hashU64(hash, UInt64(delivery.rejected.count))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBehaviorDispatchBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 32)
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
        require(SM64BehaviorDispatchBridge.route(for: SM64BooObjectBridge.ghostHuntBehaviorIdentity) == .boo, "Ghost Hunt Boo shared identity route")
        require(SM64BehaviorDispatchBridge.route(for: SM64BooObjectBridge.merryGoRoundBehaviorIdentity) == .boo, "Merry-Go-Round Boo shared identity route")
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
        let snufit = try bridge.spawnSnufit(in: engine, moveYaw: 0x100)
        require(bridge.snufit.setSnufitInput(
            SM64SnufitTickInput(distanceToMario: 1_000, globalTimer: 1),
            for: snufit
        ), "Snufit dispatch input attaches")
        let whomp = try bridge.spawnWhomp(in: engine)
        let heaveHo = try bridge.spawnHeaveHo(in: engine)
        let chuckya = try bridge.spawnChuckya(in: engine)
        let skeeter = try bridge.spawnSkeeter(in: engine)
        require(bridge.skeeter.setInput(
            SM64SkeeterTickInput(moveFlags: SM64SkeeterKernel.atWaterSurfaceFlag),
            for: skeeter
        ), "Skeeter dispatch input attaches")
        let smallBully = try bridge.spawnBully(in: engine, size: .small, homeY: 100)
        require(bridge.bully.setInput(
            SM64BullyTickInput(angleToMario: 0x1000, distanceFromHome: 0),
            for: smallBully
        ), "small Bully dispatch input attaches")
        let bigBully = try bridge.spawnBully(in: engine, size: .big, homeY: 100)
        require(bridge.bully.setInput(
            SM64BullyTickInput(angleToMario: 0x2000, distanceFromHome: 0),
            for: bigBully
        ), "big Bully dispatch input attaches")
        let lakitu = try bridge.spawnEnemyLakitu(in: engine)
        require(bridge.enemyLakitu.attach(
            lakitu,
            in: engine.objects,
            state: SM64EnemyLakituState(action: .main)
        ), "Enemy Lakitu dispatch state attaches")
        require(bridge.enemyLakitu.setInput(
            SM64EnemyLakituTickInput(distanceToMario: 400, angleToMario: 0),
            for: lakitu
        ), "Enemy Lakitu dispatch input attaches")

        var fingerprint = fnvOffset
        var tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 3, "mixed default routes preserve live list traversal")
        require(tick.scheduler.objectCounter == 29, "mixed lists preserve object counter")
        require(tick.scheduler.updated == [lakitu, whomp, amp, boo, bobomb, bird, swoop, piranhaPlant, bigBoo, flyGuy, bulletBill, goomba, spiny, snufit, heaveHo, SM64ObjectID(slot: 16, generation: 1), chuckya, SM64ObjectID(slot: 18, generation: 1), skeeter, smallBully, bigBully, SM64ObjectID(slot: 23, generation: 1), SM64ObjectID(slot: 25, generation: 1), SM64ObjectID(slot: 26, generation: 1), SM64ObjectID(slot: 27, generation: 1), SM64ObjectID(slot: 28, generation: 1), pendulum, respawner, SM64ObjectID(slot: 29, generation: 1), SM64ObjectID(slot: 24, generation: 1)], "children are visited in live list order")
        require(tick.events.map(\.route) == [.enemyLakitu, .whomp, .amp, .boo, .bobomb, .bird, .swoop, .piranhaPlant, .bigBoo, .flyGuy, .bulletBill, .goomba, .spiny, .snufit, .heaveHo, .heaveHo, .chuckya, .chuckya, .skeeter, .bully, .bully, .spiny, .skeeter, .skeeter, .skeeter, .skeeter, .decorativePendulum, .respawner, .unmigrated, .unmigrated], "identity dispatch order")
        require(tick.whompEffects.first?.objectID == whomp && tick.whompEffects.first?.size == .normal, "Whomp route executes")
        require(tick.whompEffects.first?.action == .initialize && tick.whompEffects.first?.effects == [.animate, .resetHome], "Whomp state is synchronized")
        require(tick.whompEffects.first?.health == 1 && tick.whompEffects.first?.collision == nil && tick.whompEffects.first?.movement == nil, "Whomp shared route stays value-only")
        require(tick.whompDeliveries.count == 1 && tick.whompDeliveries.first?.deleted.isEmpty == true, "Whomp owner delivery is explicit")
        require(tick.heaveHoEffects.map(\.objectID) == [heaveHo, SM64ObjectID(slot: 16, generation: 1)], "Heave Ho parent and throw child dispatch")
        require(tick.heaveHoEffects.first?.kind == .heaveHo && tick.heaveHoEffects.first?.action == .submerged, "Heave Ho parent route executes")
        require(tick.heaveHoEffects.first?.effects == [.intangible, .hide], "Heave Ho submerged state is synchronized")
        require(tick.heaveHoEffects.last?.kind == .throwChild && tick.heaveHoEffects.last?.effects.isEmpty == true, "Heave Ho throw child route executes")
        require(tick.heaveHoDeliveries.isEmpty, "Heave Ho idle route has no delivery")
        require(tick.chuckyaEffects.map(\.objectID) == [chuckya, SM64ObjectID(slot: 18, generation: 1)], "Chuckya parent and anchor dispatch")
        require(tick.chuckyaEffects.first?.kind == .chuckya && tick.chuckyaEffects.first?.action == .patrol, "Chuckya parent route executes")
        require(tick.chuckyaEffects.first?.effects == [.animate], "Chuckya patrol state is synchronized")
        require(tick.chuckyaEffects.last?.kind == .anchor && tick.chuckyaEffects.last?.effects.isEmpty == true, "Chuckya anchor route executes")
        require(tick.chuckyaDeliveries.isEmpty, "Chuckya idle route has no delivery")
        require(tick.skeeterEffects.map(\.objectID) == [skeeter, SM64ObjectID(slot: 25, generation: 1), SM64ObjectID(slot: 26, generation: 1), SM64ObjectID(slot: 27, generation: 1), SM64ObjectID(slot: 28, generation: 1)], "Skeeter parent and waves dispatch")
        require(tick.skeeterEffects.first?.effects == [.animate, .spawnWaves] && tick.skeeterEffects.first?.spawnedWaves.count == 4, "Skeeter wave route executes")
        require(tick.skeeterEffects.dropFirst().allSatisfy { $0.isWave && $0.scale == 0.5 }, "Skeeter wave state is synchronized")
        require(tick.skeeterDeliveries.isEmpty, "Skeeter idle route has no delivery")
        require(tick.enemyLakituEffects.count == 1 && tick.enemyLakituEffects.first?.objectID == lakitu, "Enemy Lakitu route executes")
        require(tick.enemyLakituEffects.first?.effects == [.animate, .spawnSpiny, .beginHold], "Enemy Lakitu spawns and holds a Spiny")
        require(tick.enemyLakituEffects.first?.subAction == .holdSpiny && tick.enemyLakituEffects.first?.numSpinies == 1, "Enemy Lakitu state is synchronized")
        guard let lakituChild = tick.enemyLakituEffects.first?.spawnedSpiny,
              let lakituRecord = engine.objects.record(for: lakitu),
              let lakituChildRecord = engine.objects.record(for: lakituChild) else {
            preconditionFailure("Enemy Lakitu child records missing")
        }
        require(lakituChild == SM64ObjectID(slot: 23, generation: 1) && lakituChildRecord.parent == lakitu, "Enemy Lakitu child identity is stable")
        require(lakituRecord.previousObject == lakituChild && lakituChildRecord.objectFlags & SM64ObjectScheduler.objectFlagTransformRelativeToParent != 0, "Enemy Lakitu parent link is explicit")
        require(tick.spinyEffects.count == 2 && tick.spinyEffects.last?.objectID == lakituChild && tick.spinyEffects.last?.action == .heldByLakitu, "Enemy Lakitu child dispatches through shared Spiny route")
        require(tick.bullyEffects.map(\.objectID) == [smallBully, bigBully], "Bully routes execute in source order")
        require(tick.bullyEffects.map(\.size) == [.small, .big] && tick.bullyEffects.allSatisfy { $0.action == .chase }, "Bully chase state is synchronized")
        require(tick.bullyEffects.allSatisfy { $0.effects == [.animate, .chase, .patrol] }, "Bully patrol/chase effects are preserved")
        require(tick.bullyDeliveries.count == 2 && tick.bullyDeliveries.allSatisfy { $0.deleted.isEmpty }, "Bully owner delivery is explicit")
        require(tick.decorativePendulumEffects.first?.output.faceRoll == 124, "pendulum route executes")
        require(
            bridge.decorativePendulum.schema4TraceRecords.isEmpty,
            "identity-only pendulum remains trace-silent without source configuration"
        )

        var sourceTraceRecords: [SM64OracleTraceRecord] = []
        let sourceBridge = SM64BehaviorDispatchBridge()
        sourceBridge.configureDecorativePendulum(
            collisionWorld: try decorativePendulumCollisionWorld(),
            behaviorProgram: try decorativePendulumProgram(),
            traceSink: { record in
                sourceTraceRecords.append(record)
                return 0
            }
        )
        let sourceEngine = SM64SwiftEngineState(objectCapacity: 4)
        let sourcePendulum = try sourceBridge.spawnPendulum(
            in: sourceEngine,
            position: SM64ObjectVector3(x: 0, y: 200, z: 0),
            faceRoll: 100
        )
        _ = sourceEngine.objects.mutate(sourcePendulum) { record in
            record.angleVelocity.roll = 0x18
        }
        let sourceTick = sourceBridge.tick(state: sourceEngine)
        require(
            sourceTick.events.map(\.route) == [.decorativePendulum]
                && sourceTick.decorativePendulumEffects.first?.objectID == sourcePendulum
                && sourceTick.decorativePendulumTraceStatus == 0,
            "configured source-backed pendulum dispatches through the owner"
        )
        require(
            sourceTraceRecords.contains { $0.domain == 6 }
                && sourceTraceRecords.contains { $0.domain == 7 }
                && sourceTraceRecords.contains { $0.domain == 12 }
                && sourceTraceRecords.allSatisfy { $0.simulationTick == sourceTick.scheduler.frame },
            "configured dispatch forwards source, collision, effect, and simulation tick records"
        )
        require(tick.respawnerEffects.first?.effects == [.spawnObject, .markForDeletion], "respawner route executes")
        require(tick.ampEffects.first?.effects == [.animate, .setHitbox], "Amp route executes")
        require(tick.ampEffects.first?.action == .active, "Amp state is synchronized")
        require(tick.booEffects.first?.objectID == boo && tick.booEffects.first?.effects == [.animate, .chase], "Boo route executes")
        require(tick.booEffects.first?.action == .chase, "Boo state is synchronized")
        require(tick.bobombEffects.first?.objectID == bobomb && tick.bobombEffects.first?.effects == [.fuseSmoke, .fuseLit, .chase], "Bob-omb route executes")
        require(tick.bobombEffects.first?.action == .chase, "Bob-omb state is synchronized")
        require(tick.bobombEffects.first?.spawnedChildren == [SM64ObjectID(slot: 24, generation: 1)], "Bob-omb smoke child is visible")
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
        require(tick.snufitEffects.first?.objectID == snufit && tick.snufitEffects.first?.kind == .snufit, "Snufit route executes")
        require(tick.snufitEffects.first?.effects == [.orbit, .idle, .tangible], "Snufit state is synchronized")
        require(tick.snufitEffects.first?.action == .idle && tick.snufitDeliveries.isEmpty, "Snufit idle route has no delivery")
        require(tick.respawnerDeliveries.first?.deleted == [respawner], "respawner deletion routes through owner sink")
        guard let child = tick.respawnerEffects.first?.spawnedObject,
              let childRecord = engine.objects.record(for: child) else {
            preconditionFailure("dispatch respawner child missing")
        }
        require(child == SM64ObjectID(slot: 29, generation: 1), "dispatch child generation is stable")
        require(childRecord.model == 0x77 && childRecord.behaviorParams == 0x1234, "dispatch child fields transfer")
        fingerprint = hashTick(fingerprint, tick, child: childRecord)

        require(bridge.skeeter.setInput(SM64SkeeterTickInput(), for: skeeter), "Skeeter second-tick input attaches")
        tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 2, "retired respawner leaves pendulum and child")
        require(tick.scheduler.objectCounter == 27, "Whomp, Heave Ho, Chuckya, Skeeter, Bully, Enemy Lakitu, Goomba, Spiny, and Snufit remain in their owner lists")
        require(tick.events.map(\.route) == [.enemyLakitu, .whomp, .amp, .boo, .bobomb, .bird, .swoop, .piranhaPlant, .bigBoo, .flyGuy, .bulletBill, .goomba, .spiny, .snufit, .heaveHo, .heaveHo, .chuckya, .chuckya, .skeeter, .bully, .bully, .spiny, .skeeter, .skeeter, .skeeter, .skeeter, .decorativePendulum, .unmigrated], "unknown child remains explicitly unmigrated")
        require(tick.enemyLakituEffects.first?.effects == [.animate] && tick.enemyLakituEffects.first?.spawnedSpiny == nil, "Enemy Lakitu hold state persists")
        require(tick.enemyLakituEffects.first?.subAction == .holdSpiny && tick.enemyLakituEffects.first?.numSpinies == 1, "Enemy Lakitu child count persists")
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
        require(tick.snufitEffects.first?.effects == [.orbit, .idle, .tangible], "Snufit persists across dispatch ticks")
        require(tick.snufitEffects.first?.action == .idle && tick.snufitDeliveries.isEmpty, "Snufit idle state persists")
        require(tick.whompEffects.first?.effects == [.animate, .resetHome], "Whomp persists across dispatch ticks")
        require(tick.whompEffects.first?.action == .initialize && tick.whompDeliveries.count == 1, "Whomp initialize state persists")
        require(tick.heaveHoEffects.map(\.kind) == [.heaveHo, .throwChild], "Heave Ho composite route persists across dispatch ticks")
        require(tick.heaveHoEffects.first?.effects == [.intangible, .hide] && tick.heaveHoDeliveries.isEmpty, "Heave Ho submerged state persists")
        require(tick.chuckyaEffects.map(\.kind) == [.chuckya, .anchor], "Chuckya composite route persists across dispatch ticks")
        require(tick.chuckyaEffects.first?.effects == [.animate, .move] && tick.chuckyaDeliveries.isEmpty, "Chuckya patrol state persists")
        require(tick.skeeterEffects.map(\.objectID) == [skeeter, SM64ObjectID(slot: 25, generation: 1), SM64ObjectID(slot: 26, generation: 1), SM64ObjectID(slot: 27, generation: 1), SM64ObjectID(slot: 28, generation: 1)], "Skeeter composite route persists across dispatch ticks")
        require(tick.skeeterEffects.first?.effects == [.animate] && tick.skeeterEffects.dropFirst().allSatisfy { abs($0.scale - 0.2) < 0.0001 }, "Skeeter wave state persists")
        require(tick.bullyEffects.map(\.objectID) == [smallBully, bigBully] && tick.bullyEffects.allSatisfy { $0.effects == [.animate, .chase] }, "Bully chase state persists")
        require(tick.bullyDeliveries.count == 2 && tick.bullyDeliveries.allSatisfy { $0.deleted.isEmpty }, "Bully delivery remains explicit")
        fingerprint = hashTick(fingerprint, tick, child: childRecord)

        let chainEngine = SM64SwiftEngineState(objectCapacity: 16)
        let chainBridge = SM64BehaviorDispatchBridge()
        let chain = try chainBridge.spawnChainChomp(in: chainEngine, homeX: 5, homeY: 200, homeZ: 15)
        require(chainBridge.chainChomp.setInput(
            SM64ChainChompTickInput(distanceToMario: 200, angleToMario: 0),
            for: chain
        ), "Chain Chomp dispatch input attaches")
        let chainTick = chainBridge.tick(state: chainEngine)
        require(chainTick.events.map(\.route) == [.chainChomp, .chainChomp, .chainChomp, .chainChomp, .chainChomp, .chainChomp], "Chain Chomp parent and segments dispatch")
        require(chainTick.scheduler.updated.map(\.traceSubject) == [1, 2, 3, 4, 5, 6], "Chain Chomp segments follow parent")
        require(chainTick.chainChompEffects.count == 6 && chainTick.chainChompEffects.first?.kind == .chomp, "Chain Chomp route allocates five segments")
        require(chainTick.chainChompEffects.first?.effects == [.animate, .allocateChain, .turn], "Chain Chomp allocation effect is preserved")
        require(chainTick.chainChompEffects.dropFirst().allSatisfy { $0.kind == .segment && $0.effects == [.animate] }, "Chain Chomp segment effects are synchronized")
        require(chainTick.chainChompDeliveries.isEmpty, "Chain Chomp idle route has no delivery")
        fingerprint = hashChainDispatch(fingerprint, chainTick)

        let releaseEngine = SM64SwiftEngineState(objectCapacity: 24)
        let releaseBridge = SM64BehaviorDispatchBridge()
        let releaseParent = try releaseBridge.spawnChainChomp(in: releaseEngine, homeX: 10, homeY: 200, homeZ: 20)
        let releasePost = try releaseBridge.spawnChainChompPost(in: releaseEngine, parent: releaseParent, homeY: 200)
        let releaseGate = try releaseBridge.spawnChainChompGate(
            in: releaseEngine,
            parent: releaseParent,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30)
        )
        require(releasePost.traceSubject == 2 && releaseGate.traceSubject == 3, "Chain Chomp release IDs are stable")
        require(releaseBridge.chainChomp.setInput(
            SM64ChainChompTickInput(distanceToMario: 200, angleToMario: 0), for: releaseParent
        ), "Chain Chomp release parent input attaches")
        require(releaseBridge.chainChompRelease.setPostInput(
            SM64ChainChompPostTickInput(marioGroundPounding: true), for: releasePost
        ), "Chain Chomp post input attaches")
        require(releaseBridge.chainChompRelease.setGateHit(true, for: releaseGate), "Chain Chomp gate input attaches")
        let releaseTick = releaseBridge.tick(state: releaseEngine)
        require(
            releaseTick.events.map(\.route) == [.chainChompRelease, .chainChompRelease] + Array(repeating: .chainChomp, count: 6),
            "Chain Chomp release children precede parent route"
        )
        require(
            releaseTick.scheduler.updated.map(\.traceSubject) == [2, 3, 1, 4, 5, 6, 7, 8],
            "Chain Chomp release surface order is preserved"
        )
        require(releaseTick.chainChompReleaseEffects.count == 2, "Chain Chomp release effects are recorded")
        require(
            releaseTick.chainChompReleaseEffects.first?.effects == [.poundSound]
                && releaseTick.chainChompReleaseEffects.first?.kind == .woodenPost,
            "Chain Chomp post pound effect is preserved"
        )
        require(
            releaseTick.chainChompReleaseEffects.last?.kind == .gate
                && releaseTick.chainChompReleaseEffects.last?.effects.rawValue == 0x3E0
                && releaseTick.chainChompReleaseEffects.last?.markedForDeletion == true,
            "Chain Chomp gate break effect is preserved"
        )
        require(releaseTick.chainChompReleaseRequests.isEmpty, "Chain Chomp post pound does not release early")
        require(
            releaseTick.chainChompReleaseDeliveries.count == 1
                && releaseTick.chainChompReleaseDeliveries.first?.deleted == [releaseGate],
            "Chain Chomp gate deletion uses owner delivery"
        )
        require(releaseTick.chainChompEffects.count == 6, "Chain Chomp parent still allocates its segments")
        fingerprint = hashChainReleaseDispatch(fingerprint, releaseTick)

        let pokeyEngine = SM64SwiftEngineState(objectCapacity: 16)
        let pokeyBridge = SM64BehaviorDispatchBridge()
        let pokey = try pokeyBridge.spawnPokey(in: pokeyEngine, homeX: 30, homeY: 100, homeZ: -20)
        require(pokeyBridge.pokey.setParentInput(
            SM64PokeyParentTickInput(distanceToMario: 1_000), for: pokey
        ), "Pokey parent input attaches")
        let pokeyTick = pokeyBridge.tick(state: pokeyEngine)
        require(
            pokeyTick.events.map(\.route) == Array(repeating: .pokey, count: 6),
            "Pokey parent and body parts dispatch"
        )
        require(
            pokeyTick.scheduler.updated.map(\.traceSubject) == [1, 2, 3, 4, 5, 6],
            "Pokey body parts follow parent"
        )
        require(pokeyTick.pokeyEffects.count == 6, "Pokey route allocates five body parts")
        require(
            pokeyTick.pokeyEffects.first?.kind == .parent
                && pokeyTick.pokeyEffects.first?.effects == [.animate, .spawnParts, .wander]
                && pokeyTick.pokeyEffects.first?.spawnedParts.map(\.traceSubject) == [2, 3, 4, 5, 6],
            "Pokey parent allocation effect is preserved"
        )
        require(
            pokeyTick.pokeyEffects.dropFirst().allSatisfy { $0.kind == .bodyPart && $0.effects == [.animate] },
            "Pokey body parts animate in source order"
        )
        require(pokeyTick.pokeyDeliveries.isEmpty, "Pokey spawn route has no deletion delivery")
        fingerprint = hashPokeyDispatch(fingerprint, pokeyTick)

        let scuttlebugEngine = SM64SwiftEngineState(objectCapacity: 16)
        let scuttlebugBridge = SM64BehaviorDispatchBridge()
        let scuttlebugSpawner = try scuttlebugBridge.spawnScuttlebugSpawner(in: scuttlebugEngine)
        var scuttlebugSpawnTick: SM64BehaviorDispatchTickResult?
        for _ in 0..<40 where scuttlebugSpawnTick == nil {
            require(scuttlebugBridge.scuttlebug.setSpawnerInput(
                SM64ScuttlebugSpawnerTickInput(distanceToMario: 1_000),
                for: scuttlebugSpawner
            ), "Scuttlebug spawner input attaches")
            let candidate = scuttlebugBridge.tick(state: scuttlebugEngine)
            if candidate.scuttlebugEffects.contains(where: { $0.spawnedChild != nil }) {
                scuttlebugSpawnTick = candidate
            }
        }
        guard let scuttlebugTick = scuttlebugSpawnTick else {
            preconditionFailure("Scuttlebug child did not spawn")
        }
        require(
            scuttlebugTick.events.map(\.route) == [.scuttlebug, .scuttlebug],
            "Scuttlebug spawner and child dispatch"
        )
        require(
            scuttlebugTick.scheduler.updated.map(\.traceSubject) == [1, 2],
            "Scuttlebug child follows spawner across lists"
        )
        require(
            scuttlebugTick.scuttlebugEffects.count == 2
                && scuttlebugTick.scuttlebugEffects.first?.kind == .spawner
                && scuttlebugTick.scuttlebugEffects.first?.spawnedChild?.traceSubject == 2
                && scuttlebugTick.scuttlebugEffects.last?.kind == .scuttlebug,
            "Scuttlebug spawn effect is preserved"
        )
        require(scuttlebugTick.scuttlebugDeliveries.isEmpty, "Scuttlebug spawn route has no deletion delivery")
        fingerprint = hashScuttlebugDispatch(fingerprint, scuttlebugTick)

        let buddyEngine = SM64SwiftEngineState(objectCapacity: 8)
        let buddyBridge = SM64BehaviorDispatchBridge()
        _ = try buddyBridge.spawnBobombBuddy(in: buddyEngine)
        let buddyTick = buddyBridge.tick(state: buddyEngine)
        require(buddyTick.events.map(\.route) == [.bobombBuddy], "Bob-omb Buddy route dispatch")
        require(buddyTick.scheduler.updated.map(\.traceSubject) == [1], "Bob-omb Buddy callback ordering")
        require(buddyTick.bobombBuddyEffects.count == 1, "Bob-omb Buddy effect is recorded")
        require(buddyTick.bobombBuddyDeliveries.count == 1 && buddyTick.bobombBuddyDeliveries.first?.presented.isEmpty == true, "Bob-omb Buddy empty owner delivery is explicit")
        fingerprint = hashBobombBuddyDispatch(fingerprint, buddyTick)

        let shockEngine = SM64SwiftEngineState(objectCapacity: 8)
        let shockBridge = SM64BehaviorDispatchBridge()
        _ = try shockBridge.spawnBowserShockWave(in: shockEngine)
        let shockTick = shockBridge.tick(state: shockEngine)
        require(shockTick.events.map(\.route) == [.bowserShockWave], "Bowser shockwave route dispatch")
        require(shockTick.scheduler.updated.map(\.traceSubject) == [1], "Bowser shockwave callback ordering")
        require(
            shockTick.bowserShockWaveEffects.count == 1
                && shockTick.bowserShockWaveEffects.first?.timer == 1,
            "Bowser shockwave effect is recorded"
        )
        fingerprint = hashBowserShockWaveDispatch(fingerprint, shockTick)

        let keyEngine = SM64SwiftEngineState(objectCapacity: 8)
        let keyBridge = SM64BehaviorDispatchBridge()
        _ = try keyBridge.spawnBowserKey(in: keyEngine)
        let keyTick = keyBridge.tick(state: keyEngine)
        require(keyTick.events.map(\.route) == [.bowserKey], "Bowser key route dispatch")
        require(keyTick.scheduler.updated.map(\.traceSubject) == [1], "Bowser key callback ordering")
        require(
            keyTick.bowserKeyEffects.count == 1
                && keyTick.bowserKeyEffects.first?.effects == [.sparkleParticles, .sparkleSpawn],
            "Bowser key effect is recorded"
        )
        fingerprint = hashBowserKeyDispatch(fingerprint, keyTick)

        let fireballEngine = SM64SwiftEngineState(objectCapacity: 8)
        let fireballBridge = SM64BehaviorDispatchBridge()
        let fireball = try fireballBridge.spawnBouncingFireball(in: fireballEngine)
        let fireballFlame = try fireballBridge.spawnBouncingFireballFlame(in: fireballEngine)
        let fireballTick = fireballBridge.tick(state: fireballEngine)
        require(
            fireballTick.events.map(\.route) == [.bouncingFireball, .bouncingFireball],
            "Bouncing fireball parent and flame dispatch"
        )
        require(
            fireballTick.scheduler.updated.map(\.traceSubject) == [2, 1],
            "Bouncing fireball child follows parent"
        )
        require(
            fireballTick.bouncingFireballEffects.count == 2
                && fireballTick.bouncingFireballEffects.first?.objectID == fireballFlame
                && fireballTick.bouncingFireballEffects.first?.kind == .flame
                && fireballTick.bouncingFireballEffects.last?.objectID == fireball
                && fireballTick.bouncingFireballEffects.last?.kind == .fireball,
            "Bouncing fireball parent/flame effects are preserved"
        )
        fingerprint = hashBouncingFireballDispatch(fingerprint, fireballTick)

        let kingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let kingBridge = SM64BehaviorDispatchBridge()
        let king = try kingBridge.spawnKingBobomb(in: kingEngine, homeY: 100, positionY: 100)
        require(kingBridge.kingBobomb.setEnvironment(
            SM64KingBobombEnvironment(input: SM64KingBobombInput(
                positionY: 100,
                dialogCanActivate: true
            )),
            for: king
        ), "King Bob-omb dispatch environment attaches")
        let kingTick = kingBridge.tick(state: kingEngine)
        require(kingTick.events.map(\.route) == [.kingBobomb], "King Bob-omb route dispatch")
        require(kingTick.scheduler.updated.map(\.traceSubject) == [1], "King Bob-omb callback ordering")
        require(
            kingTick.kingBobombEffects.count == 1
                && kingTick.kingBobombEffects.first?.output.state.subAction == 1
                && kingTick.kingBobombEffects.first?.output.effects == [.resetHome, .cameraFocus, .bossMusic, .intangible, .renderingEnabled]
                && kingTick.kingBobombEffects.first?.presentedEffects.count == 1,
            "King Bob-omb intro route is preserved effects=\(kingTick.kingBobombEffects.first?.output.effects.rawValue ?? 0) sub=\(kingTick.kingBobombEffects.first?.output.state.subAction ?? -1) presented=\(kingTick.kingBobombEffects.first?.presentedEffects.count ?? -1)"
        )
        require(
            kingTick.kingBobombDeliveries.count == 1
                && kingTick.kingBobombDeliveries.first?.presented.count == 1,
            "King Bob-omb owner presentation is explicit"
        )
        fingerprint = hashKingBobombDispatch(fingerprint, kingTick)

        let penguinEngine = SM64SwiftEngineState(objectCapacity: 8)
        let penguinBridge = SM64BehaviorDispatchBridge()
        let penguin = try penguinBridge.spawnSLWalkingPenguin(
            in: penguinEngine,
            position: SM64ObjectVector3(x: 600, y: 12, z: -40),
            moveYaw: 0x2000
        )
        let penguinTick = penguinBridge.tick(state: penguinEngine)
        require(penguinTick.events.map(\.route) == [.slWalkingPenguin], "SL walking penguin route dispatch")
        require(penguinTick.scheduler.updated.map(\.traceSubject) == [1], "SL walking penguin callback ordering")
        require(
            penguinTick.slWalkingPenguinEffects.count == 1
                && penguinTick.slWalkingPenguinEffects.first?.objectID == penguin
                && penguinTick.slWalkingPenguinEffects.first?.collision == nil
                && penguinTick.slWalkingPenguinEffects.first?.movement == nil,
            "SL walking penguin value route is preserved"
        )
        fingerprint = hashSLWalkingPenguinDispatch(fingerprint, penguinTick)

        let smallEngine = SM64SwiftEngineState(objectCapacity: 8)
        let smallBridge = SM64BehaviorDispatchBridge()
        let smallPenguin = try smallBridge.spawnSmallPenguin(in: smallEngine)
        _ = smallEngine.objects.mutate(smallPenguin) { record in
            record.soundStateID = 1
        }
        let smallTick = smallBridge.tick(state: smallEngine)
        require(smallTick.events.map(\.route) == [.smallPenguin], "small penguin route dispatch")
        require(smallTick.scheduler.updated.map(\.traceSubject) == [1], "small penguin callback ordering")
        require(
            smallTick.smallPenguinEffects.count == 1
                && smallTick.smallPenguinEffects.first?.objectID == smallPenguin
                && smallTick.smallPenguinEffects.first?.output.state.action == SM64SmallPenguinBehavior.idleAction
                && smallTick.smallPenguinEffects.first?.output.state.timer == 1
                && smallTick.smallPenguinEffects.first?.output.state.animation == SM64SmallPenguinBehavior.idleAnimation
                && smallTick.smallPenguinEffects.first?.presentedEffects.isEmpty == true,
            "small penguin value route is preserved"
        )
        require(
            smallTick.smallPenguinDeliveries.count == 1
                && smallTick.smallPenguinDeliveries.first?.delivered.isEmpty == true,
            "small penguin owner delivery is explicit"
        )
        fingerprint = hashSmallPenguinDispatch(fingerprint, smallTick)

        let shellEngine = SM64SwiftEngineState(objectCapacity: 8)
        let shellBridge = SM64BehaviorDispatchBridge()
        let underwaterShell = try shellBridge.spawnKoopaUnderwaterShell(
            in: shellEngine,
            positionX: -30,
            positionY: 20,
            positionZ: 4
        )
        let shellTick = shellBridge.tick(state: shellEngine)
        require(shellTick.events.map(\.route) == [.koopaShell], "Koopa underwater shell route dispatch")
        require(shellTick.scheduler.updated.map(\.traceSubject) == [1], "Koopa shell callback ordering")
        require(
            shellTick.koopaShellEffects.count == 1
                && shellTick.koopaShellEffects.first?.objectID == underwaterShell
                && shellTick.koopaShellEffects.first?.kind == .underwater
                && shellTick.koopaShellEffects.first?.effects == [.animate, .tangible]
                && shellTick.koopaShellEffects.first?.action == .free
                && shellTick.koopaShellEffects.first?.spawnedChildren.isEmpty == true,
            "Koopa underwater shell value route is preserved"
        )
        require(shellTick.koopaShellDeliveries.isEmpty, "Koopa shell idle route has no delivery")
        fingerprint = hashKoopaShellDispatch(fingerprint, shellTick)

        let cutsceneEngine = SM64SwiftEngineState(objectCapacity: 8)
        let cutsceneBridge = SM64BehaviorDispatchBridge()
        let cutsceneKey = try cutsceneBridge.spawnBowserKeyCutscene(
            kind: .courseExit,
            in: cutsceneEngine,
            position: SM64ObjectVector3(x: 4, y: 5, z: 6)
        )
        let cutsceneTick = cutsceneBridge.tick(state: cutsceneEngine)
        require(cutsceneTick.events.map(\.route) == [.bowserKeyCutscene], "Bowser key cutscene route dispatch")
        require(cutsceneTick.scheduler.updated.map(\.traceSubject) == [1], "Bowser key cutscene callback ordering")
        require(
            cutsceneTick.bowserKeyCutsceneEffects.count == 1
                && cutsceneTick.bowserKeyCutsceneEffects.first?.objectID == cutsceneKey
                && cutsceneTick.bowserKeyCutsceneEffects.first?.kind == .courseExit,
            "Bowser key cutscene value route is preserved"
        )
        fingerprint = hashBowserKeyCutsceneDispatch(fingerprint, cutsceneTick)

        let explosionEngine = SM64SwiftEngineState(objectCapacity: 8)
        let explosionBridge = SM64BehaviorDispatchBridge()
        let explosion = try explosionBridge.spawnExplosion(
            in: explosionEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30)
        )
        let explosionTick = explosionBridge.tick(state: explosionEngine)
        require(explosionTick.events.map(\.route) == [.explosion], "Explosion route dispatch")
        require(explosionTick.scheduler.updated.map(\.traceSubject) == [1], "Explosion callback ordering")
        require(
            explosionTick.explosionEffects.count == 1
                && explosionTick.explosionEffects.first?.objectID == explosion
                && explosionTick.explosionEffects.first?.effects == [.sound, .cameraShake, .fade, .animate]
                && explosionTick.explosionEffects.first?.timer == 1
                && explosionTick.explosionEffects.first?.presentedEffects.count == 2
                && explosionTick.explosionDeliveries.count == 1,
            "Explosion value/owner route is preserved"
        )
        fingerprint = hashExplosionDispatch(fingerprint, explosionTick)

        let moneybagEngine = SM64SwiftEngineState(objectCapacity: 8)
        let moneybagBridge = SM64BehaviorDispatchBridge()
        let moneybag = try moneybagBridge.spawnMoneybag(
            in: moneybagEngine,
            action: .death,
            positionX: 20,
            positionY: 30,
            positionZ: 40
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64MoneybagObjectBridge.hiddenBehaviorIdentity) == .moneybag,
            "hidden Moneybag identity shares the owner route"
        )
        let moneybagTick = moneybagBridge.tick(state: moneybagEngine)
        require(moneybagTick.events.map(\.route) == [.moneybag], "Moneybag route dispatch")
        require(moneybagTick.scheduler.updated.map(\.traceSubject) == [1], "Moneybag callback ordering")
        require(
            moneybagTick.moneybagEffects.count == 1
                && moneybagTick.moneybagEffects.first?.objectID == moneybag
                && moneybagTick.moneybagEffects.first?.kind == false
                && moneybagTick.moneybagEffects.first?.action == SM64MoneybagAction.death.rawValue
                && moneybagTick.moneybagEffects.first?.effects == [.death],
            "Moneybag value/owner route is preserved"
        )
        require(moneybagTick.moneybagDeliveries.isEmpty, "Moneybag initial death has no delivery")
        fingerprint = hashMoneybagDispatch(fingerprint, moneybagTick)

        let waterBombEngine = SM64SwiftEngineState(objectCapacity: 16)
        let waterBombBridge = SM64BehaviorDispatchBridge()
        let waterBombSpawner = try waterBombBridge.spawnWaterBombSpawner(
            in: waterBombEngine,
            positionX: 0,
            positionY: 0,
            positionZ: 0,
            radiusParameter: 0
        )
        require(
            waterBombBridge.waterBomb.setSpawnerInput(
                SM64WaterBombSpawnerTickInput(
                    marioX: 100,
                    marioY: 80,
                    marioZ: 40,
                    marioForwardVelocity: 5,
                    marioMoveYaw: 0x1000,
                    randomDelay: 7
                ),
                for: waterBombSpawner
            ),
            "Water-bomb spawner input attaches"
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterBombObjectBridge.defaultBombBehaviorIdentity) == .waterBomb
                && SM64BehaviorDispatchBridge.route(for: SM64WaterBombObjectBridge.defaultShadowBehaviorIdentity) == .waterBomb,
            "Water-bomb child identities share the owner route"
        )
        let waterBombTick = waterBombBridge.tick(state: waterBombEngine)
        require(
            waterBombTick.events.map(\.route) == [.waterBomb, .waterBomb, .waterBomb],
            "Water-bomb family route dispatch"
        )
        require(
            waterBombTick.scheduler.updated.map(\.traceSubject) == [1, 2, 3],
            "Water-bomb callback ordering"
        )
        require(
            waterBombTick.waterBombEffects.count == 3
                && waterBombTick.waterBombEffects[0].kind == .spawner
                && waterBombTick.waterBombEffects[0].effects == [.animate, .spawnBomb]
                && waterBombTick.waterBombEffects[0].spawnedChildren.count == 2
                && waterBombTick.waterBombEffects[1].kind == .bomb
                && waterBombTick.waterBombEffects[1].action == .drop
                && waterBombTick.waterBombEffects[1].effects == [.animate, .landingSound]
                && waterBombTick.waterBombEffects[2].kind == .shadow
                && waterBombTick.waterBombEffects[2].action == .drop
                && waterBombTick.waterBombEffects[2].effects == [.animate],
            "Water-bomb value/owner route is preserved"
        )
        require(waterBombTick.waterBombDeliveries.isEmpty, "Water-bomb initial family has no delivery")
        fingerprint = hashWaterBombDispatch(fingerprint, waterBombTick)

        let eyerokEngine = SM64SwiftEngineState(objectCapacity: 16)
        let eyerokBridge = SM64BehaviorDispatchBridge()
        let eyerok = try eyerokBridge.spawnEyerok(
            in: eyerokEngine,
            homeX: 10,
            homeY: 20,
            homeZ: 30
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64EyerokObjectBridge.handBehaviorIdentity) == .eyerok,
            "Eyerok hand identity shares the owner route"
        )
        let eyerokTick = eyerokBridge.tick(state: eyerokEngine)
        require(
            eyerokTick.events.map(\.route) == [.eyerok, .eyerok, .eyerok],
            "Eyerok family route dispatch"
        )
        require(eyerokTick.scheduler.updated.map(\.traceSubject) == [1, 2, 3], "Eyerok callback ordering")
        require(
            eyerokTick.eyerokEffects.count == 3
                && eyerokTick.eyerokEffects[0].objectID == eyerok
                && eyerokTick.eyerokEffects[0].kind == .boss
                && eyerokTick.eyerokEffects[0].bossEffects == [.spawnHands]
                && eyerokTick.eyerokEffects[0].spawnedChildren.count == 2
                && eyerokTick.eyerokEffects[1].kind == .hand
                && eyerokTick.eyerokEffects[1].handAction == .sleep
                && eyerokTick.eyerokEffects[2].kind == .hand
                && eyerokTick.eyerokEffects[2].handAction == .sleep,
            "Eyerok value/owner route is preserved"
        )
        require(eyerokTick.eyerokDeliveries.count == 3, "Eyerok owner delivery receipts are explicit")
        fingerprint = hashEyerokDispatch(fingerprint, eyerokTick)

        let mrIEngine = SM64SwiftEngineState(objectCapacity: 16)
        let mrIBridge = SM64BehaviorDispatchBridge()
        let mrI = try mrIBridge.spawnMrI(in: mrIEngine, homeX: 40, homeY: 50, homeZ: 60)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64MrIObjectBridge.bodyBehaviorIdentity) == .mrI
                && SM64BehaviorDispatchBridge.route(for: SM64MrIObjectBridge.particleBehaviorIdentity) == .mrI,
            "Mr I child identities share the owner route"
        )
        let mrITick = mrIBridge.tick(state: mrIEngine)
        require(mrITick.events.map(\.route) == [.mrI, .mrI], "Mr I eye/body route dispatch")
        require(mrITick.scheduler.updated.map(\.traceSubject) == [1, 2], "Mr I callback ordering")
        require(
            mrITick.mrIEffects.count == 2
                && mrITick.mrIEffects[0].objectID == mrI
                && mrITick.mrIEffects[0].kind == .eye
                && mrITick.mrIEffects[0].action == .idle
                && mrITick.mrIEffects[0].effects == [.resetHome, .intangible]
                && mrITick.mrIEffects[1].kind == .body,
            "Mr I value/owner route is preserved"
        )
        require(mrITick.mrIDeliveries.isEmpty, "Mr I idle route has no delivery")
        fingerprint = hashMrIDispatch(fingerprint, mrITick)

        let racingEngine = SM64SwiftEngineState(objectCapacity: 16)
        let racingBridge = SM64BehaviorDispatchBridge()
        let racingPenguin = try racingBridge.spawnRacingPenguin(in: racingEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RacingPenguinObjectBridge.finishLineBehaviorIdentity) == .racingPenguin
                && SM64BehaviorDispatchBridge.route(for: SM64RacingPenguinObjectBridge.shortcutBehaviorIdentity) == .racingPenguin,
            "Racing-penguin child identities share the owner route"
        )
        let racingTick = racingBridge.tick(state: racingEngine)
        require(racingTick.events.map(\.route) == [.racingPenguin], "Racing-penguin route dispatch")
        require(racingTick.scheduler.updated.map(\.traceSubject) == [1], "Racing-penguin callback ordering")
        require(
            racingTick.racingPenguinEffects.count == 1
                && racingTick.racingPenguinEffects[0].objectID == racingPenguin
                && racingTick.racingPenguinEffects[0].output.action == SM64RacingPenguinBehavior.waitForMario
                && racingTick.racingPenguinEffects[0].raceChildren == nil,
            "Racing-penguin value/owner route is preserved"
        )
        require(racingTick.racingPenguinDeliveries.count == 1, "Racing-penguin owner delivery is explicit")
        fingerprint = hashRacingPenguinDispatch(fingerprint, racingTick)

        let yoshiEngine = SM64SwiftEngineState(objectCapacity: 16)
        let yoshiBridge = SM64BehaviorDispatchBridge()
        let yoshi = try yoshiBridge.spawnYoshi(in: yoshiEngine)
        let yoshiTick = yoshiBridge.tick(state: yoshiEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64YoshiObjectBridge.defaultBehaviorIdentity) == .yoshi, "Yoshi identity route")
        require(yoshiTick.events.map(\.route) == [.yoshi], "Yoshi route dispatch")
        require(yoshiTick.scheduler.updated.map(\.traceSubject) == [1], "Yoshi callback ordering")
        require(
            yoshiTick.yoshiEffects.count == 1
                && yoshiTick.yoshiEffects[0].objectID == yoshi
                && yoshiTick.yoshiEffects[0].output.state.action == SM64YoshiBehavior.idleAction
                && yoshiTick.yoshiEffects[0].output.deactivated == false,
            "Yoshi value/owner route is preserved"
        )
        require(yoshiTick.yoshiDeliveries.count == 1, "Yoshi owner delivery is explicit")
        fingerprint = hashYoshiDispatch(fingerprint, yoshiTick)

        let bowserBombEngine = SM64SwiftEngineState(objectCapacity: 16)
        let bowserBombBridge = SM64BehaviorDispatchBridge()
        let bowserBomb = try bowserBombBridge.spawnBowserBomb(in: bowserBombEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BowserBombObjectBridge.smokeBehaviorIdentity) == .bowserBomb,
            "Bowser-bomb smoke identity route"
        )
        let bowserBombTick = bowserBombBridge.tick(state: bowserBombEngine)
        require(bowserBombTick.events.map(\.route) == [.bowserBomb], "Bowser-bomb route dispatch")
        require(bowserBombTick.scheduler.updated.map(\.traceSubject) == [1], "Bowser-bomb callback ordering")
        require(
            bowserBombTick.bowserBombEffects.count == 1
                && bowserBombTick.bowserBombEffects[0].objectID == bowserBomb
                && bowserBombTick.bowserBombEffects[0].kind == .bomb,
            "Bowser-bomb value/owner route is preserved"
        )
        require(bowserBombTick.bowserBombDeliveries.isEmpty, "Bowser-bomb idle route has no delivery")
        fingerprint = hashBowserBombDispatch(fingerprint, bowserBombTick)

        let tuxiesEngine = SM64SwiftEngineState(objectCapacity: 16)
        let tuxiesBridge = SM64BehaviorDispatchBridge()
        let tuxiesMother = try tuxiesBridge.spawnTuxiesMother(in: tuxiesEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TuxiesMotherObjectBridge.defaultMotherBehaviorIdentity) == .tuxiesMother,
            "Tuxie's mother identity route"
        )
        let tuxiesTick = tuxiesBridge.tick(state: tuxiesEngine)
        require(tuxiesTick.events.map(\.route) == [.tuxiesMother], "Tuxie's mother route dispatch")
        require(tuxiesTick.scheduler.updated.map(\.traceSubject) == [1], "Tuxie's mother callback ordering")
        require(
            tuxiesTick.tuxiesMotherEffects.count == 1
                && tuxiesTick.tuxiesMotherEffects[0].objectID == tuxiesMother
                && tuxiesTick.tuxiesMotherEffects[0].output.action == SM64TuxiesMotherBehavior.followChild,
            "Tuxie's mother value/owner route is preserved"
        )
        fingerprint = hashTuxiesMotherDispatch(fingerprint, tuxiesTick)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlyGuyObjectBridge.flameBehaviorIdentity) == .flyGuy,
            "Fly Guy flame identity shares the owner route"
        )
        fingerprint = hashU64(
            fingerprint,
            UInt64(SM64BehaviorDispatchBridge.route(for: SM64FlyGuyObjectBridge.flameBehaviorIdentity).rawValue)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BowserBombObjectBridge.explosionBehaviorIdentity) == .bowserBomb,
            "Bowser mine-flame identity shares the Bowser-bomb route"
        )
        fingerprint = hashU64(
            fingerprint,
            UInt64(SM64BehaviorDispatchBridge.route(for: SM64BowserBombObjectBridge.explosionBehaviorIdentity).rawValue)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BigBooObjectBridge.staircaseBehaviorIdentity) == .bigBoo,
            "Big Boo staircase child shares the owner route"
        )
        fingerprint = hashU64(
            fingerprint,
            UInt64(SM64BehaviorDispatchBridge.route(for: SM64BigBooObjectBridge.staircaseBehaviorIdentity).rawValue)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TuxiesMotherObjectBridge.unusedChildBehaviorIdentity) == .tuxiesMother,
            "Tuxie's unused child identity shares the mother owner route"
        )
        fingerprint = hashU64(
            fingerprint,
            UInt64(SM64BehaviorDispatchBridge.route(for: SM64TuxiesMotherObjectBridge.unusedChildBehaviorIdentity).rawValue)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TuxiesMotherObjectBridge.babyChildBehaviorIdentity) == .tuxiesMother,
            "Tuxie's baby child identity shares the mother owner route"
        )
        fingerprint = hashU64(
            fingerprint,
            UInt64(SM64BehaviorDispatchBridge.route(for: SM64TuxiesMotherObjectBridge.babyChildBehaviorIdentity).rawValue)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BobombBuddyObjectBridge.opensCannonBehaviorIdentity) == .bobombBuddy,
            "Bob-omb Buddy cannon-role identity shares the owner route"
        )
        fingerprint = hashU64(
            fingerprint,
            UInt64(SM64BehaviorDispatchBridge.route(for: SM64BobombBuddyObjectBridge.opensCannonBehaviorIdentity).rawValue)
        )

        let arrowLiftEngine = SM64SwiftEngineState(objectCapacity: 8)
        let arrowLiftBridge = SM64BehaviorDispatchBridge()
        let arrowLift = try arrowLiftBridge.spawnArrowLift(in: arrowLiftEngine, faceYaw: 0)
        _ = arrowLiftEngine.objects.mutate(arrowLift) { record in
            record.timer = 61
            // The C input is gMarioObject->platform == arrow lift. The
            // focused owner smoke uses the stable object ID as that relation
            // without introducing an unrelated player dispatch event.
            record.platform = arrowLift
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ArrowLiftObjectBridge.defaultBehaviorIdentity) == .arrowLift,
            "Arrow-lift identity route"
        )
        let arrowLiftIdleTick = arrowLiftBridge.tick(state: arrowLiftEngine)
        require(arrowLiftIdleTick.events.map(\.route) == [.arrowLift], "Arrow-lift route dispatch")
        let arrowLiftTick = arrowLiftBridge.tick(state: arrowLiftEngine)
        let arrowRecord = arrowLiftEngine.objects.record(for: arrowLift)
        require(
            arrowLiftTick.events.map(\.route) == [.arrowLift]
                && arrowLiftTick.arrowLiftEffects.count == 1
                && arrowLiftTick.arrowLiftEffects[0].objectID == arrowLift
                && arrowLiftTick.arrowLiftEffects[0].output.action == 1
                && arrowLiftTick.arrowLiftEffects[0].output.displacement == 12
                && arrowRecord?.action == 1
                && arrowRecord?.position.x == -12,
            "Arrow-lift value/owner route is preserved"
        )

        let elevatorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let elevatorBridge = SM64BehaviorDispatchBridge()
        let rrElevator = try elevatorBridge.spawnElevator(
            in: elevatorEngine,
            behaviorIdentity: SM64ElevatorObjectBridge.rrBehaviorIdentity,
            positionY: 0,
            bottomY: 0,
            topY: 20,
            midpointY: 10
        )
        let hmcElevator = try elevatorBridge.spawnElevator(
            in: elevatorEngine,
            behaviorIdentity: SM64ElevatorObjectBridge.hmcBehaviorIdentity,
            positionY: 0,
            bottomY: 0,
            topY: 20,
            midpointY: 10
        )
        let meshElevator = try elevatorBridge.spawnElevator(
            in: elevatorEngine,
            behaviorIdentity: SM64ElevatorObjectBridge.meshBehaviorIdentity,
            positionY: 0,
            bottomY: 0,
            topY: 20,
            midpointY: 10
        )
        for id in [rrElevator, hmcElevator, meshElevator] {
            _ = elevatorEngine.objects.mutate(id) { record in
                record.action = 1
                record.timer = 0
                record.platform = id
            }
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ElevatorObjectBridge.rrBehaviorIdentity) == .elevator
                && SM64BehaviorDispatchBridge.route(for: SM64ElevatorObjectBridge.hmcBehaviorIdentity) == .elevator
                && SM64BehaviorDispatchBridge.route(for: SM64ElevatorObjectBridge.meshBehaviorIdentity) == .elevator,
            "Elevator family identities share the owner route"
        )
        let elevatorTick = elevatorBridge.tick(state: elevatorEngine)
        require(
            elevatorTick.events.map(\.route) == [.elevator, .elevator, .elevator]
                && elevatorTick.elevatorEffects.count == 3
                && elevatorTick.elevatorEffects.allSatisfy { $0.output.velocityY == 2 }
                && elevatorEngine.objects.record(for: rrElevator)?.position.y == 2
                && elevatorEngine.objects.record(for: hmcElevator)?.position.y == 2
                && elevatorEngine.objects.record(for: meshElevator)?.position.y == 2,
            "Elevator family value/owner route is preserved"
        )

        let seesawEngine = SM64SwiftEngineState(objectCapacity: 8)
        let seesawBridge = SM64BehaviorDispatchBridge()
        let seesaw = try seesawBridge.spawnSeesawPlatform(in: seesawEngine, behaviorByte: 1)
        _ = seesawEngine.objects.mutate(seesaw) { record in
            record.distanceToMario = 100
            record.angleToMario = 0
            record.moveAngles.yaw = 0
            record.platform = seesaw
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SeesawPlatformObjectBridge.defaultBehaviorIdentity) == .seesawPlatform,
            "Seesaw-platform identity route"
        )
        let seesawTick = seesawBridge.tick(state: seesawEngine)
        require(
            seesawTick.events.map(\.route) == [.seesawPlatform]
                && seesawTick.seesawPlatformEffects.count == 1
                && seesawTick.seesawPlatformEffects[0].output.pitchVelocity == 2
                && seesawTick.seesawPlatformEffects[0].output.playsRockingSound == false
                && seesawEngine.objects.record(for: seesaw)?.faceAngles.pitch == 0,
            "Seesaw-platform value/owner route is preserved"
        )

        let swingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let swingBridge = SM64BehaviorDispatchBridge()
        let swing = try swingBridge.spawnSwingPlatform(in: swingEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SwingPlatformObjectBridge.defaultBehaviorIdentity) == .swingPlatform,
            "Swing-platform identity route"
        )
        let swingTick = swingBridge.tick(state: swingEngine)
        require(
            swingTick.events.map(\.route) == [.swingPlatform]
                && swingTick.swingPlatformEffects.count == 1
                && swingTick.swingPlatformEffects[0].output.speed == -4
                && swingTick.swingPlatformEffects[0].output.faceRoll == 8188
                && swingEngine.objects.record(for: swing)?.faceAngles.roll == 8188,
            "Swing-platform value/owner route is preserved"
        )

        let rotatingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let rotatingBridge = SM64BehaviorDispatchBridge()
        let rotating = try rotatingBridge.spawnRotatingPlatform(
            in: rotatingEngine,
            faceYaw: 0,
            speedByte: 8,
            action: 1
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RotatingPlatformObjectBridge.defaultBehaviorIdentity) == .rotatingPlatform,
            "Rotating-platform identity route"
        )
        let rotatingTick = rotatingBridge.tick(state: rotatingEngine)
        require(
            rotatingTick.events.map(\.route) == [.rotatingPlatform]
                && rotatingTick.rotatingPlatformEffects.count == 1
                && rotatingTick.rotatingPlatformEffects[0].output.angleVelocityYaw == 128
                && rotatingTick.rotatingPlatformEffects[0].output.faceYaw == 128
                && rotatingTick.rotatingPlatformEffects[0].output.playsLoopSound
                && rotatingEngine.objects.record(for: rotating)?.faceAngles.yaw == 128,
            "Rotating-platform value/owner route is preserved"
        )

        let movingBarEngine = SM64SwiftEngineState(objectCapacity: 8)
        let movingBarBridge = SM64BehaviorDispatchBridge()
        let movingBar = try movingBarBridge.spawnTTCMovingBar(
            in: movingBarEngine,
            faceYaw: 0,
            speedSetting: 0,
            behaviorByte: 0
        )
        _ = movingBarEngine.objects.mutate(movingBar) { record in
            record.timer = 56
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCMovingBarObjectBridge.defaultBehaviorIdentity) == .ttcMovingBar,
            "TTC moving-bar identity route"
        )
        let movingBarTick = movingBarBridge.tick(state: movingBarEngine)
        require(
            movingBarTick.events.map(\.route) == [.ttcMovingBar]
                && movingBarTick.ttcMovingBarEffects.count == 1
                && movingBarTick.ttcMovingBarEffects[0].output.action == 1
                && movingBarTick.ttcMovingBarEffects[0].output.speed == -8
                && movingBarTick.ttcMovingBarEffects[0].output.moveYaw == 0x4000
                && movingBarEngine.objects.record(for: movingBar)?.action == 1,
            "TTC moving-bar value/owner route is preserved"
        )

        let spinnerEngine = SM64SwiftEngineState(objectCapacity: 8)
        let spinnerBridge = SM64BehaviorDispatchBridge()
        let spinner = try spinnerBridge.spawnTTCSpinner(
            in: spinnerEngine,
            facePitch: 0x1000,
            speedSetting: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCSpinnerObjectBridge.defaultBehaviorIdentity) == .ttcSpinner,
            "TTC spinner identity route"
        )
        let spinnerTick = spinnerBridge.tick(state: spinnerEngine)
        require(
            spinnerTick.events.map(\.route) == [.ttcSpinner]
                && spinnerTick.ttcSpinnerEffects.count == 1
                && spinnerTick.ttcSpinnerEffects[0].output.angleVelocityPitch == 200
                && spinnerTick.ttcSpinnerEffects[0].output.facePitch == 0x10C8
                && spinnerEngine.objects.record(for: spinner)?.faceAngles.pitch == 0x10C8,
            "TTC spinner value/owner route is preserved"
        )

        let treadmillEngine = SM64SwiftEngineState(objectCapacity: 8)
        let treadmillBridge = SM64BehaviorDispatchBridge()
        let treadmill = try treadmillBridge.spawnTTCTreadmill(
            in: treadmillEngine,
            faceYaw: 0,
            speedSetting: 0,
            behaviorByte: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCTreadmillObjectBridge.defaultBehaviorIdentity) == .ttcTreadmill,
            "TTC treadmill identity route"
        )
        let treadmillTick = treadmillBridge.tick(state: treadmillEngine)
        require(
            treadmillTick.events.map(\.route) == [.ttcTreadmill]
                && treadmillTick.ttcTreadmillEffects.count == 1
                && treadmillTick.ttcTreadmillEffects[0].output.becameMaster
                && treadmillTick.ttcTreadmillEffects[0].output.forwardVelocity == 4.2
                && treadmillEngine.objects.record(for: treadmill)?.forwardVelocity == 4.2,
            "TTC treadmill value/owner route is preserved"
        )

        let pendulumEngine = SM64SwiftEngineState(objectCapacity: 8)
        let pendulumBridge = SM64BehaviorDispatchBridge()
        let ttcPendulum = try pendulumBridge.spawnTTCPendulum(
            in: pendulumEngine,
            speedSetting: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCPendulumObjectBridge.defaultBehaviorIdentity) == .ttcPendulum,
            "TTC pendulum identity route"
        )
        let pendulumTick = pendulumBridge.tick(state: pendulumEngine)
        require(
            pendulumTick.events.map(\.route) == [.ttcPendulum]
                && pendulumTick.ttcPendulumEffects.count == 1
                && pendulumTick.ttcPendulumEffects[0].output.angle == 6487
                && pendulumTick.ttcPendulumEffects[0].output.angleVelocity == -13
                && pendulumEngine.objects.record(for: ttcPendulum)?.faceAngles.roll == 6487,
            "TTC pendulum value/owner route is preserved"
        )

        let ttcElevatorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let ttcElevatorBridge = SM64BehaviorDispatchBridge()
        let ttcElevator = try ttcElevatorBridge.spawnTTCElevator(
            in: ttcElevatorEngine,
            positionY: 100,
            behaviorParameterHigh: 0,
            speedSetting: 0,
            direction: 1
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCElevatorObjectBridge.defaultBehaviorIdentity) == .ttcElevator,
            "TTC elevator identity route"
        )
        let ttcElevatorTick = ttcElevatorBridge.tick(state: ttcElevatorEngine)
        require(
            ttcElevatorTick.events.map(\.route) == [.ttcElevator]
                && ttcElevatorTick.ttcElevatorEffects.count == 1
                && ttcElevatorTick.ttcElevatorEffects[0].output.velocityY == 6
                && ttcElevatorTick.ttcElevatorEffects[0].output.positionY == 106
                && ttcElevatorEngine.objects.record(for: ttcElevator)?.position.y == 106,
            "TTC elevator value/owner route is preserved"
        )

        let rotatingSolidEngine = SM64SwiftEngineState(objectCapacity: 8)
        let rotatingSolidBridge = SM64BehaviorDispatchBridge()
        let rotatingSolid = try rotatingSolidBridge.spawnTTCRotatingSolid(
            in: rotatingSolidEngine,
            positionY: 0,
            behaviorByte: 0,
            speedSetting: 0
        )
        _ = rotatingSolidEngine.objects.mutate(rotatingSolid) { record in
            record.timer = 121
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCRotatingSolidObjectBridge.defaultBehaviorIdentity) == .ttcRotatingSolid,
            "TTC rotating-solid identity route"
        )
        let rotatingSolidTick = rotatingSolidBridge.tick(state: rotatingSolidEngine)
        require(
            rotatingSolidTick.events.map(\.route) == [.ttcRotatingSolid]
                && rotatingSolidTick.ttcRotatingSolidEffects.count == 1
                && rotatingSolidTick.ttcRotatingSolidEffects[0].output.playedClickSound
                && rotatingSolidTick.ttcRotatingSolidEffects[0].output.numberOfTurns == 1
                && rotatingSolidEngine.objects.record(for: rotatingSolid)?.faceAngles.roll == 0,
            "TTC rotating-solid value/owner route is preserved"
        )

        let rotator2DEngine = SM64SwiftEngineState(objectCapacity: 8)
        let rotator2DBridge = SM64BehaviorDispatchBridge()
        let rotator2D = try rotator2DBridge.spawnTTC2DRotator(
            in: rotator2DEngine,
            faceYaw: 0,
            behaviorByte: 0,
            speedSetting: 0
        )
        _ = rotator2DEngine.objects.mutate(rotator2D) { record in
            record.timer = 41
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTC2DRotatorObjectBridge.defaultBehaviorIdentity) == .ttc2DRotator,
            "TTC 2D rotator identity route"
        )
        let rotator2DTick = rotator2DBridge.tick(state: rotator2DEngine)
        require(
            rotator2DTick.events.map(\.route) == [.ttc2DRotator]
                && rotator2DTick.ttc2DRotatorEffects.count == 1
                && rotator2DTick.ttc2DRotatorEffects[0].output.targetYaw == -0x444
                && rotator2DTick.ttc2DRotatorEffects[0].output.timer == 0
                && rotator2DEngine.objects.record(for: rotator2D)?.faceAngles.yaw == 0,
            "TTC 2D rotator value/owner route is preserved"
        )

        let cogEngine = SM64SwiftEngineState(objectCapacity: 8)
        let cogBridge = SM64BehaviorDispatchBridge()
        let cog = try cogBridge.spawnTTCCog(in: cogEngine, faceYaw: 0, behaviorByte: 0, speedSetting: 0)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCCogObjectBridge.defaultBehaviorIdentity) == .ttcCog,
            "TTC cog identity route"
        )
        let cogTick = cogBridge.tick(state: cogEngine)
        require(
            cogTick.events.map(\.route) == [.ttcCog]
                && cogTick.ttcCogEffects.count == 1
                && cogTick.ttcCogEffects[0].output.speed == 200
                && cogTick.ttcCogEffects[0].output.angleVelocityYaw == 200
                && cogEngine.objects.record(for: cog)?.faceAngles.yaw == 200,
            "TTC cog value/owner route is preserved"
        )

        let pyramidEngine = SM64SwiftEngineState(objectCapacity: 8)
        let pyramidBridge = SM64BehaviorDispatchBridge()
        let pyramid = try pyramidBridge.spawnPyramidElevator(in: pyramidEngine, positionY: 4600)
        let marker = try pyramidBridge.spawnPyramidMarker(
            in: pyramidEngine,
            parent: pyramid,
            positionY: 4600
        )
        _ = pyramidEngine.objects.mutate(pyramid) { record in record.platform = pyramid }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64PyramidElevatorObjectBridge.elevatorBehaviorIdentity) == .pyramidElevator
                && SM64BehaviorDispatchBridge.route(for: SM64PyramidElevatorObjectBridge.markerBehaviorIdentity) == .pyramidMarker,
            "Pyramid elevator/marker identities route"
        )
        let pyramidTick = pyramidBridge.tick(state: pyramidEngine)
        require(
            pyramidTick.events.map(\.route) == [.pyramidElevator, .pyramidMarker]
                && pyramidTick.pyramidElevatorEffects.count == 1
                && pyramidTick.pyramidElevatorEffects[0].output.action == 1
                && pyramidTick.pyramidMarkerEffects.count == 1
                && pyramidTick.pyramidMarkerEffects[0].objectID == marker
                && !pyramidTick.pyramidMarkerEffects[0].active
                && pyramidEngine.objects.record(for: marker) == nil,
            "Pyramid elevator marker parent route is preserved"
        )

        let fragmentEngine = SM64SwiftEngineState(objectCapacity: 8)
        let fragmentBridge = SM64BehaviorDispatchBridge()
        let fragment = try fragmentBridge.spawnPyramidTopFragment(in: fragmentEngine, scale: 0.8)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64PyramidTopFragmentObjectBridge.defaultBehaviorIdentity) == .pyramidElevator,
            "Pyramid top fragment shares the pyramid dispatch lane"
        )
        _ = fragmentEngine.objects.mutate(fragment) { record in record.timer = 60 }
        let fragmentTick = fragmentBridge.tick(state: fragmentEngine)
        require(
            fragmentTick.pyramidTopFragmentEffects.first { $0.objectID == fragment }?.output.deactivated == true
                && fragmentEngine.objects.record(for: fragment) == nil,
            "Pyramid top fragment retirement route"
        )

        let detectorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let detectorBridge = SM64BehaviorDispatchBridge()
        let detectorParent = try detectorEngine.spawnObject(in: .level, behaviorIdentity: 0x7079_7261_6D69_64)
        let detector = try detectorBridge.spawnPyramidPillarTouchDetector(in: detectorEngine, parent: detectorParent)
        _ = detectorEngine.objects.mutate(detector) { record in record.interactionStatus = 1 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64PyramidPillarTouchDetectorObjectBridge.defaultBehaviorIdentity) == .pyramidElevator,
            "Pyramid pillar detector shares the pyramid dispatch lane"
        )
        let detectorTick = detectorBridge.tick(state: detectorEngine)
        require(
            detectorTick.pyramidPillarTouchDetectorEffects.first { $0.objectID == detector }?.output.parentTouchedCount == 1
                && detectorEngine.objects.record(for: detector) == nil
                && detectorEngine.objects.record(for: detectorParent)?.behaviorParams == 1,
            "Pyramid pillar touch detector collision/deactivation route"
        )

        let pyramidTopEngine = SM64SwiftEngineState(objectCapacity: 8)
        let pyramidTopBridge = SM64BehaviorDispatchBridge()
        let pyramidTop = try pyramidTopBridge.spawnPyramidTop(in: pyramidTopEngine)
        _ = pyramidTopEngine.objects.mutate(pyramidTop) { record in record.behaviorParams = 4 }
        require(SM64BehaviorDispatchBridge.route(for: SM64PyramidTopObjectBridge.defaultBehaviorIdentity) == .pyramidElevator, "Pyramid top identity route")
        let pyramidTopTick = pyramidTopBridge.tick(state: pyramidTopEngine)
        require(
            pyramidTopTick.pyramidTopEffects.first { $0.objectID == pyramidTop }?.output.action == 1
                && pyramidTopTick.pyramidTopEffects.first { $0.objectID == pyramidTop }?.output.playPuzzleJingle == true,
            "Pyramid top solved transition route"
        )

        let pitBlockEngine = SM64SwiftEngineState(objectCapacity: 8)
        let pitBlockBridge = SM64BehaviorDispatchBridge()
        let pitBlock = try pitBlockBridge.spawnTTCPitBlock(
            in: pitBlockEngine,
            positionY: 0,
            behaviorByte: 0,
            speedSetting: 0,
            randomWaitTime: 70
        )
        _ = pitBlockEngine.objects.mutate(pitBlock) { record in
            record.timer = 21
            record.position.y = 325
            record.velocity.y = 11
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TTCPitBlockObjectBridge.defaultBehaviorIdentity) == .ttcPitBlock,
            "TTC pit-block identity route"
        )
        let pitBlockTick = pitBlockBridge.tick(state: pitBlockEngine)
        require(
            pitBlockTick.events.map(\.route) == [.ttcPitBlock]
                && pitBlockTick.ttcPitBlockEffects.count == 1
                && pitBlockTick.ttcPitBlockEffects[0].output.clampedAtEndpoint
                && pitBlockTick.ttcPitBlockEffects[0].output.direction == 1
                && pitBlockTick.ttcPitBlockEffects[0].output.waitTime == 30
                && pitBlockEngine.objects.record(for: pitBlock)?.position.y == 330
                && pitBlockEngine.objects.record(for: pitBlock)?.timer == 0,
            "TTC pit-block value/owner route is preserved"
        )

        let checkeredEngine = SM64SwiftEngineState(objectCapacity: 8)
        let checkeredBridge = SM64BehaviorDispatchBridge()
        let checkered = try checkeredBridge.spawnStaticCheckeredPlatform(
            in: checkeredEngine,
            mode: 3,
            debugVelocityPitch: 7,
            debugVelocityYaw: -8,
            debugVelocityRoll: 9
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64StaticCheckeredPlatformObjectBridge.defaultBehaviorIdentity) == .staticCheckeredPlatform,
            "Static checkered platform identity route"
        )
        let checkeredTick = checkeredBridge.tick(state: checkeredEngine)
        require(
            checkeredTick.events.map(\.route) == [.staticCheckeredPlatform]
                && checkeredTick.staticCheckeredPlatformEffects.count == 1
                && checkeredTick.staticCheckeredPlatformEffects[0].output.facePitch == 7
                && checkeredTick.staticCheckeredPlatformEffects[0].output.faceYaw == -8
                && checkeredTick.staticCheckeredPlatformEffects[0].output.faceRoll == 9
                && checkeredEngine.objects.record(for: checkered)?.faceAngles.yaw == -8,
            "Static checkered platform value/owner route is preserved"
        )

        let bbhTrapEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bbhTrapBridge = SM64BehaviorDispatchBridge()
        let bbhTrap = try bbhTrapBridge.spawnBBHTiltingTrapPlatform(
            in: bbhTrapEngine,
            facePitch: 100
        )
        _ = bbhTrapEngine.objects.mutate(bbhTrap) { record in
            record.platform = bbhTrap
            record.distanceToMario = 500
            record.angleToMario = 0
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BBHTiltingTrapPlatformObjectBridge.defaultBehaviorIdentity) == .bbhTiltingTrapPlatform,
            "BBH tilting trap identity route"
        )
        let bbhTrapTick = bbhTrapBridge.tick(state: bbhTrapEngine)
        require(
            bbhTrapTick.events.map(\.route) == [.bbhTiltingTrapPlatform]
                && bbhTrapTick.bbhTiltingTrapPlatformEffects.count == 1
                && bbhTrapTick.bbhTiltingTrapPlatformEffects[0].output.action == 0
                && bbhTrapTick.bbhTiltingTrapPlatformEffects[0].output.facePitch == 600
                && bbhTrapTick.bbhTiltingTrapPlatformEffects[0].output.angleVelocityPitch == 500
                && bbhTrapEngine.objects.record(for: bbhTrap)?.faceAngles.pitch == 600,
            "BBH tilting trap value/owner route is preserved"
        )

        let lllEngine = SM64SwiftEngineState(objectCapacity: 8)
        let lllBridge = SM64BehaviorDispatchBridge()
        let lllRectangular = try lllBridge.spawnLLLSinkingPlatform(
            in: lllEngine,
            rectangularMode: true,
            positionY: 100
        )
        _ = lllBridge.lllSinkingPlatform.attach(
            lllRectangular,
            rectangularMode: true,
            positionY: 100,
            oscillationTimer: 0x4000,
            in: lllEngine.objects
        )
        _ = lllEngine.objects.mutate(lllRectangular) { record in record.action = 1 }
        let lllSquare = try lllBridge.spawnLLLSinkingPlatform(
            in: lllEngine,
            rectangularMode: false,
            positionY: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LLLSinkingPlatformObjectBridge.rectangularBehaviorIdentity) == .lllSinkingPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64LLLSinkingPlatformObjectBridge.squareBehaviorIdentity) == .lllSinkingPlatform,
            "LLL sinking platform identities share route"
        )
        let lllTick = lllBridge.tick(state: lllEngine)
        require(
            lllTick.events.map(\.route) == [.lllSinkingPlatform, .lllSinkingPlatform]
                && lllTick.lllSinkingPlatformEffects.count == 2
                && lllTick.lllSinkingPlatformEffects[0].output.positionY == 99.6
                && lllTick.lllSinkingPlatformEffects[0].output.oscillationTimer == 0x4100
                && lllTick.lllSinkingPlatformEffects[1].output.facePitch == 0
                && lllEngine.objects.record(for: lllRectangular)?.position.y == 99.6
                && lllEngine.objects.record(for: lllSquare)?.faceAngles.pitch == 0,
            "LLL rectangular/square sinking routes are preserved"
        )

        let wfWoodEngine = SM64SwiftEngineState(objectCapacity: 8)
        let wfWoodBridge = SM64BehaviorDispatchBridge()
        let wfWood = try wfWoodBridge.spawnWfRotatingWoodenPlatform(
            in: wfWoodEngine,
            faceYaw: 100
        )
        _ = wfWoodEngine.objects.mutate(wfWood) { record in record.timer = 61 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WfRotatingWoodenPlatformObjectBridge.defaultBehaviorIdentity) == .wfRotatingWoodenPlatform,
            "WF rotating wooden platform identity route"
        )
        let wfStartTick = wfWoodBridge.tick(state: wfWoodEngine)
        let wfSpinTick = wfWoodBridge.tick(state: wfWoodEngine)
        require(
            wfStartTick.events.map(\.route) == [.wfRotatingWoodenPlatform]
                && wfStartTick.wfRotatingWoodenPlatformEffects.count == 1
                && wfStartTick.wfRotatingWoodenPlatformEffects[0].output.action == 1
                && wfStartTick.wfRotatingWoodenPlatformEffects[0].output.angleVelocityYaw == 0
                && wfSpinTick.events.map(\.route) == [.wfRotatingWoodenPlatform]
                && wfSpinTick.wfRotatingWoodenPlatformEffects[0].output.faceYaw == 356
                && wfSpinTick.wfRotatingWoodenPlatformEffects[0].output.playedSound
                && wfWoodEngine.objects.record(for: wfWood)?.faceAngles.yaw == 356,
            "WF rotating wooden platform value/owner route is preserved"
        )

        let octagonalEngine = SM64SwiftEngineState(objectCapacity: 8)
        let octagonalBridge = SM64BehaviorDispatchBridge()
        let octagonal = try octagonalBridge.spawnRotatingOctagonalPlatform(
            in: octagonalEngine,
            faceYaw: 100,
            collisionModelIndex: 1,
            speedIndex: 3
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RotatingOctagonalPlatformObjectBridge.defaultBehaviorIdentity) == .rotatingOctagonalPlatform,
            "Rotating octagonal platform identity route"
        )
        let octagonalTick = octagonalBridge.tick(state: octagonalEngine)
        require(
            octagonalTick.events.map(\.route) == [.rotatingOctagonalPlatform]
                && octagonalTick.rotatingOctagonalPlatformEffects.count == 1
                && octagonalTick.rotatingOctagonalPlatformEffects[0].output.faceYaw == -500
                && octagonalTick.rotatingOctagonalPlatformEffects[0].output.angleVelocityYaw == -600
                && octagonalEngine.objects.record(for: octagonal)?.faceAngles.yaw == -500,
            "Rotating octagonal platform value/owner route is preserved"
        )

        let towerEngine = SM64SwiftEngineState(objectCapacity: 8)
        let towerBridge = SM64BehaviorDispatchBridge()
        let towerParent = try towerEngine.spawnObject(in: .level, behaviorIdentity: 0x7770_6172_656E_74)
        let towerChild = try towerBridge.spawnWfSolidTowerPlatform(
            in: towerEngine,
            parent: towerParent
        )
        _ = towerEngine.objects.mutate(towerParent) { record in record.action = 3 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WfSolidTowerPlatformObjectBridge.defaultBehaviorIdentity) == .wfSolidTowerPlatform,
            "WF solid tower platform identity route"
        )
        let towerTick = towerBridge.tick(state: towerEngine)
        require(
            towerTick.events.map(\.route) == [.unmigrated, .wfSolidTowerPlatform]
                && towerTick.wfSolidTowerPlatformEffects.count == 1
                && towerTick.wfSolidTowerPlatformEffects[0].parentID == towerParent
                && towerTick.wfSolidTowerPlatformEffects[0].output.shouldDelete
                && towerEngine.objects.record(for: towerChild) == nil,
            "WF solid tower parent-child deletion route is preserved"
        )

        let towerFamilyEngine = SM64SwiftEngineState(objectCapacity: 12)
        let towerFamilyBridge = SM64BehaviorDispatchBridge()
        let towerFamilyParent = try towerFamilyEngine.spawnObject(
            in: .level,
            behaviorIdentity: 0x7770_6172_656E_74
        )
        let elevatorChild = try towerFamilyBridge.spawnWfElevatorTowerPlatform(
            in: towerFamilyEngine,
            parent: towerFamilyParent,
            position: .zero
        )
        let slidingChild = try towerFamilyBridge.spawnWfSlidingTowerPlatform(
            in: towerFamilyEngine,
            parent: towerFamilyParent,
            position: .zero,
            moveYaw: 0
        )
        _ = towerFamilyEngine.objects.mutate(elevatorChild) { record in record.platform = elevatorChild }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WfTowerPlatformObjectBridge.elevatorBehaviorIdentity) == .wfTowerPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64WfTowerPlatformObjectBridge.slidingBehaviorIdentity) == .wfTowerPlatform,
            "WF elevator/sliding tower identities share route"
        )
        let towerFamilyTick = towerFamilyBridge.tick(state: towerFamilyEngine)
        _ = towerFamilyEngine.objects.mutate(towerFamilyParent) { record in record.action = 3 }
        let towerFamilyDeleteTick = towerFamilyBridge.tick(state: towerFamilyEngine)
        require(
            towerFamilyTick.events.map(\.route) == [.unmigrated, .wfTowerPlatform, .wfTowerPlatform]
                && towerFamilyTick.wfTowerPlatformEffects.count == 2
                && towerFamilyTick.wfTowerPlatformEffects[0].kind == .elevator
                && towerFamilyTick.wfTowerPlatformEffects[0].output.action == 1
                && towerFamilyTick.wfTowerPlatformEffects[1].kind == .sliding
                && towerFamilyTick.wfTowerPlatformEffects[1].output.forwardVelocity == -3
                && towerFamilyDeleteTick.wfTowerPlatformEffects.count == 2
                && towerFamilyDeleteTick.wfTowerPlatformEffects.allSatisfy { $0.output.shouldDelete }
                && towerFamilyEngine.objects.record(for: elevatorChild) == nil
                && towerFamilyEngine.objects.record(for: slidingChild) == nil,
            "WF elevator/sliding tower parent-child routes are preserved"
        )

        let trackBallEngine = SM64SwiftEngineState(objectCapacity: 12)
        let trackBallBridge = SM64BehaviorDispatchBridge()
        let trackBallParent = try trackBallEngine.spawnObject(in: .level, behaviorIdentity: 0x7770_6172_656E_74)
        let activeTrackBall = try trackBallBridge.spawnTrackBall(
            in: trackBallEngine,
            parent: trackBallParent,
            behaviorByte: 6,
            parentBaseBallIndex: 0
        )
        let staleTrackBall = try trackBallBridge.spawnTrackBall(
            in: trackBallEngine,
            parent: trackBallParent,
            behaviorByte: 1,
            parentBaseBallIndex: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TrackBallObjectBridge.defaultBehaviorIdentity) == .wfTowerPlatform,
            "track-ball identity shares the platform dispatch lane"
        )
        let trackBallTick = trackBallBridge.tick(state: trackBallEngine)
        let activeTrackBallEffect = trackBallTick.trackBallEffects.first { $0.objectID == activeTrackBall }
        let staleTrackBallEffect = trackBallTick.trackBallEffects.first { $0.objectID == staleTrackBall }
        require(
            activeTrackBallEffect?.output.relativeIndex == 5
                && activeTrackBallEffect?.output.shouldDelete == false
                && staleTrackBallEffect?.output.relativeIndex == 0
                && staleTrackBallEffect?.output.shouldDelete == true
                && trackBallEngine.objects.record(for: activeTrackBall) != nil
                && trackBallEngine.objects.record(for: staleTrackBall) == nil,
            "track-ball parent-index lifetime route is preserved"
        )

        let wfSlidingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let wfSlidingBridge = SM64BehaviorDispatchBridge()
        let wfSliding = try wfSlidingBridge.spawnWfSlidingPlatform(
            in: wfSlidingEngine,
            faceYaw: 0x8000,
            moveYaw: 0x4000,
            behaviorByte: 1,
            initialTimer: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WfSlidingPlatformObjectBridge.defaultBehaviorIdentity) == .wfSlidingPlatform,
            "WF sliding platform identity route"
        )
        _ = wfSlidingBridge.tick(state: wfSlidingEngine)
        let wfSlidingStartTick = wfSlidingBridge.tick(state: wfSlidingEngine)
        _ = wfSlidingEngine.objects.mutate(wfSliding) { record in
            record.timer = 50
            record.position.x = 12
            record.forwardVelocity = 10
        }
        let wfSlidingEndTick = wfSlidingBridge.tick(state: wfSlidingEngine)
        require(
            wfSlidingStartTick.events.map(\.route) == [.wfSlidingPlatform]
                && wfSlidingStartTick.wfSlidingPlatformEffects.count == 1
                && wfSlidingStartTick.wfSlidingPlatformEffects[0].output.action == 1
                && wfSlidingStartTick.wfSlidingPlatformEffects[0].output.positionX == 12
                && wfSlidingEndTick.wfSlidingPlatformEffects.count == 1
                && wfSlidingEndTick.wfSlidingPlatformEffects[0].output.positionX == 512
                && wfSlidingEndTick.wfSlidingPlatformEffects[0].output.forwardVelocity == 0
                && wfSlidingEngine.objects.record(for: wfSliding)?.position.x == 512,
            "WF sliding platform value/owner route is preserved"
        )

        let wdwEngine = SM64SwiftEngineState(objectCapacity: 8)
        let wdwBridge = SM64BehaviorDispatchBridge()
        let wdwElevator = try wdwBridge.spawnWdwExpressElevator(in: wdwEngine, positionY: 500)
        let wdwStatic = try wdwBridge.spawnWdwExpressElevatorPlatform(in: wdwEngine, positionY: 100)
        _ = wdwEngine.objects.mutate(wdwElevator) { record in record.platform = wdwElevator }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WdwExpressElevatorObjectBridge.elevatorBehaviorIdentity) == .wdwExpressElevator
                && SM64BehaviorDispatchBridge.route(for: SM64WdwExpressElevatorObjectBridge.staticPlatformBehaviorIdentity) == .wdwExpressElevator,
            "WDW express elevator identities share route"
        )
        let wdwStartTick = wdwBridge.tick(state: wdwEngine)
        let wdwDownTick = wdwBridge.tick(state: wdwEngine)
        require(
            wdwStartTick.events.map(\.route) == [.wdwExpressElevator, .wdwExpressElevator]
                && wdwStartTick.wdwExpressElevatorEffects.count == 2
                && wdwStartTick.wdwExpressElevatorEffects[0].output.action == 1
                && wdwStartTick.wdwExpressElevatorEffects[1].kind == .staticPlatform
                && wdwDownTick.wdwExpressElevatorEffects[0].output.positionY == 480
                && wdwDownTick.wdwExpressElevatorEffects[0].output.playedSound
                && wdwEngine.objects.record(for: wdwStatic)?.position.y == 100,
            "WDW express elevator/static platform route is preserved"
        )

        let rockEngine = SM64SwiftEngineState(objectCapacity: 8)
        let rockBridge = SM64BehaviorDispatchBridge()
        let rock = try rockBridge.spawnLllSinkingRockBlock(
            in: rockEngine,
            position: SM64ObjectVector3(x: 0, y: 100, z: 0)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LllSinkingRockBlockObjectBridge.defaultBehaviorIdentity) == .lllSinkingRockBlock,
            "LLL sinking rock block identity route"
        )
        let rockIdleTick = rockBridge.tick(state: rockEngine)
        _ = rockEngine.objects.setPlatform(rock, platform: rock)
        let rockSinkTick = rockBridge.tick(state: rockEngine)
        require(
            rockIdleTick.events.map(\.route) == [.lllSinkingRockBlock]
                && rockIdleTick.lllSinkingRockBlockEffects.count == 1
                && rockIdleTick.lllSinkingRockBlockEffects[0].output.positionY == 100
                && rockSinkTick.lllSinkingRockBlockEffects.count == 1
                && rockSinkTick.lllSinkingRockBlockEffects[0].output.oscillationAngle == 124
                && (rockEngine.objects.record(for: rock)?.position.y ?? 100) < 100,
            "LLL sinking rock block value/owner route is preserved"
        )

        let volcanoTrapEngine = SM64SwiftEngineState(objectCapacity: 8)
        let volcanoTrapBridge = SM64BehaviorDispatchBridge()
        let volcanoTrap = try volcanoTrapBridge.spawnVolcanoFallingTrap(
            in: volcanoTrapEngine,
            position: SM64ObjectVector3(x: 0, y: 100, z: 0)
        )
        _ = volcanoTrapEngine.objects.mutate(volcanoTrap) { record in record.distanceToMario = 900 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64VolcanoFallingTrapObjectBridge.defaultBehaviorIdentity) == .lllSinkingRockBlock,
            "volcano falling trap shares the LLL trap dispatch lane"
        )
        let volcanoTrapTick = volcanoTrapBridge.tick(state: volcanoTrapEngine)
        require(
            volcanoTrapTick.volcanoFallingTrapEffects.count == 1
                && volcanoTrapTick.volcanoFallingTrapEffects[0].output.action == 1
                && volcanoTrapTick.volcanoFallingTrapEffects[0].output.playQuietPound,
            "volcano falling trap trigger route is preserved"
        )

        let rollingLogEngine = SM64SwiftEngineState(objectCapacity: 12)
        let rollingLogBridge = SM64BehaviorDispatchBridge()
        let ttmLog = try rollingLogBridge.spawnRollingLog(
            in: rollingLogEngine,
            variant: .ttm,
            position: SM64ObjectVector3(x: 3_970, y: 0, z: 3_654)
        )
        let lllLog = try rollingLogBridge.spawnRollingLog(
            in: rollingLogEngine,
            variant: .lll,
            position: SM64ObjectVector3(x: 5_120, y: 0, z: 6_016)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RollingLogObjectBridge.ttmBehaviorIdentity) == .lllSinkingRockBlock
                && SM64BehaviorDispatchBridge.route(for: SM64RollingLogObjectBridge.lllBehaviorIdentity) == .lllSinkingRockBlock,
            "TTM/LLL rolling-log identities share the trap dispatch lane"
        )
        let rollingLogTick = rollingLogBridge.tick(state: rollingLogEngine)
        require(
            rollingLogTick.rollingLogEffects.count == 2
                && rollingLogTick.rollingLogEffects.allSatisfy { !$0.output.hitBoundary }
                && rollingLogEngine.objects.record(for: ttmLog)?.position.z == 3_654
                && rollingLogEngine.objects.record(for: lllLog)?.position.z == 6_016,
            "TTM/LLL rolling-log owner route is preserved"
        )

        let meshEngine = SM64SwiftEngineState(objectCapacity: 8)
        let meshBridge = SM64BehaviorDispatchBridge()
        let mesh = try meshBridge.spawnLllMovingOctagonalMesh(
            in: meshEngine,
            position: SM64ObjectVector3(x: 0, y: 100, z: 0),
            mode: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LllMovingOctagonalMeshObjectBridge.defaultBehaviorIdentity) == .lllMovingOctagonalMesh,
            "LLL moving octagonal mesh identity route"
        )
        let meshStartTick = meshBridge.tick(state: meshEngine)
        let meshWaitTick = meshBridge.tick(state: meshEngine)
        require(
            meshStartTick.events.map(\.route) == [.lllMovingOctagonalMesh]
                && meshStartTick.lllMovingOctagonalMeshEffects.count == 1
                && meshStartTick.lllMovingOctagonalMeshEffects[0].output.action == 1
                && meshStartTick.lllMovingOctagonalMeshEffects[0].output.positionY < 100
                && meshWaitTick.lllMovingOctagonalMeshEffects[0].output.sequenceIndex == 0
                && meshWaitTick.lllMovingOctagonalMeshEffects[0].output.moveYaw == 0x4000
                && (meshEngine.objects.record(for: mesh)?.position.y ?? 100) < 100,
            "LLL moving octagonal mesh value/owner route is preserved"
        )

        let ferrisEngine = SM64SwiftEngineState(objectCapacity: 12)
        let ferrisBridge = SM64BehaviorDispatchBridge()
        let ferrisAxle = try ferrisBridge.spawnFerrisWheel(
            in: ferrisEngine,
            position: .zero
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FerrisWheelPlatformObjectBridge.axleBehaviorIdentity) == .ferrisWheel
                && SM64BehaviorDispatchBridge.route(for: SM64FerrisWheelPlatformObjectBridge.platformBehaviorIdentity) == .ferrisWheel,
            "Ferris wheel identities share route"
        )
        let ferrisTick = ferrisBridge.tick(state: ferrisEngine)
        require(
            ferrisTick.events.map(\.route) == Array(repeating: .ferrisWheel, count: 5)
                && ferrisTick.ferrisWheelEffects.count == 4
                && ferrisTick.ferrisWheelEffects.map(\.platformIndex) == [0, 1, 2, 3]
                && ferrisTick.ferrisWheelEffects[0].parentID == ferrisAxle
                && ferrisTick.ferrisWheelEffects[0].output.position == .init(x: 300, y: 0, z: 400),
            "Ferris wheel parent-relative platform route is preserved"
        )

        let checkerEngine = SM64SwiftEngineState(objectCapacity: 12)
        let checkerBridge = SM64BehaviorDispatchBridge()
        let checkerGroup = try checkerBridge.spawnCheckerboardGroup(
            in: checkerEngine,
            position: .zero,
            variant: 0,
            waitTime: 65
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CheckerboardPlatformObjectBridge.groupBehaviorIdentity) == .checkerboardPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64CheckerboardPlatformObjectBridge.childBehaviorIdentity) == .checkerboardPlatform,
            "Checkerboard group/child identities share route"
        )
        let checkerTick = checkerBridge.tick(state: checkerEngine)
        require(
            checkerTick.events.map(\.route) == Array(repeating: .checkerboardPlatform, count: 3)
                && checkerTick.checkerboardPlatformEffects.count == 2
                && checkerTick.checkerboardPlatformEffects[0].parentID == checkerGroup
                && checkerTick.checkerboardPlatformEffects[0].output.action == 1
                && checkerTick.checkerboardPlatformEffects[1].output.action == 3
                && checkerEngine.objects.record(for: checkerGroup) == nil,
            "Checkerboard group/child owner route is preserved"
        )

        let towerGroupEngine = SM64SwiftEngineState(objectCapacity: 24)
        let towerGroupBridge = SM64BehaviorDispatchBridge()
        let mario = try towerGroupEngine.spawnObject(in: .generalActor, isMario: true)
        _ = towerGroupEngine.objects.mutate(mario) { record in record.position.y = 0 }
        let towerGroup = try towerGroupBridge.spawnWfTowerPlatformGroup(
            in: towerGroupEngine,
            position: .zero
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WfTowerPlatformGroupObjectBridge.defaultBehaviorIdentity) == .wfTowerPlatformGroup,
            "WF tower platform group identity route"
        )
        _ = towerGroupBridge.tick(state: towerGroupEngine)
        let towerGroupSpawnTick = towerGroupBridge.tick(state: towerGroupEngine)
        require(
            towerGroupSpawnTick.wfTowerPlatformGroupEffects.count == 1
                && towerGroupSpawnTick.wfTowerPlatformGroupEffects[0].objectID == towerGroup
                && towerGroupSpawnTick.wfTowerPlatformGroupEffects[0].output.spawnChildren
                && towerGroupSpawnTick.wfTowerPlatformGroupEffects[0].spawnedChildren.count == 7
                && towerGroupEngine.objects.record(for: towerGroup) == nil
                && towerGroupSpawnTick.wfSolidTowerPlatformEffects.count == 3
                && towerGroupSpawnTick.wfTowerPlatformEffects.count == 4,
            "WF tower platform group child allocation route is preserved"
        )

        let hexEngine = SM64SwiftEngineState(objectCapacity: 8)
        let hexBridge = SM64BehaviorDispatchBridge()
        let hex = try hexBridge.spawnLllRotatingHexagonalPlatform(
            in: hexEngine,
            moveYaw: 0x7fff
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LllRotatingHexagonalPlatformObjectBridge.defaultBehaviorIdentity) == .lllRotatingHexagonalPlatform,
            "LLL rotating hexagonal platform identity route"
        )
        let hexTick = hexBridge.tick(state: hexEngine)
        require(
            hexTick.events.map(\.route) == [.lllRotatingHexagonalPlatform]
                && hexTick.lllRotatingHexagonalPlatformEffects.count == 1
                && hexTick.lllRotatingHexagonalPlatformEffects[0].output.moveYaw == 0x80ff
                && hexEngine.objects.record(for: hex)?.faceAngles.yaw == 0x80ff,
            "LLL rotating hexagonal platform value/owner route is preserved"
        )

        let flameEngine = SM64SwiftEngineState(objectCapacity: 8)
        let flameBridge = SM64BehaviorDispatchBridge()
        let flameParent = try flameEngine.spawnObject(in: .level, behaviorIdentity: 0x666C_7061_72656E_74)
        _ = flameEngine.objects.mutate(flameParent) { record in
            record.position = .init(x: 100, y: 200, z: 300)
            record.moveAngles.yaw = 0
        }
        let flame = try flameBridge.spawnLllRotatingHexFlame(
            in: flameEngine,
            parent: flameParent,
            leftOffset: 200,
            forwardOffset: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LllRotatingHexFlameObjectBridge.defaultBehaviorIdentity) == .lllRotatingHexFlame,
            "LLL rotating hex flame identity route"
        )
        let flameTick = flameBridge.tick(state: flameEngine)
        _ = flameEngine.objects.mutate(flameParent) { record in record.action = 3 }
        let flameDeleteTick = flameBridge.tick(state: flameEngine)
        require(
            flameTick.events.map(\.route) == [.unmigrated, .lllRotatingHexFlame]
                && flameTick.lllRotatingHexFlameEffects.count == 1
                && flameTick.lllRotatingHexFlameEffects[0].output.position == .init(x: 300, y: 300, z: 300)
                && flameDeleteTick.lllRotatingHexFlameEffects[0].output.shouldDelete
                && flameEngine.objects.record(for: flame) == nil,
            "LLL rotating hex flame parent-child route is preserved"
        )

        let fireBarEngine = SM64SwiftEngineState(objectCapacity: 24)
        let fireBarBridge = SM64BehaviorDispatchBridge()
        let fireBar = try fireBarBridge.spawnLllRotatingFireBar(
            in: fireBarEngine,
            behaviorByte: 0
        )
        _ = fireBarEngine.objects.mutate(fireBar) { record in record.distanceToMario = 2000 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LllRotatingFireBarObjectBridge.defaultBehaviorIdentity) == .lllRotatingFireBar,
            "LLL rotating fire-bar identity route"
        )
        _ = fireBarBridge.tick(state: fireBarEngine)
        let fireBarSpawnTick = fireBarBridge.tick(state: fireBarEngine)
        _ = fireBarEngine.objects.mutate(fireBar) { record in record.distanceToMario = 3301 }
        let fireBarLeaveTick = fireBarBridge.tick(state: fireBarEngine)
        require(
            fireBarSpawnTick.lllRotatingFireBarEffects.count == 1
                && fireBarSpawnTick.lllRotatingFireBarEffects[0].output.spawnFlames
                && fireBarSpawnTick.lllRotatingFireBarEffects[0].spawnedFlames.count == 8
                && fireBarSpawnTick.lllRotatingHexFlameEffects.count == 8
                && fireBarLeaveTick.lllRotatingFireBarEffects[0].output.action == 3
                && fireBarLeaveTick.lllRotatingHexFlameEffects.allSatisfy { $0.output.shouldDelete },
            "LLL rotating fire-bar parent/flame route is preserved"
        )

        let activatedEngine = SM64SwiftEngineState(objectCapacity: 8)
        let activatedBridge = SM64BehaviorDispatchBridge()
        let activated = try activatedBridge.spawnActivatedBackAndForthPlatform(
            in: activatedEngine,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            behaviorByte: 0x80
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ActivatedBackAndForthPlatformObjectBridge.defaultBehaviorIdentity) == .activatedBackAndForthPlatform,
            "Activated back-and-forth platform identity route"
        )
        _ = activatedBridge.tick(state: activatedEngine)
        _ = activatedEngine.objects.setPlatform(activated, platform: activated)
        let activatedTick = activatedBridge.tick(state: activatedEngine)
        require(
            activatedTick.events.map(\.route) == [.activatedBackAndForthPlatform]
                && activatedTick.activatedBackAndForthPlatformEffects.count == 1
                && activatedTick.activatedBackAndForthPlatformEffects[0].output.platformVelocity == 10
                && activatedEngine.objects.record(for: activated)?.position.y == 200,
            "Activated back-and-forth platform value/owner route is preserved"
        )

        let bitfsEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bitfsBridge = SM64BehaviorDispatchBridge()
        let bitfsPlatform = try bitfsBridge.spawnBitfsSinkingPlatform(in: bitfsEngine, positionY: 100)
        let bitfsCage = try bitfsBridge.spawnBitfsSinkingCage(in: bitfsEngine, positionY: 100, cageParameter: 1)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BitfsSinkingPlatformObjectBridge.platformBehaviorIdentity) == .bitfsSinkingPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64BitfsSinkingPlatformObjectBridge.cageBehaviorIdentity) == .bitfsSinkingPlatform,
            "BITFS sinking platform identities share route"
        )
        let bitfsTick = bitfsBridge.tick(state: bitfsEngine)
        require(
            bitfsTick.events.map(\.route) == [.dddMovingPole, .bitfsSinkingPlatform, .bitfsSinkingPlatform]
                && bitfsTick.bitfsSinkingPlatformEffects.count == 2
                && bitfsTick.dddMovingPoleEffects.count == 1
                && bitfsTick.dddMovingPoleEffects[0].parentID == bitfsCage
                && bitfsTick.bitfsSinkingPlatformEffects[0].output.positionY == 100
                && bitfsTick.bitfsSinkingPlatformEffects[1].output.positionY == -200
                && bitfsEngine.objects.record(for: bitfsPlatform)?.position.y == 100
                && bitfsEngine.objects.record(for: bitfsCage)?.position.y == -200,
            "BITFS sinking platform/cage route is preserved"
        )

        let ringEngine = SM64SwiftEngineState(objectCapacity: 8)
        let ringBridge = SM64BehaviorDispatchBridge()
        let ring = try ringBridge.spawnLllRotatingHexagonalRing(in: ringEngine)
        _ = ringEngine.objects.setPlatform(ring, platform: ring)
        _ = ringBridge.tick(state: ringEngine)
        _ = ringEngine.objects.mutate(ring) { record in record.action = 2; record.timer = 0 }
        let ringTick = ringBridge.tick(state: ringEngine)
        require(
            ringTick.events.map(\.route) == [.lllRotatingHexagonalRing, .volcanoFlames]
                && ringTick.lllRotatingHexagonalRingEffects.count == 1
                && ringTick.lllRotatingHexagonalRingEffects[0].output.spawnVolcanoFlame
                && ringTick.lllRotatingHexagonalRingEffects[0].spawnedFlame != nil,
            "LLL rotating hexagonal ring route is preserved"
        )

        let woodEngine = SM64SwiftEngineState(objectCapacity: 12)
        let woodBridge = SM64BehaviorDispatchBridge()
        let wood = try woodBridge.spawnLllFloatingWoodBridge(in: woodEngine)
        _ = woodEngine.objects.mutate(wood) { record in record.distanceToMario = 2000 }
        let woodSpawnTick = woodBridge.tick(state: woodEngine)
        require(
            woodSpawnTick.lllFloatingWoodBridgeEffects.count == 1
                && woodSpawnTick.lllFloatingWoodBridgeEffects[0].spawnedChildren.count == 3,
            "LLL floating wood bridge child allocation"
        )
        _ = woodBridge.tick(state: woodEngine)
        _ = woodEngine.objects.mutate(wood) { record in record.distanceToMario = 2700 }
        _ = woodBridge.tick(state: woodEngine)
        let woodDeleteTick = woodBridge.tick(state: woodEngine)
        require(
            woodDeleteTick.lllWoodPieceEffects.count == 3
                && woodDeleteTick.lllWoodPieceEffects.allSatisfy { $0.output.shouldDelete },
            "LLL floating wood piece parent-delete route"
        )

        let squashEngine = SM64SwiftEngineState(objectCapacity: 8)
        let squashBridge = SM64BehaviorDispatchBridge()
        let squash = try squashBridge.spawnSquishablePlatform(
            in: squashEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SquishablePlatformObjectBridge.defaultBehaviorIdentity) == .squishablePlatform,
            "squishable platform identity route"
        )
        let squashTick = squashBridge.tick(state: squashEngine)
        require(
            squashTick.events.map(\.route) == [.squishablePlatform]
                && squashTick.squishablePlatformEffects.count == 1
                && abs(squashTick.squishablePlatformEffects[0].output.scaleY - 0.7) < 0.001
                && abs((squashEngine.objects.record(for: squash)?.scale.y ?? 0) - 0.7) < 0.001,
            "squishable platform scale route is preserved"
        )

        let drawbridgeEngine = SM64SwiftEngineState(objectCapacity: 8)
        let drawbridgeBridge = SM64BehaviorDispatchBridge()
        let drawbridgeSpawner = try drawbridgeBridge.spawnLllDrawbridgeSpawner(
            in: drawbridgeEngine,
            position: .zero,
            moveYaw: 0x4000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64LllDrawbridgeObjectBridge.spawnerBehaviorIdentity) == .lllDrawbridge
                && SM64BehaviorDispatchBridge.route(for: SM64LllDrawbridgeObjectBridge.drawbridgeBehaviorIdentity) == .lllDrawbridge,
            "LLL drawbridge identities share route"
        )
        let drawbridgeTick = drawbridgeBridge.tick(state: drawbridgeEngine)
        let drawbridgeChildTick = drawbridgeBridge.tick(state: drawbridgeEngine)
        require(
            drawbridgeTick.events.map(\.route) == [.lllDrawbridge]
                && drawbridgeTick.lllDrawbridgeSpawnerEffects.count == 1
                && drawbridgeTick.lllDrawbridgeSpawnerEffects[0].objectID == drawbridgeSpawner
                && drawbridgeTick.lllDrawbridgeSpawnerEffects[0].spawnedChildren.count == 2
                && drawbridgeChildTick.events.map(\.route) == [.lllDrawbridge, .lllDrawbridge]
                && drawbridgeChildTick.lllDrawbridgeEffects.count == 2
                && drawbridgeChildTick.lllDrawbridgeEffects.allSatisfy { $0.output.faceRoll == 0 }
                && drawbridgeEngine.objects.record(for: drawbridgeSpawner) == nil,
            "LLL drawbridge parent/child route is preserved"
        )

        let waveEngine = SM64SwiftEngineState(objectCapacity: 8)
        let waveBridge = SM64BehaviorDispatchBridge()
        let waveMario = try waveEngine.spawnObject(in: .player, isMario: true)
        _ = waveEngine.objects.mutate(waveMario) { record in
            record.position = SM64ObjectVector3(x: 10, y: 20, z: 30)
            record.activeParticleFlags = 0x80
        }
        let wave = try waveBridge.spawnIdleWaterWave(in: waveEngine, waterLevel: 100)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64IdleWaterWaveObjectBridge.defaultBehaviorIdentity) == .idleWaterWave,
            "idle water wave identity route"
        )
        let waveActiveTick = waveBridge.tick(state: waveEngine)
        require(
            waveActiveTick.idleWaterWaveEffects.first?.output.position == .init(x: 10, y: 105, z: 30)
                && !waveActiveTick.idleWaterWaveEffects[0].output.deactivate,
            "idle water wave follows Mario while particle flag is active"
        )
        _ = waveEngine.objects.mutate(waveMario) { record in record.activeParticleFlags = 0 }
        let waveDeleteTick = waveBridge.tick(state: waveEngine)
        require(
            waveDeleteTick.events.contains { $0.route == .idleWaterWave }
                && waveDeleteTick.idleWaterWaveEffects.count == 1
                && waveDeleteTick.idleWaterWaveEffects[0].output.animationState == 2
                && waveDeleteTick.idleWaterWaveEffects[0].output.deactivate
                && waveDeleteTick.idleWaterWaveEffects[0].output.clearMarioFlag
                && waveEngine.objects.record(for: wave) == nil,
            "idle water wave sixteen-frame deactivation route is preserved"
        )

        let objectWaveEngine = SM64SwiftEngineState(objectCapacity: 8)
        let objectWaveBridge = SM64BehaviorDispatchBridge()
        let objectWave = try objectWaveBridge.spawnObjectWaterWave(in: objectWaveEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64IdleWaterWaveObjectBridge.objectWaterWaveBehaviorIdentity) == .idleWaterWave,
            "object water wave identity shares route"
        )
        let objectWaveTick = objectWaveBridge.tick(state: objectWaveEngine)
        require(
            objectWaveTick.events.map(\.route) == [.idleWaterWave]
                && objectWaveTick.idleWaterWaveEffects.count == 1
                && objectWaveTick.idleWaterWaveEffects[0].output.animationState == 1
                && objectWaveEngine.objects.record(for: objectWave) != nil,
            "object water wave shared-loop route is preserved"
        )

        let waterfallEngine = SM64SwiftEngineState(objectCapacity: 8)
        let waterfallBridge = SM64BehaviorDispatchBridge()
        let waterfall = try waterfallBridge.spawnWaterfallSoundLoop(in: waterfallEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterfallSoundLoopObjectBridge.defaultBehaviorIdentity) == .waterfallSoundLoop,
            "waterfall sound loop identity route"
        )
        let waterfallTick = waterfallBridge.tick(state: waterfallEngine)
        require(
            waterfallTick.events.map(\.route) == [.waterfallSoundLoop]
                && waterfallTick.waterfallSoundLoopEffects.count == 1
                && waterfallTick.waterfallSoundLoopEffects[0].objectID == waterfall
                && waterfallTick.waterfallSoundLoopEffects[0].output.playWaterfallSound,
            "waterfall sound loop route is preserved"
        )

        let volcanoEngine = SM64SwiftEngineState(objectCapacity: 8)
        let volcanoBridge = SM64BehaviorDispatchBridge()
        let volcano = try volcanoBridge.spawnVolcanoSoundLoop(in: volcanoEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64VolcanoSoundLoopObjectBridge.defaultBehaviorIdentity) == .volcanoSoundLoop,
            "volcano sound loop identity route"
        )
        let volcanoTick = volcanoBridge.tick(state: volcanoEngine)
        require(
            volcanoTick.events.map(\.route) == [.volcanoSoundLoop]
                && volcanoTick.volcanoSoundLoopEffects.count == 1
                && volcanoTick.volcanoSoundLoopEffects[0].objectID == volcano
                && volcanoTick.volcanoSoundLoopEffects[0].output.playVolcanoSound,
            "volcano sound loop route is preserved"
        )

        let tumblingEngine = SM64SwiftEngineState(objectCapacity: 32)
        let tumblingBridge = SM64BehaviorDispatchBridge()
        let tumblingParent = try tumblingBridge.spawnTumblingBridge(
            in: tumblingEngine,
            variant: .wf,
            distanceToMario: 900
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TumblingBridgeObjectBridge.wfBehaviorIdentity) == .tumblingBridge
                && SM64BehaviorDispatchBridge.route(for: SM64TumblingBridgeObjectBridge.bbhBehaviorIdentity) == .tumblingBridge
                && SM64BehaviorDispatchBridge.route(for: SM64TumblingBridgeObjectBridge.lllBehaviorIdentity) == .tumblingBridge
                && SM64BehaviorDispatchBridge.route(for: SM64TumblingBridgeObjectBridge.platformBehaviorIdentity) == .tumblingBridge,
            "tumbling bridge identities share route"
        )
        _ = tumblingBridge.tick(state: tumblingEngine)
        let tumblingSpawnTick = tumblingBridge.tick(state: tumblingEngine)
        let tumblingChildren = tumblingSpawnTick.tumblingBridgeParentEffects[0].spawnedChildren
        require(
            tumblingSpawnTick.events.count == 10
                && tumblingSpawnTick.tumblingBridgeParentEffects.count == 1
                && tumblingSpawnTick.tumblingBridgeParentEffects[0].objectID == tumblingParent
                && tumblingChildren.count == 9
                && tumblingSpawnTick.tumblingBridgePlatformEffects.count == 9,
            "tumbling bridge parent allocates nine source-order platforms"
        )
        _ = tumblingEngine.objects.setPlatform(tumblingChildren[0], platform: tumblingChildren[0])
        let tumblingActiveTick = tumblingBridge.tick(state: tumblingEngine)
        require(
            tumblingActiveTick.tumblingBridgePlatformEffects.first?.output.action == 1
                && tumblingActiveTick.tumblingBridgeParentEffects.first?.output.visible == false,
            "tumbling bridge activation and distance hiding route is preserved"
        )
        _ = tumblingEngine.objects.mutate(tumblingParent) { record in record.distanceToMario = 1300 }
        let tumblingDeleteTick = tumblingBridge.tick(state: tumblingEngine)
        require(
            tumblingDeleteTick.tumblingBridgeParentEffects.first?.output.action == 3
                && tumblingDeleteTick.tumblingBridgeParentEffects.first?.output.visible == true
                && tumblingDeleteTick.tumblingBridgePlatformEffects.count == 9
                && tumblingDeleteTick.tumblingBridgePlatformEffects.allSatisfy { $0.output.shouldDelete }
                && tumblingChildren.allSatisfy { tumblingEngine.objects.record(for: $0) == nil },
            "tumbling bridge parent exit deletes child platforms"
        )

        let floatingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let floatingBridge = SM64BehaviorDispatchBridge()
        let floatingSquare = try floatingBridge.spawnFloatingPlatform(
            in: floatingEngine,
            variant: .wdwSquare,
            floorHeight: 0,
            waterLevel: 200
        )
        let floatingRectangular = try floatingBridge.spawnFloatingPlatform(
            in: floatingEngine,
            variant: .wdwRectangular,
            floorHeight: 100,
            waterLevel: 0
        )
        let floatingJrb = try floatingBridge.spawnFloatingPlatform(
            in: floatingEngine,
            variant: .jrb,
            floorHeight: 0,
            waterLevel: 200
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FloatingPlatformObjectBridge.wdwSquareBehaviorIdentity) == .floatingPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64FloatingPlatformObjectBridge.wdwRectangularBehaviorIdentity) == .floatingPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64FloatingPlatformObjectBridge.jrbBehaviorIdentity) == .floatingPlatform,
            "floating platform identities share route"
        )
        let floatingTick = floatingBridge.tick(state: floatingEngine)
        require(
            floatingTick.events.map(\.route) == Array(repeating: .floatingPlatform, count: 3)
                && floatingTick.floatingPlatformEffects.count == 3
                && floatingTick.floatingPlatformEffects.first(where: { $0.objectID == floatingSquare })?.output.action == 0
                && floatingTick.floatingPlatformEffects.first(where: { $0.objectID == floatingSquare })?.output.positionY == 200
                && floatingTick.floatingPlatformEffects.first(where: { $0.objectID == floatingRectangular })?.output.action == 1
                && floatingTick.floatingPlatformEffects.first(where: { $0.objectID == floatingRectangular })?.output.positionY == 164
                && floatingTick.floatingPlatformEffects.first(where: { $0.objectID == floatingJrb })?.variant == .jrb,
            "WDW/JRB floating platform shared route is preserved"
        )
        let jrbBoxEngine = SM64SwiftEngineState(objectCapacity: 8)
        let jrbBoxBridge = SM64BehaviorDispatchBridge()
        let jrbBox = try jrbBoxBridge.spawnJrbFloatingBox(in: jrbBoxEngine, position: .init(x: 10, y: 100, z: 30))
        require(SM64BehaviorDispatchBridge.route(for: SM64JrbFloatingBoxObjectBridge.defaultBehaviorIdentity) == .floatingPlatform, "JRB floating box shared floating route")
        _ = jrbBoxEngine.objects.mutate(jrbBox) { $0.timer = 16 }
        let jrbBoxTick = jrbBoxBridge.tick(state: jrbBoxEngine)
        require(jrbBoxTick.jrbFloatingBoxEffects.first?.output.positionY == 110, "JRB floating box sine-height route")

        let sliding2Engine = SM64SwiftEngineState(objectCapacity: 8)
        let sliding2Bridge = SM64BehaviorDispatchBridge()
        let sliding2 = try sliding2Bridge.spawnSlidingPlatform2(
            in: sliding2Engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30),
            behaviorParams: 0x0010_0000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SlidingPlatform2ObjectBridge.defaultBehaviorIdentity) == .slidingPlatform2,
            "sliding platform 2 identity route"
        )
        let sliding2Tick = sliding2Bridge.tick(state: sliding2Engine)
        require(
            sliding2Tick.events.map(\.route) == [.slidingPlatform2]
                && sliding2Tick.slidingPlatform2Effects.count == 1
                && sliding2Tick.slidingPlatform2Effects[0].objectID == sliding2
                && sliding2Tick.slidingPlatform2Effects[0].output.position == .init(x: 10, y: 20, z: 30),
            "packed sliding platform 2 route is preserved"
        )

        let smallWaveEngine = SM64SwiftEngineState(objectCapacity: 8)
        let smallWaveBridge = SM64BehaviorDispatchBridge()
        let smallWave = try smallWaveBridge.spawnSmallWaterWave(
            in: smallWaveEngine,
            position: .zero,
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SmallWaterWaveObjectBridge.defaultBehaviorIdentity) == .smallWaterWave,
            "small water wave identity route"
        )
        let smallWaveTick = smallWaveBridge.tick(state: smallWaveEngine)
        require(
            smallWaveTick.events.map(\.route) == [.smallWaterWave]
                && smallWaveTick.smallWaterWaveEffects.count == 1
                && smallWaveTick.smallWaterWaveEffects[0].output.position.y == 7
                && !smallWaveTick.smallWaterWaveEffects[0].output.shouldDeactivate,
            "small water wave scale/rise route is preserved"
        )
        _ = smallWaveEngine.objects.mutate(smallWave) { record in record.position.y = 100 }
        let smallWaveDeleteTick = smallWaveBridge.tick(state: smallWaveEngine)
        require(
            smallWaveDeleteTick.smallWaterWaveEffects.count == 1
                && smallWaveDeleteTick.smallWaterWaveEffects[0].output.shouldDeactivate
                && smallWaveDeleteTick.smallWaterWaveEffects[0].spawnedSplash != nil
                && smallWaveDeleteTick.waterSplashEffects.count == 1
                && smallWaveDeleteTick.waterSplashEffects[0].objectID
                    == smallWaveDeleteTick.smallWaterWaveEffects[0].spawnedSplash
                && smallWaveEngine.objects.record(for: smallWave) == nil,
            "small water wave water-level deactivation/spawn route is preserved"
        )

        let ambientEngine = SM64SwiftEngineState(objectCapacity: 8)
        let ambientBridge = SM64BehaviorDispatchBridge()
        let birds = try ambientBridge.spawnBirdsSoundLoop(in: ambientEngine, behaviorByte: 0)
        let birdsSuppressed = try ambientBridge.spawnBirdsSoundLoop(
            in: ambientEngine,
            behaviorByte: 2,
            cameraBehindMario: true
        )
        let sand = try ambientBridge.spawnSandSoundLoop(in: ambientEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64AmbientSoundLoopObjectBridge.birdsBehaviorIdentity) == .ambientSoundLoop
                && SM64BehaviorDispatchBridge.route(for: SM64AmbientSoundLoopObjectBridge.sandBehaviorIdentity) == .ambientSoundLoop,
            "ambient sound identities share route"
        )
        let ambientTick = ambientBridge.tick(state: ambientEngine)
        require(
            ambientTick.events.map(\.route) == Array(repeating: .ambientSoundLoop, count: 3)
                && ambientTick.ambientSoundLoopEffects.count == 3
                && ambientTick.ambientSoundLoopEffects.first(where: { $0.objectID == birds })?.output.soundIntent == 0
                && ambientTick.ambientSoundLoopEffects.first(where: { $0.objectID == birdsSuppressed })?.output.playSound == false
                && ambientTick.ambientSoundLoopEffects.first(where: { $0.objectID == sand })?.output.soundIntent == 3,
            "birds/sand ambient sound route is preserved"
        )

        let exclamationEngine = SM64SwiftEngineState(objectCapacity: 8)
        let exclamationBridge = SM64BehaviorDispatchBridge()
        let exclamationParent = try exclamationEngine.spawnObject(
            in: .default,
            behaviorIdentity: 0x6578_7061_7265_6E74
        )
        _ = exclamationEngine.objects.mutate(exclamationParent) { $0.action = 1 }
        let exclamation = try exclamationBridge.spawnRotatingExclamationMark(
            in: exclamationEngine,
            parent: exclamationParent,
            moveYaw: 0x7fff
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RotatingExclamationMarkObjectBridge.defaultBehaviorIdentity) == .rotatingExclamationMark,
            "rotating exclamation mark identity route"
        )
        let exclamationActiveTick = exclamationBridge.tick(state: exclamationEngine)
        require(
            exclamationActiveTick.rotatingExclamationMarkEffects.count == 1
                && exclamationActiveTick.rotatingExclamationMarkEffects[0].output.moveYaw == 0x87ff
                && !exclamationActiveTick.rotatingExclamationMarkEffects[0].output.shouldDelete,
            "rotating exclamation mark active parent route is preserved"
        )
        _ = exclamationEngine.objects.mutate(exclamationParent) { $0.action = 2 }
        let exclamationDeleteTick = exclamationBridge.tick(state: exclamationEngine)
        require(
            exclamationDeleteTick.rotatingExclamationMarkEffects.count == 1
                && exclamationDeleteTick.rotatingExclamationMarkEffects[0].output.shouldDelete
                && exclamationEngine.objects.record(for: exclamation) == nil,
            "rotating exclamation mark parent deletion route is preserved"
        )

        let bubbleEngine = SM64SwiftEngineState(objectCapacity: 48)
        let bubbleBridge = SM64BehaviorDispatchBridge()
        let bubble = try bubbleBridge.spawnWaterAirBubble(in: bubbleEngine, waterLevel: 100)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterAirBubbleObjectBridge.defaultBehaviorIdentity) == .waterAirBubble,
            "water-air bubble identity route"
        )
        _ = bubbleEngine.objects.mutate(bubble) { record in
            record.timer = 201
            record.interactionStatus = 1
        }
        let bubbleTick = bubbleBridge.tick(state: bubbleEngine)
        require(
            bubbleTick.waterAirBubbleEffects.count == 1
                && bubbleTick.waterAirBubbleEffects[0].output.shouldDelete
                && bubbleTick.waterAirBubbleEffects[0].output.spawnBubbleCount == 30
                && bubbleTick.waterAirBubbleEffects[0].spawnedBubbles.count == 30
                && bubbleEngine.objects.record(for: bubble) == nil,
            "water-air bubble interaction/spawn route is preserved"
        )
        require(
            bubbleTick.bubbleMaybeEffects.count == 30
                && bubbleTick.bubbleMaybeEffects.allSatisfy {
                    $0.output.scaleX == 1
                        && $0.output.scaleY == 1
                        && $0.output.animationState == 0
                },
            "water-air bubble child oscillation route is preserved"
        )

        let objectBubbleEngine = SM64SwiftEngineState(objectCapacity: 8)
        let objectBubbleBridge = SM64BehaviorDispatchBridge()
        let objectBubble = try objectBubbleBridge.spawnObjectBubble(
            in: objectBubbleEngine,
            position: SM64ObjectVector3(x: 0, y: 101, z: 0),
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ObjectBubbleObjectBridge.defaultBehaviorIdentity) == .objectBubble,
            "object bubble identity route"
        )
        let objectBubbleTick = objectBubbleBridge.tick(state: objectBubbleEngine)
        require(
            objectBubbleTick.objectBubbleEffects.count == 1
                && objectBubbleTick.objectBubbleEffects[0].output.shouldDeactivate
                && objectBubbleTick.objectBubbleEffects[0].spawnedSplash != nil
                && objectBubbleEngine.objects.record(for: objectBubble) == nil,
            "object bubble water-boundary route is preserved"
        )
        let objectBubbleSplashTick = objectBubbleBridge.tick(state: objectBubbleEngine)
        require(
            objectBubbleSplashTick.waterSplashEffects.count == 1
                && objectBubbleSplashTick.waterSplashEffects[0].objectID
                    == objectBubbleTick.objectBubbleEffects[0].spawnedSplash,
            "object bubble child splash owner route is preserved"
        )

        let dropletEngine = SM64SwiftEngineState(objectCapacity: 8)
        let dropletBridge = SM64BehaviorDispatchBridge()
        let droplet = try dropletBridge.spawnWaterDroplet(
            in: dropletEngine,
            position: .zero,
            velocityY: -1,
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterDropletObjectBridge.defaultBehaviorIdentity) == .waterDroplet,
            "water droplet identity route"
        )
        let dropletTick = dropletBridge.tick(state: dropletEngine)
        require(
            dropletTick.waterDropletEffects.count == 1
                && dropletTick.waterDropletEffects[0].output.shouldDelete
                && dropletTick.waterDropletEffects[0].output.spawnSplash
                && dropletTick.waterDropletEffects[0].spawnedSplash != nil
                && dropletEngine.objects.record(for: droplet) == nil,
            "water droplet gravity/splash route is preserved"
        )
        let dropletSplashTick = dropletBridge.tick(state: dropletEngine)
        require(
            dropletSplashTick.waterSplashEffects.count == 1
                && dropletSplashTick.waterSplashEffects[0].objectID
                    == dropletTick.waterDropletEffects[0].spawnedSplash,
            "water droplet child splash owner route is preserved"
        )

        let splashEngine = SM64SwiftEngineState(objectCapacity: 8)
        let splashBridge = SM64BehaviorDispatchBridge()
        let bubbleSplash = try splashBridge.spawnBubbleSplash(
            in: splashEngine,
            position: SM64ObjectVector3(x: 10, y: 3, z: -3),
            waterLevel: 120
        )
        let dropletSplash = try splashBridge.spawnWaterDropletSplash(
            in: splashEngine,
            position: SM64ObjectVector3(x: -4, y: 0, z: 8),
            randomScale: 0.25
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterSplashObjectBridge.bubbleBehaviorIdentity)
                == .waterSplash
                && SM64BehaviorDispatchBridge.route(for: SM64WaterSplashObjectBridge.waterDropletBehaviorIdentity)
                    == .waterSplash,
            "water splash child identities route"
        )
        let splashTick = splashBridge.tick(state: splashEngine)
        require(
            splashTick.waterSplashEffects.count == 2
                && splashTick.waterSplashEffects.contains {
                    $0.objectID == bubbleSplash
                        && $0.output.position == .init(x: 10, y: 125, z: -3)
                        && $0.output.scale == .init(x: 0.5, y: 1, z: 0.5)
                }
                && splashTick.waterSplashEffects.contains {
                    $0.objectID == dropletSplash
                        && $0.output.position == .init(x: -4, y: 5, z: 8)
                        && $0.output.scale == .init(x: 1.75, y: 1.75, z: 1.75)
                },
            "water splash value/owner route is preserved"
        )

        let bubbleMaybeEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bubbleMaybeBridge = SM64BehaviorDispatchBridge()
        let bubbleMaybe = try bubbleMaybeBridge.spawnBubbleMaybe(
            in: bubbleMaybeEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            randomOffsetX: 2,
            randomOffsetY: 3,
            randomOffsetZ: -1,
            angleF4: 0x400,
            angleF8: 0x800,
            expansionRateX: 0x100,
            expansionRateY: 0x200
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BubbleMaybeObjectBridge.defaultBehaviorIdentity)
                == .bubbleMaybe,
            "bubble-maybe identity route"
        )
        let bubbleMaybeTick = bubbleMaybeBridge.tick(state: bubbleMaybeEngine)
        require(
            bubbleMaybeTick.bubbleMaybeEffects.count == 1
                && bubbleMaybeTick.bubbleMaybeEffects[0].objectID == bubbleMaybe
                && bubbleMaybeTick.bubbleMaybeEffects[0].output.position
                    == .init(x: 12, y: 23, z: -5)
                && bubbleMaybeTick.bubbleMaybeEffects[0].output.animationState == 0,
            "bubble-maybe value/owner route is preserved"
        )

        let windEngine = SM64SwiftEngineState(objectCapacity: 8)
        let windBridge = SM64BehaviorDispatchBridge()
        let wind = try windBridge.spawnWind(
            in: windEngine,
            position: SM64ObjectVector3(x: 100, y: 200, z: -50),
            moveYaw: 0x4000,
            initialRandomX: 10,
            initialRandomY: 15,
            initialRandomZ: -20,
            initialForwardVelocity: 10
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WindObjectBridge.defaultBehaviorIdentity) == .wind,
            "wind identity route"
        )
        let windTick = windBridge.tick(state: windEngine)
        require(
            windTick.windEffects.count == 1
                && windTick.windEffects[0].objectID == wind
                && windTick.windEffects[0].output.position
                    == .init(x: -390, y: 295, z: -60)
                && windTick.windEffects[0].output.opacity == 100,
            "wind value/owner route is preserved"
        )
        let jetStreamEngine = SM64SwiftEngineState(objectCapacity: 8)
        let jetStreamBridge = SM64BehaviorDispatchBridge()
        let jetStream = try jetStreamBridge.spawnJetStream(in: jetStreamEngine, position: .init(x: 10, y: 20, z: 30), distanceToMario: 4_000)
        require(SM64BehaviorDispatchBridge.route(for: SM64JetStreamObjectBridge.defaultBehaviorIdentity) == .wind, "Jet Stream shared wind route")
        let jetStreamTick = jetStreamBridge.tick(state: jetStreamEngine)
        require(jetStreamTick.jetStreamEffects.first?.objectID == jetStream && jetStreamTick.jetStreamEffects.first?.output.particleCount == 60 && jetStreamTick.jetStreamEffects.first?.output.visible == true, "Jet Stream bubble/sound gate route")
        let jetRingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let jetRingBridge = SM64BehaviorDispatchBridge()
        let jetRing = try jetRingBridge.spawnJetStreamWaterRing(in: jetRingEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64JetStreamWaterRingObjectBridge.defaultBehaviorIdentity) == .wind, "Jet Stream water-ring shared wind route")
        require(jetRingBridge.jetStreamWaterRing.setCollectionInput(marioNear: true, crossedRingPlane: true, for: jetRing), "Jet Stream water-ring collection input")
        let jetRingTick = jetRingBridge.tick(state: jetRingEngine)
        require(jetRingTick.jetStreamWaterRingEffects.first?.output.collected == true && jetRingTick.jetStreamWaterRingEffects.first?.output.action == 1, "Jet Stream water-ring collection route")
        let jetSpawnerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let jetSpawnerBridge = SM64BehaviorDispatchBridge()
        let jetSpawner = try jetSpawnerBridge.spawnJetStreamRingSpawner(in: jetSpawnerEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64JetStreamRingSpawnerObjectBridge.defaultBehaviorIdentity) == .wind, "Jet Stream ring-spawner shared wind route")
        let jetSpawnerTick = jetSpawnerBridge.tick(state: jetSpawnerEngine)
        require(jetSpawnerTick.jetStreamRingSpawnerEffects.first?.spawnedRing != nil, "Jet Stream ring-spawner cadence route")
        require(jetSpawnerBridge.jetStreamRingSpawner.setRingsCollected(5, for: jetSpawner), "Jet Stream ring-spawner solved input")
        _ = jetSpawnerEngine.objects.mutate(jetSpawner) { $0.timer = 10 }
        let jetSolvedTick = jetSpawnerBridge.tick(state: jetSpawnerEngine)
        require(jetSolvedTick.jetStreamRingSpawnerEffects.first?.output.spawnStar == true, "Jet Stream ring-spawner star intent route")
        let mantaRingEngine = SM64SwiftEngineState(objectCapacity: 8)
        let mantaRingBridge = SM64BehaviorDispatchBridge()
        let mantaRing = try mantaRingBridge.spawnMantaRayWaterRing(in: mantaRingEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64MantaRayWaterRingObjectBridge.defaultBehaviorIdentity) == .wind, "Manta Ray water-ring shared wind route")
        require(mantaRingBridge.mantaRayWaterRing.setCollectionInput(marioNear: true, crossedRingPlane: true, for: mantaRing), "Manta Ray water-ring collection input")
        let mantaRingTick = mantaRingBridge.tick(state: mantaRingEngine)
        require(mantaRingTick.mantaRayWaterRingEffects.first?.output.collected == true && mantaRingTick.mantaRayWaterRingEffects.first?.output.action == 1, "Manta Ray water-ring collection route")
        let whirlpoolEngine = SM64SwiftEngineState(objectCapacity: 8)
        let whirlpoolBridge = SM64BehaviorDispatchBridge()
        let whirlpool = try whirlpoolBridge.spawnWhirlpool(in: whirlpoolEngine, position: .init(x: 10, y: 20, z: 30), distanceToMario: 4_000)
        require(SM64BehaviorDispatchBridge.route(for: SM64WhirlpoolObjectBridge.defaultBehaviorIdentity) == .wind, "whirlpool shared wind route")
        let whirlpoolTick = whirlpoolBridge.tick(state: whirlpoolEngine)
        require(whirlpoolTick.whirlpoolEffects.first?.objectID == whirlpool && whirlpoolTick.whirlpoolEffects.first?.output.particleCount == 60 && whirlpoolTick.whirlpoolEffects.first?.output.faceYaw == 0x1F40, "whirlpool bubble/rotation route")
        let mantaEngine = SM64SwiftEngineState(objectCapacity: 16)
        let mantaBridge = SM64BehaviorDispatchBridge()
        let manta = try mantaBridge.spawnMantaRay(in: mantaEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64MantaRayObjectBridge.defaultBehaviorIdentity) == .wind, "Manta Ray shared wind route")
        let mantaTick = mantaBridge.tick(state: mantaEngine)
        require(mantaTick.mantaRayEffects.first?.objectID == manta && mantaTick.mantaRayEffects.first?.output.spawnRing == true, "Manta Ray trajectory/ring route")
        require(mantaBridge.mantaRay.setRingsCollected(5, for: manta), "Manta Ray solved ring input")
        _ = mantaEngine.objects.mutate(manta) { $0.timer = 50 }
        let mantaSolvedTick = mantaBridge.tick(state: mantaEngine)
        require(mantaSolvedTick.mantaRayEffects.first?.output.spawnStar == true && mantaSolvedTick.mantaRayEffects.first?.output.action == 1, "Manta Ray star transition route")

        let shallowEngine = SM64SwiftEngineState(objectCapacity: 16)
        let shallowBridge = SM64BehaviorDispatchBridge()
        let shallow = try shallowBridge.spawnShallowWaterWave(
            in: shallowEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(
                for: SM64ShallowWaterWaveObjectBridge.defaultBehaviorIdentity
            ) == .shallowWaterWave,
            "shallow-water-wave identity route"
        )
        let shallowTick = shallowBridge.tick(state: shallowEngine)
        require(
            shallowTick.shallowWaterWaveEffects.count == 1
                && shallowTick.shallowWaterWaveEffects[0].objectID == shallow
                && shallowTick.shallowWaterWaveEffects[0].output.spawnDropletCount == 5
                && shallowTick.shallowWaterWaveEffects[0].spawnedDroplets.count == 5
                && shallowTick.waterDropletEffects.count == 5
                && shallowEngine.objects.record(for: shallow) != nil,
            "shallow-water-wave parent/child route is preserved"
        )
        _ = shallowBridge.tick(state: shallowEngine)
        require(shallowEngine.objects.record(for: shallow) == nil, "shallow-water-wave delayed deactivation is preserved")

        let shallowSplashEngine = SM64SwiftEngineState(objectCapacity: 32)
        let shallowSplashBridge = SM64BehaviorDispatchBridge()
        let shallowSplash = try shallowSplashBridge.spawnShallowWaterSplash(
            in: shallowSplashEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(
                for: SM64ShallowWaterWaveObjectBridge.splashBehaviorIdentity
            ) == .shallowWaterWave,
            "shallow-water-splash identity route"
        )
        let shallowSplashTick = shallowSplashBridge.tick(state: shallowSplashEngine)
        require(
            shallowSplashTick.shallowWaterWaveEffects.count == 1
                && shallowSplashTick.shallowWaterWaveEffects[0].objectID == shallowSplash
                && shallowSplashTick.shallowWaterWaveEffects[0].output.spawnDropletCount == 18
                && shallowSplashTick.shallowWaterWaveEffects[0].spawnedDroplets.count == 18
                && shallowSplashTick.waterDropletEffects.count == 18,
            "shallow-water-splash parent/child route is preserved"
        )

        let waterSplashEngine = SM64SwiftEngineState(objectCapacity: 64)
        let waterSplashBridge = SM64BehaviorDispatchBridge()
        let waterSplash = try waterSplashBridge.spawnWaterSplashSpawner(
            in: waterSplashEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(
                for: SM64WaterSplashSpawnerObjectBridge.defaultBehaviorIdentity
            ) == .waterSplashSpawner,
            "water-splash spawner identity route"
        )
        let waterSplashTick = waterSplashBridge.tick(state: waterSplashEngine)
        require(
            waterSplashTick.waterSplashSpawnerEffects.count == 1
                && waterSplashTick.waterSplashSpawnerEffects[0].objectID == waterSplash
                && waterSplashTick.waterSplashSpawnerEffects[0].output.position.y == 100
                && waterSplashTick.waterSplashSpawnerEffects[0].output.spawnDropletCount == 3
                && waterSplashTick.waterSplashSpawnerEffects[0].spawnedDroplets.count == 3
                && waterSplashTick.waterDropletEffects.count == 3,
            "water-splash spawner parent/child route is preserved"
        )
        for _ in 0..<11 { _ = waterSplashBridge.tick(state: waterSplashEngine) }
        require(waterSplashEngine.objects.record(for: waterSplash) == nil, "water-splash spawner teardown is preserved")

        let bubbleSpawnerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let bubbleSpawnerBridge = SM64BehaviorDispatchBridge()
        let bubbleSpawner = try bubbleSpawnerBridge.spawnBubbleParticleSpawner(
            in: bubbleSpawnerEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            delay: 2,
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(
                for: SM64BubbleParticleSpawnerObjectBridge.defaultBehaviorIdentity
            ) == .bubbleParticleSpawner,
            "bubble particle spawner identity route"
        )
        _ = bubbleSpawnerBridge.tick(state: bubbleSpawnerEngine)
        _ = bubbleSpawnerBridge.tick(state: bubbleSpawnerEngine)
        let bubbleSpawnerTick = bubbleSpawnerBridge.tick(state: bubbleSpawnerEngine)
        require(
            bubbleSpawnerTick.bubbleParticleSpawnerEffects.count == 1
                && bubbleSpawnerTick.bubbleParticleSpawnerEffects[0].objectID == bubbleSpawner
                && bubbleSpawnerTick.bubbleParticleSpawnerEffects[0].spawnedChild != nil
                && bubbleSpawnerTick.smallWaterWaveEffects.count == 1
                && bubbleSpawnerEngine.objects.record(for: bubbleSpawner) == nil,
            "bubble particle spawner parent/child route is preserved"
        )

        let wakingBubbleEngine = SM64SwiftEngineState(objectCapacity: 8)
        let wakingBubbleBridge = SM64BehaviorDispatchBridge()
        let wakingBubble = try wakingBubbleBridge.spawnPiranhaPlantWakingBubble(
            in: wakingBubbleEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            initialMoveYaw: 0x4000,
            initialForwardVelocity: 10,
            initialVelocityY: 8
        )
        require(
            SM64BehaviorDispatchBridge.route(
                for: SM64PiranhaPlantWakingBubbleObjectBridge.defaultBehaviorIdentity
            ) == .piranhaPlantWakingBubble,
            "Piranha waking bubble identity route"
        )
        let wakingBubbleTick = wakingBubbleBridge.tick(state: wakingBubbleEngine)
        require(
            wakingBubbleTick.piranhaPlantWakingBubbleEffects.count == 1
                && wakingBubbleTick.piranhaPlantWakingBubbleEffects[0].objectID == wakingBubble
                && wakingBubbleTick.piranhaPlantWakingBubbleEffects[0].output.position
                    == .init(x: 10, y: 28, z: 6)
                && wakingBubbleTick.piranhaPlantWakingBubbleEffects[0].output.timer == 1,
            "Piranha waking bubble physics route is preserved"
        )
        for _ in 0..<9 { _ = wakingBubbleBridge.tick(state: wakingBubbleEngine) }
        require(wakingBubbleEngine.objects.record(for: wakingBubble) == nil, "Piranha waking bubble lifetime is preserved")

        let piranhaBubbleEngine = SM64SwiftEngineState(objectCapacity: 48)
        let piranhaBubbleBridge = SM64BehaviorDispatchBridge()
        let piranhaParent = try piranhaBubbleEngine.spawnObject(in: .generalActor, behaviorIdentity: 0x706172656e7431)
        _ = piranhaBubbleEngine.objects.mutate(piranhaParent) { record in
            record.position = SM64ObjectVector3(x: 10, y: 20, z: -4)
            record.action = Int32(SM64PiranhaPlantAction.sleeping.rawValue)
            record.moveAngles.yaw = 0x4000
            record.animationState = 0
            record.distanceToMario = 100
            record.drawingDistance = 2_000
        }
        let piranhaBubble = try piranhaBubbleBridge.spawnPiranhaPlantBubble(
            in: piranhaBubbleEngine,
            parent: piranhaParent,
            lastAnimationFrame: 30
        )
        require(
            SM64BehaviorDispatchBridge.route(
                for: SM64PiranhaPlantBubbleObjectBridge.defaultBehaviorIdentity
            ) == .piranhaPlantBubble,
            "Piranha Plant bubble identity route"
        )
        _ = piranhaBubbleBridge.tick(state: piranhaBubbleEngine)
        let piranhaBubbleGrowTick = piranhaBubbleBridge.tick(state: piranhaBubbleEngine)
        require(
            piranhaBubbleGrowTick.piranhaPlantBubbleEffects.count == 1
                && piranhaBubbleGrowTick.piranhaPlantBubbleEffects[0].objectID == piranhaBubble
                && piranhaBubbleGrowTick.piranhaPlantBubbleEffects[0].output.scale == 5
                && !piranhaBubbleGrowTick.piranhaPlantBubbleEffects[0].output.hidden,
            "Piranha Plant bubble grow route is preserved"
        )
        _ = piranhaBubbleEngine.objects.mutate(piranhaParent) { $0.action = Int32(SM64PiranhaPlantAction.wokenUp.rawValue) }
        let piranhaBubbleBurstTick = piranhaBubbleBridge.tick(state: piranhaBubbleEngine)
        require(
            piranhaBubbleBurstTick.piranhaPlantBubbleEffects.count == 1
                && piranhaBubbleBurstTick.piranhaPlantBubbleEffects[0].output.action == .burst
                && piranhaBubbleBurstTick.piranhaPlantBubbleEffects[0].output.spawnWakingBubbleCount == 0,
            "Piranha Plant bubble burst transition route is preserved"
        )
        let piranhaBubbleSpawnTick = piranhaBubbleBridge.tick(state: piranhaBubbleEngine)
        require(
            piranhaBubbleSpawnTick.piranhaPlantBubbleEffects.count == 1
                && piranhaBubbleSpawnTick.piranhaPlantBubbleEffects[0].output.action == .idle
                && piranhaBubbleSpawnTick.piranhaPlantBubbleEffects[0].spawnedWakingBubbles.count == 15
                && piranhaBubbleSpawnTick.piranhaPlantWakingBubbleEffects.count == 15,
            "Piranha Plant bubble child burst route is preserved"
        )

        let waveTrailEngine = SM64SwiftEngineState(objectCapacity: 8)
        let waveTrailBridge = SM64BehaviorDispatchBridge()
        let marioWaveTrail = try waveTrailBridge.spawnWaveTrail(
            in: waveTrailEngine,
            kind: .mario,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            waterLevel: 100,
            globalFrame: 0
        )
        let objectWaveTrail = try waveTrailBridge.spawnWaveTrail(
            in: waveTrailEngine,
            kind: .object,
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            waterLevel: 100,
            globalFrame: 1
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaveTrailObjectBridge.marioBehaviorIdentity) == .waveTrail
                && SM64BehaviorDispatchBridge.route(for: SM64WaveTrailObjectBridge.objectBehaviorIdentity) == .waveTrail,
            "wave trail identities share route"
        )
        let waveTrailTick = waveTrailBridge.tick(state: waveTrailEngine)
        require(
            waveTrailTick.waveTrailEffects.count == 2
                && waveTrailTick.waveTrailEffects.first(where: { $0.objectID == marioWaveTrail })?.output.position
                    == .init(x: 10, y: 105, z: -4)
                && waveTrailTick.waveTrailEffects.first(where: { $0.objectID == objectWaveTrail })?.output.shouldDelete == true,
            "wave trail placement/alternating deletion route is preserved"
        )

        let strongWindEngine = SM64SwiftEngineState(objectCapacity: 8)
        let strongWindBridge = SM64BehaviorDispatchBridge()
        let visibleWind = try strongWindBridge.spawnStrongWindParticle(
            in: strongWindEngine,
            kind: .visible,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            movePitch: 0,
            initialRandomX: 1,
            initialRandomY: 2,
            initialRandomZ: 3
        )
        let tinyWind = try strongWindBridge.spawnStrongWindParticle(
            in: strongWindEngine,
            kind: .tiny,
            position: .zero,
            movePitch: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64StrongWindParticleObjectBridge.visibleBehaviorIdentity) == .strongWindParticle
                && SM64BehaviorDispatchBridge.route(for: SM64StrongWindParticleObjectBridge.tinyBehaviorIdentity) == .strongWindParticle,
            "strong wind particle identities share route"
        )
        let strongWindTick = strongWindBridge.tick(state: strongWindEngine)
        require(
            strongWindTick.strongWindParticleEffects.count == 2
                && strongWindTick.strongWindParticleEffects.first(where: { $0.objectID == visibleWind })?.output.position
                    == .init(x: 111, y: 22, z: -1)
                && strongWindTick.strongWindParticleEffects.first(where: { $0.objectID == tinyWind })?.output.opacity == 100,
            "strong wind particle movement route is preserved"
        )

        let waterParticleEngine = SM64SwiftEngineState(objectCapacity: 16)
        let waterParticleBridge = SM64BehaviorDispatchBridge()
        let smallParticle = try waterParticleBridge.spawnWaterParticle(
            in: waterParticleEngine,
            kind: .small,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            initialOffset: SM64ObjectVector3(x: 1, y: 2, z: 3),
            waterLevel: 100,
            randomStepX: 0.5,
            randomStepZ: -0.5
        )
        let snowParticle = try waterParticleBridge.spawnWaterParticle(
            in: waterParticleEngine,
            kind: .snow,
            position: .zero,
            waterLevel: 100
        )
        let bubbleParticle = try waterParticleBridge.spawnWaterParticle(
            in: waterParticleEngine,
            kind: .bubbles,
            position: .zero,
            waterLevel: -1
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterParticleObjectBridge.smallBehaviorIdentity) == .waterParticle
                && SM64BehaviorDispatchBridge.route(for: SM64WaterParticleObjectBridge.snowBehaviorIdentity) == .waterParticle
                && SM64BehaviorDispatchBridge.route(for: SM64WaterParticleObjectBridge.bubblesBehaviorIdentity) == .waterParticle,
            "water particle identities share route"
        )
        let waterParticleTick = waterParticleBridge.tick(state: waterParticleEngine)
        require(
            waterParticleTick.waterParticleEffects.count == 3
                && waterParticleTick.waterParticleEffects.first(where: { $0.objectID == smallParticle })?.output.position
                    == .init(x: 11.5, y: 27, z: -1.5)
                && waterParticleTick.waterParticleEffects.first(where: { $0.objectID == snowParticle })?.output.kind == .snow
                && waterParticleTick.waterParticleEffects.first(where: { $0.objectID == bubbleParticle })?.output.spawnObjectSplash == false,
            "water particle variant route is preserved"
        )

        let plungeEngine = SM64SwiftEngineState(objectCapacity: 16)
        let plungeBridge = SM64BehaviorDispatchBridge()
        let plunge = try plungeBridge.spawnPlungeBubble(
            in: plungeEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64PlungeBubbleObjectBridge.defaultBehaviorIdentity)
                == .plungeBubble,
            "plunge bubble identity route"
        )
        let plungeTick = plungeBridge.tick(state: plungeEngine)
        require(
            plungeTick.plungeBubbleEffects.count == 1
                && plungeTick.plungeBubbleEffects[0].objectID == plunge
                && plungeTick.plungeBubbleEffects[0].spawnedParticles.count == 3
                && plungeTick.waterParticleEffects.count == 3
                && plungeEngine.objects.record(for: plunge) == nil,
            "plunge bubble parent/child route is preserved"
        )

        let breathEngine = SM64SwiftEngineState(objectCapacity: 16)
        let breathBridge = SM64BehaviorDispatchBridge()
        let breath = try breathBridge.spawnBreathParticleSpawner(
            in: breathEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BreathParticleSpawnerObjectBridge.defaultBehaviorIdentity)
                == .breathParticleSpawner,
            "breath particle spawner identity route"
        )
        let breathTick = breathBridge.tick(state: breathEngine)
        require(
            breathTick.breathParticleSpawnerEffects.count == 1
                && breathTick.breathParticleSpawnerEffects[0].objectID == breath
                && breathTick.breathParticleSpawnerEffects[0].spawnedMist != nil
                && breathTick.waterMistEffects.count == 1
                && breathEngine.objects.record(for: breath) != nil,
            "breath particle spawner parent/child route is preserved"
        )
        for _ in 0..<7 { _ = breathBridge.tick(state: breathEngine) }
        require(breathEngine.objects.record(for: breath) == nil, "breath particle spawner delayed teardown is preserved")

        let mistSpawnerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let mistSpawnerBridge = SM64BehaviorDispatchBridge()
        let mistSpawner = try mistSpawnerBridge.spawnMistParticleSpawner(in: mistSpawnerEngine, position: SM64ObjectVector3(x: 10, y: 20, z: -4))
        let mistSpawnerTick = mistSpawnerBridge.tick(state: mistSpawnerEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64MistParticleSpawnerObjectBridge.defaultBehaviorIdentity) == .mistParticleSpawner
                && SM64BehaviorDispatchBridge.route(for: SM64MistParticleObjectBridge.puff1BehaviorIdentity) == .mistParticle
                && SM64BehaviorDispatchBridge.route(for: SM64MistParticleObjectBridge.puff2BehaviorIdentity) == .mistParticle,
            "mist particle identities route"
        )
        require(
            mistSpawnerTick.mistParticleSpawnerEffects.count == 1
                && mistSpawnerTick.mistParticleSpawnerEffects[0].objectID == mistSpawner
                && mistSpawnerTick.mistParticleSpawnerEffects[0].spawnedPuff1 != nil
                && mistSpawnerTick.mistParticleSpawnerEffects[0].spawnedPuff2 != nil
                && mistSpawnerTick.mistParticleEffects.count == 2,
            "mist particle parent/child route is preserved"
        )

        let tweesterEngine = SM64SwiftEngineState(objectCapacity: 8)
        let tweesterBridge = SM64BehaviorDispatchBridge()
        let tweester = try tweesterBridge.spawnTweesterSandParticle(
            in: tweesterEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            initialRandomX: 1,
            initialRandomZ: 2,
            randomScale: 0.25
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TweesterSandParticleObjectBridge.defaultBehaviorIdentity)
                == .tweesterSandParticle,
            "Tweester sand particle identity route"
        )
        let tweesterTick = tweesterBridge.tick(state: tweesterEngine)
        require(
            tweesterTick.tweesterSandParticleEffects.count == 1
                && tweesterTick.tweesterSandParticleEffects[0].objectID == tweester
                && tweesterTick.tweesterSandParticleEffects[0].output.position
                    == .init(x: 11, y: 42, z: -2)
                && tweesterTick.tweesterSandParticleEffects[0].output.scale == 1.25,
            "Tweester sand particle movement route is preserved"
        )

        let flameRuntimeEngine = SM64SwiftEngineState(objectCapacity: 16)
        let flameRuntimeBridge = SM64BehaviorDispatchBridge()
        let marioObject = try flameRuntimeEngine.spawnObject(in: .player, isMario: true)
        _ = flameRuntimeEngine.objects.mutate(marioObject) { record in
            record.position = SM64ObjectVector3(x: 10, y: 200, z: -4)
            record.moveAngles.yaw = 0
        }
        let flameMarioID = try flameRuntimeBridge.spawnFlameMario(in: flameRuntimeEngine, parent: marioObject)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlameMarioObjectBridge.defaultBehaviorIdentity) == .flameMario
                && SM64BehaviorDispatchBridge.route(for: SM64BlackSmokeMarioObjectBridge.defaultBehaviorIdentity) == .blackSmokeMario,
            "Mario flame/smoke identities route"
        )
        let flameMarioTick = flameRuntimeBridge.tick(state: flameRuntimeEngine)
        require(
            flameMarioTick.flameMarioEffects.count == 1
                && flameMarioTick.flameMarioEffects[0].objectID == flameMarioID
                && flameMarioTick.flameMarioEffects[0].output.position == SM64ObjectVector3(x: 10, y: 80, z: 36)
                && flameMarioTick.flameMarioEffects[0].spawnedSmoke == nil,
            "Mario flame placement route is preserved"
        )
        let flameSmokeTick = flameRuntimeBridge.tick(state: flameRuntimeEngine)
        require(
            flameSmokeTick.flameMarioEffects.count == 1
                && flameSmokeTick.flameMarioEffects[0].spawnedSmoke != nil
                && flameSmokeTick.blackSmokeMarioEffects.count == 1,
            "Mario flame emitted smoke route is preserved"
        )

        let bowserSmokeEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bowserSmokeBridge = SM64BehaviorDispatchBridge()
        let bowserSmoke = try bowserSmokeBridge.spawnBlackSmokeBowser(
            in: bowserSmokeEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            initialMoveYaw: 0,
            initialForwardVelocity: 2,
            initialVelocityY: 8
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlackSmokeBowserObjectBridge.defaultBehaviorIdentity)
                == .blackSmokeBowser,
            "Bowser black-smoke identity route"
        )
        let bowserSmokeTick = bowserSmokeBridge.tick(state: bowserSmokeEngine)
        require(
            bowserSmokeTick.blackSmokeBowserEffects.count == 1
                && bowserSmokeTick.blackSmokeBowserEffects[0].objectID == bowserSmoke
                && bowserSmokeTick.blackSmokeBowserEffects[0].output.position
                    == SM64ObjectVector3(x: 10, y: 28, z: -2)
                && bowserSmokeTick.blackSmokeBowserEffects[0].output.animationState == 1,
            "Bowser black-smoke movement route is preserved"
        )
        for _ in 0..<7 { _ = bowserSmokeBridge.tick(state: bowserSmokeEngine) }
        require(bowserSmokeEngine.objects.record(for: bowserSmoke) == nil, "Bowser black-smoke eight-frame teardown is preserved")

        let upwardSmokeEngine = SM64SwiftEngineState(objectCapacity: 16)
        let upwardSmokeBridge = SM64BehaviorDispatchBridge()
        let upwardSmoke = try upwardSmokeBridge.spawnBlackSmokeUpward(
            in: upwardSmokeEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            scale: 2
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlackSmokeUpwardObjectBridge.defaultBehaviorIdentity)
                == .blackSmokeUpward,
            "upward black-smoke identity route"
        )
        let upwardSmokeTick = upwardSmokeBridge.tick(state: upwardSmokeEngine)
        require(
            upwardSmokeTick.blackSmokeUpwardEffects.count == 1
                && upwardSmokeTick.blackSmokeUpwardEffects[0].objectID == upwardSmoke
                && upwardSmokeTick.blackSmokeUpwardEffects[0].spawnedChild != nil
                && upwardSmokeEngine.objects.record(for: upwardSmokeTick.blackSmokeUpwardEffects[0].spawnedChild!)?.scale
                    == .init(x: 2, y: 2, z: 2),
            "upward black-smoke parent/child route is preserved"
        )
        for _ in 0..<3 { _ = upwardSmokeBridge.tick(state: upwardSmokeEngine) }
        require(upwardSmokeEngine.objects.record(for: upwardSmoke) == nil, "upward black-smoke four-frame teardown is preserved")

        let whitePuffSmokeEngine = SM64SwiftEngineState(objectCapacity: 8)
        let whitePuffSmokeBridge = SM64BehaviorDispatchBridge()
        let whitePuffSmoke = try whitePuffSmokeBridge.spawnWhitePuffSmoke(
            in: whitePuffSmokeEngine,
            position: SM64ObjectVector3(x: 10, y: 100, z: -4),
            initialScale: 3
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WhitePuffSmokeObjectBridge.defaultBehaviorIdentity)
                == .whitePuffSmoke,
            "white puff smoke identity route"
        )
        let whitePuffSmokeTick = whitePuffSmokeBridge.tick(state: whitePuffSmokeEngine)
        require(
            whitePuffSmokeTick.whitePuffSmokeEffects.count == 1
                && whitePuffSmokeTick.whitePuffSmokeEffects[0].objectID == whitePuffSmoke
                && whitePuffSmokeTick.whitePuffSmokeEffects[0].output.position
                    == SM64ObjectVector3(x: 10, y: 0, z: -4)
                && whitePuffSmokeTick.whitePuffSmokeEffects[0].output.animationState == 0,
            "white puff smoke initialization route is preserved"
        )
        for _ in 0..<9 { _ = whitePuffSmokeBridge.tick(state: whitePuffSmokeEngine) }
        require(whitePuffSmokeEngine.objects.record(for: whitePuffSmoke) == nil, "white puff smoke ten-frame teardown is preserved")

        let whitePuffSmoke2Engine = SM64SwiftEngineState(objectCapacity: 8)
        let whitePuffSmoke2Bridge = SM64BehaviorDispatchBridge()
        let whitePuffSmoke2 = try whitePuffSmoke2Bridge.spawnWhitePuffSmoke2(
            in: whitePuffSmoke2Engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            forwardVelocity: 2,
            velocityY: 4,
            gravity: -1,
            initialOffsetX: 1,
            initialOffsetZ: 2
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WhitePuffSmoke2ObjectBridge.defaultBehaviorIdentity)
                == .whitePuffSmoke2,
            "white puff smoke 2 identity route"
        )
        let whitePuffSmoke2Tick = whitePuffSmoke2Bridge.tick(state: whitePuffSmoke2Engine)
        require(
            whitePuffSmoke2Tick.whitePuffSmoke2Effects.count == 1
                && whitePuffSmoke2Tick.whitePuffSmoke2Effects[0].objectID == whitePuffSmoke2
                && whitePuffSmoke2Tick.whitePuffSmoke2Effects[0].output.position
                    == SM64ObjectVector3(x: 11, y: 23, z: 0)
                && whitePuffSmoke2Tick.whitePuffSmoke2Effects[0].output.velocityY == 3,
            "white puff smoke 2 movement route is preserved"
        )
        for _ in 0..<6 { _ = whitePuffSmoke2Bridge.tick(state: whitePuffSmoke2Engine) }
        require(whitePuffSmoke2Engine.objects.record(for: whitePuffSmoke2) == nil, "white puff smoke 2 seven-frame teardown is preserved")

        let whitePuffExplosionEngine = SM64SwiftEngineState(objectCapacity: 8)
        let whitePuffExplosionBridge = SM64BehaviorDispatchBridge()
        let whitePuffExplosion = try whitePuffExplosionBridge.spawnWhitePuffExplosion(
            in: whitePuffExplosionEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            velocity: SM64ObjectVector3(x: 1, y: 2, z: 3),
            gravity: -1,
            initialScale: 254,
            behaviorParam: 2
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WhitePuffExplosionObjectBridge.defaultBehaviorIdentity)
                == .whitePuffExplosion,
            "white puff explosion identity route"
        )
        let whitePuffExplosionTick = whitePuffExplosionBridge.tick(state: whitePuffExplosionEngine)
        require(
            whitePuffExplosionTick.whitePuffExplosionEffects.count == 1
                && whitePuffExplosionTick.whitePuffExplosionEffects[0].objectID == whitePuffExplosion
                && whitePuffExplosionTick.whitePuffExplosionEffects[0].output.position
                    == SM64ObjectVector3(x: 11, y: 22, z: -1)
                && whitePuffExplosionTick.whitePuffExplosionEffects[0].output.opacity == 233
                && whitePuffExplosionTick.whitePuffExplosionEffects[0].output.scale == 233,
            "white puff explosion fade/movement route is preserved"
        )
        for _ in 0..<20 { _ = whitePuffExplosionBridge.tick(state: whitePuffExplosionEngine) }
        require(whitePuffExplosionEngine.objects.record(for: whitePuffExplosion) == nil, "white puff explosion teardown is preserved")

        let dustSmokeEngine = SM64SwiftEngineState(objectCapacity: 16)
        let dustSmokeBridge = SM64BehaviorDispatchBridge()
        let dustSmoke = try dustSmokeBridge.spawnDustSmoke(
            in: dustSmokeEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            velocity: SM64ObjectVector3(x: 1, y: 2, z: 3),
            forwardVelocity: 2
        )
        let fuseSmoke = try dustSmokeBridge.spawnBobombFuseSmoke(
            in: dustSmokeEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            initialOffset: SM64ObjectVector3(x: 1, y: 60, z: -2)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64DustSmokeObjectBridge.smokeBehaviorIdentity) == .dustSmoke
                && SM64BehaviorDispatchBridge.route(for: SM64DustSmokeObjectBridge.bobombFuseBehaviorIdentity) == .dustSmoke,
            "dust smoke identities route"
        )
        let dustDelayTick = dustSmokeBridge.tick(state: dustSmokeEngine)
        require(
            dustDelayTick.dustSmokeEffects.count == 2
                && dustDelayTick.dustSmokeEffects.contains { $0.objectID == fuseSmoke && $0.output.position == .init(x: 11, y: 80, z: -6) },
            "dust smoke delay and fuse initialization route is preserved"
        )
        let dustMoveTick = dustSmokeBridge.tick(state: dustSmokeEngine)
        require(
            dustMoveTick.dustSmokeEffects.contains { $0.objectID == dustSmoke && $0.output.position == .init(x: 11, y: 22, z: 1) && $0.output.smokeTimer == 1 },
            "dust smoke movement route is preserved"
        )
        for _ in 0..<10 { _ = dustSmokeBridge.tick(state: dustSmokeEngine) }
        require(dustSmokeEngine.objects.record(for: dustSmoke) == nil, "dust smoke eleven-step native lifetime is preserved")

        let starKeyPuffEngine = SM64SwiftEngineState(objectCapacity: 64)
        let starKeyPuffBridge = SM64BehaviorDispatchBridge()
        let starKeyPuffSpawner = try starKeyPuffBridge.spawnStarKeyCollectionPuffSpawner(
            in: starKeyPuffEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64StarKeyCollectionPuffSpawnerObjectBridge.defaultBehaviorIdentity)
                == .starKeyPuffSpawner,
            "star-key puff spawner identity route"
        )
        let starKeyPuffTick = starKeyPuffBridge.tick(state: starKeyPuffEngine)
        require(
            starKeyPuffTick.starKeyPuffSpawnerEffects.count == 1
                && starKeyPuffTick.starKeyPuffSpawnerEffects[0].objectID == starKeyPuffSpawner
                && starKeyPuffTick.starKeyPuffSpawnerEffects[0].spawnedPuffs.count == 20
                && starKeyPuffTick.whitePuffExplosionEffects.count == 20
                && starKeyPuffEngine.objects.record(for: starKeyPuffSpawner) == nil,
            "star-key puff parent/child allocation and teardown are preserved"
        )

        let staticFlameEngine = SM64SwiftEngineState(objectCapacity: 8)
        let staticFlameBridge = SM64BehaviorDispatchBridge()
        let staticFlame = try staticFlameBridge.spawnStaticFlame(
            in: staticFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlameObjectBridge.defaultBehaviorIdentity) == .staticFlame,
            "static flame identity route"
        )
        let staticFlameTick = staticFlameBridge.tick(state: staticFlameEngine)
        require(
            staticFlameTick.staticFlameEffects.count == 1
                && staticFlameTick.staticFlameEffects[0].objectID == staticFlame
                && staticFlameTick.staticFlameEffects[0].output.animationState == 1
                && staticFlameEngine.objects.record(for: staticFlame)?.interactionType == 1
                && staticFlameEngine.objects.record(for: staticFlame)?.scale == .init(x: 7, y: 7, z: 7),
            "static flame interaction/animation route is preserved"
        )

        let flamethrowerEngine = SM64SwiftEngineState(objectCapacity: 8)
        let flamethrowerBridge = SM64BehaviorDispatchBridge()
        let flamethrowerFlame = try flamethrowerBridge.spawnFlamethrowerFlame(
            in: flamethrowerEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            forwardVelocity: 20,
            behaviorParam: 2,
            initialOffset: SM64ObjectVector3(x: 1, y: 2, z: 3),
            initialAnimationState: 3
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlamethrowerFlameObjectBridge.defaultBehaviorIdentity)
                == .flamethrowerFlame,
            "flamethrower flame identity route"
        )
        let flamethrowerTick = flamethrowerBridge.tick(state: flamethrowerEngine)
        require(
            flamethrowerTick.flamethrowerFlameEffects.count == 1
                && flamethrowerTick.flamethrowerFlameEffects[0].objectID == flamethrowerFlame
                && flamethrowerTick.flamethrowerFlameEffects[0].output.position == .init(x: 11, y: 22, z: 19)
                && flamethrowerTick.flamethrowerFlameEffects[0].output.scale == 2
                && flamethrowerTick.flamethrowerFlameEffects[0].output.animationState == 4,
            "flamethrower flame sizing/movement route is preserved"
        )

        let bouncingFlameEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bouncingFlameBridge = SM64BehaviorDispatchBridge()
        let bouncingFlame = try bouncingFlameBridge.spawnFlameBouncing(
            in: bouncingFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            initialScale: 2
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlameBouncingObjectBridge.defaultBehaviorIdentity)
                == .flameBouncing,
            "bouncing flame identity route"
        )
        let bouncingFlameTick = bouncingFlameBridge.tick(state: bouncingFlameEngine)
        require(
            bouncingFlameTick.flameBouncingEffects.count == 1
                && bouncingFlameTick.flameBouncingEffects[0].objectID == bouncingFlame
                && bouncingFlameTick.flameBouncingEffects[0].output.position == .init(x: 10, y: 49, z: 11)
                && bouncingFlameTick.flameBouncingEffects[0].output.forwardVelocity == 15,
            "bouncing flame movement route is preserved"
        )

        let bowserFlameEngine = SM64SwiftEngineState(objectCapacity: 16)
        let bowserFlameBridge = SM64BehaviorDispatchBridge()
        let bowserFlame = try bowserFlameBridge.spawnBowserFlame(
            in: bowserFlameEngine,
            kind: .normal,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            forwardVelocity: 10,
            velocityY: 20,
            scaleFactor: 2
        )
        let largeBowserFlame = try bowserFlameBridge.spawnBowserFlame(
            in: bowserFlameEngine,
            kind: .largeBurningOut,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BowserFlameObjectBridge.normalBehaviorIdentity) == .flameBowser
                && SM64BehaviorDispatchBridge.route(for: SM64BowserFlameObjectBridge.largeBurningOutBehaviorIdentity) == .flameLargeBurningOut,
            "Bowser flame identities route"
        )
        let bowserFlameTick = bowserFlameBridge.tick(state: bowserFlameEngine)
        require(
            bowserFlameTick.flameBowserEffects.count == 2
                && bowserFlameTick.flameBowserEffects.contains { $0.objectID == bowserFlame && $0.output.position == .init(x: 10, y: 39, z: 6) && $0.output.scaleFactor == 2 }
                && bowserFlameTick.flameBowserEffects.contains { $0.objectID == largeBowserFlame },
            "Bowser flame shared loop route is preserved"
        )

        let blueFlamesEngine = SM64SwiftEngineState(objectCapacity: 32)
        let blueFlamesBridge = SM64BehaviorDispatchBridge()
        let blueFlames = try blueFlamesBridge.spawnBlueFlamesGroup(
            in: blueFlamesEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            scale: 5
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlueFlamesGroupObjectBridge.defaultBehaviorIdentity)
                == .blueFlamesGroup,
            "blue-flames group identity route"
        )
        let blueFlamesTick = blueFlamesBridge.tick(state: blueFlamesEngine)
        require(
            blueFlamesTick.blueFlamesGroupEffects.count == 1
                && blueFlamesTick.blueFlamesGroupEffects[0].objectID == blueFlames
                && blueFlamesTick.blueFlamesGroupEffects[0].spawnedFlames.count == 3
                && blueFlamesTick.flameBouncingEffects.count == 3
                && blueFlamesEngine.objects.record(for: blueFlames) != nil,
            "blue-flames group parent/child burst route is preserved"
        )
        for _ in 0..<16 { _ = blueFlamesBridge.tick(state: blueFlamesEngine) }
        require(blueFlamesEngine.objects.record(for: blueFlames) == nil, "blue-flames group sixteen-frame teardown is preserved")

        let blueBowserEngine = SM64SwiftEngineState(objectCapacity: 32)
        let blueBowserBridge = SM64BehaviorDispatchBridge()
        let blueBowser = try blueBowserBridge.spawnBlueBowserFlame(
            in: blueBowserEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            behaviorParam: 0
        )
        let floatingLanding = try blueBowserBridge.spawnFlameFloatingLanding(
            in: blueBowserEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            behaviorParam: 0,
            scale: 5
        )
        _ = blueBowserEngine.objects.mutate(floatingLanding) { record in record.moveFlags |= 1 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlueBowserFlameObjectBridge.defaultBehaviorIdentity) == .blueBowserFlame
                && SM64BehaviorDispatchBridge.route(for: SM64FlameFloatingLandingObjectBridge.defaultBehaviorIdentity) == .flameFloatingLanding,
            "blue Bowser/floating landing identities route"
        )
        let blueBowserTick = blueBowserBridge.tick(state: blueBowserEngine)
        require(
            blueBowserTick.blueBowserFlameEffects.count == 1
                && blueBowserTick.blueBowserFlameEffects[0].objectID == blueBowser
                && blueBowserTick.flameFloatingLandingEffects.count == 1
                && blueBowserTick.flameFloatingLandingEffects[0].objectID == floatingLanding
                && blueBowserTick.flameFloatingLandingEffects[0].spawnedChild != nil
                && blueBowserEngine.objects.record(for: floatingLanding) == nil,
            "blue Bowser/floating landing child route is preserved"
        )

        let volcanoFlameEngine = SM64SwiftEngineState(objectCapacity: 8)
        let volcanoFlameBridge = SM64BehaviorDispatchBridge()
        let volcanoFlame = try volcanoFlameBridge.spawnVolcanoFlames(
            in: volcanoFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            forwardVelocity: 2,
            gravity: -4
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64VolcanoFlamesObjectBridge.defaultBehaviorIdentity) == .volcanoFlames,
            "volcano flame identity route"
        )
        let volcanoFlameTick = volcanoFlameBridge.tick(state: volcanoFlameEngine)
        require(
            volcanoFlameTick.volcanoFlamesEffects.count == 1
                && volcanoFlameTick.volcanoFlamesEffects[0].objectID == volcanoFlame
                && volcanoFlameTick.volcanoFlamesEffects[0].output.position == .init(x: 10, y: 16, z: -2),
            "volcano flame movement route is preserved"
        )

        let koopaFlameEngine = SM64SwiftEngineState(objectCapacity: 8)
        let koopaFlameBridge = SM64BehaviorDispatchBridge()
        let koopaFlame = try koopaFlameBridge.spawnKoopaShellFlame(
            in: koopaFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            forwardVelocity: 4,
            gravity: -4,
            initialOffset: SM64ObjectVector3(x: 1, y: 2, z: 3),
            initialAnimationState: 2
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64KoopaShellFlameObjectBridge.defaultBehaviorIdentity) == .koopaShellFlame,
            "Koopa-shell flame identity route"
        )
        let koopaFlameTick = koopaFlameBridge.tick(state: koopaFlameEngine)
        require(
            koopaFlameTick.koopaShellFlameEffects.count == 1
                && koopaFlameTick.koopaShellFlameEffects[0].objectID == koopaFlame
                && koopaFlameTick.koopaShellFlameEffects[0].output.position == .init(x: 11, y: 18, z: 3)
                && koopaFlameTick.koopaShellFlameEffects[0].output.scale == 3.7,
            "Koopa-shell flame movement/scale route is preserved"
        )

        let growingFlameEngine = SM64SwiftEngineState(objectCapacity: 16)
        let growingFlameBridge = SM64BehaviorDispatchBridge()
        let growingFlame = try growingFlameBridge.spawnFlameMovingForwardGrowing(
            in: growingFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            forwardVelocity: 30,
            initialOffset: SM64ObjectVector3(x: 1, y: 0, z: 2),
            initialAnimationState: 3
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlameMovingForwardGrowingObjectBridge.defaultBehaviorIdentity) == .flameMovingForwardGrowing,
            "moving/growing flame identity route"
        )
        let growingFlameTick = growingFlameBridge.tick(state: growingFlameEngine)
        require(
            growingFlameTick.flameMovingForwardGrowingEffects.count == 1
                && growingFlameTick.flameMovingForwardGrowingEffects[0].objectID == growingFlame
                && growingFlameTick.flameMovingForwardGrowingEffects[0].output.position == .init(x: 11, y: 20, z: 28)
                && growingFlameTick.flameMovingForwardGrowingEffects[0].output.scaleFactor == 3.5,
            "moving/growing flame movement route is preserved"
        )

        let betaFlameEngine = SM64SwiftEngineState(objectCapacity: 32)
        let betaFlameBridge = SM64BehaviorDispatchBridge()
        let betaFlameSpawner = try betaFlameBridge.spawnBetaMovingFlames(
            in: betaFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BetaMovingFlamesObjectBridge.spawnBehaviorIdentity) == .betaMovingFlamesSpawn
                && SM64BehaviorDispatchBridge.route(for: SM64BetaMovingFlamesObjectBridge.flameBehaviorIdentity) == .betaMovingFlames,
            "Beta moving-flame identities route"
        )
        let betaFlameTick = betaFlameBridge.tick(state: betaFlameEngine)
        require(
            betaFlameTick.betaMovingFlamesSpawnEffects.count == 1
                && betaFlameTick.betaMovingFlamesSpawnEffects[0].objectID == betaFlameSpawner
                && betaFlameTick.betaMovingFlamesSpawnEffects[0].spawnedChild != nil
                && betaFlameTick.betaMovingFlamesEffects.isEmpty,
            "Beta moving-flame parent/child route is preserved"
        )
        let betaFlameChildTick = betaFlameBridge.tick(state: betaFlameEngine)
        require(betaFlameChildTick.betaMovingFlamesEffects.count == 1, "Beta moving-flame child updates on its owning list")

        let bowserSpawnEngine = SM64SwiftEngineState(objectCapacity: 32)
        let bowserSpawnBridge = SM64BehaviorDispatchBridge()
        let bowserObjectForSpawn = try bowserSpawnEngine.spawnObject(in: .generalActor, behaviorIdentity: 0xB0)
        _ = bowserSpawnEngine.objects.mutate(bowserObjectForSpawn) { record in
            record.position = SM64ObjectVector3(x: 10, y: 20, z: -4)
            record.moveAngles.yaw = 0
            record.soundStateID = 6
        }
        let bowserSpawner = try bowserSpawnBridge.spawnBowserFlameSpawn(in: bowserSpawnEngine, bowserObject: bowserObjectForSpawn, sampleX: 1, sampleY: 2, sampleZ: 3, samplePitch: 4, sampleYaw: 5)
        _ = bowserSpawnEngine.objects.mutate(bowserSpawner) { record in record.animationState = 49 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BowserFlameSpawnObjectBridge.defaultBehaviorIdentity) == .bowserFlameSpawn,
            "Bowser flame spawner identity route"
        )
        let bowserSpawnTick = bowserSpawnBridge.tick(state: bowserSpawnEngine)
        require(
            bowserSpawnTick.bowserFlameSpawnEffects.count == 1
                && bowserSpawnTick.bowserFlameSpawnEffects[0].objectID == bowserSpawner
                && bowserSpawnTick.bowserFlameSpawnEffects[0].output.shouldSpawnFlame
                && bowserSpawnTick.bowserFlameSpawnEffects[0].spawnedFlame != nil,
            "Bowser flame trajectory child spawn route is preserved"
        )

        let piranhaFlameEngine = SM64SwiftEngineState(objectCapacity: 32)
        let piranhaFlameBridge = SM64BehaviorDispatchBridge()
        let piranhaFlame = try piranhaFlameBridge.spawnSmallPiranhaFlame(
            in: piranhaFlameEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            mode: .ephemeral,
            scale: 2,
            randomScaleJitter: 0,
            initialAnimationState: 3
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SmallPiranhaFlameObjectBridge.defaultBehaviorIdentity) == .smallPiranhaFlame,
            "small Piranha flame identity route"
        )
        let piranhaFlameTick = piranhaFlameBridge.tick(state: piranhaFlameEngine)
        require(
            piranhaFlameTick.smallPiranhaFlameEffects.count == 1
                && piranhaFlameTick.smallPiranhaFlameEffects[0].objectID == piranhaFlame
                && piranhaFlameTick.smallPiranhaFlameEffects[0].output.scaleX == 1.8
                && piranhaFlameTick.smallPiranhaFlameEffects[0].output.animationState == 3,
            "small Piranha flame decorative mode is preserved"
        )

        let fireSpitterEngine = SM64SwiftEngineState(objectCapacity: 16)
        let fireSpitterBridge = SM64BehaviorDispatchBridge()
        let fireSpitter = try fireSpitterBridge.spawnFireSpitter(
            in: fireSpitterEngine,
            distanceToMario: 500,
            targetYaw: 0x2000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FireSpitterObjectBridge.defaultBehaviorIdentity) == .fireSpitter,
            "fire-spitter identity route"
        )
        let fireSpitterTick = fireSpitterBridge.tick(state: fireSpitterEngine)
        require(
            fireSpitterTick.fireSpitterEffects.count == 1
                && fireSpitterTick.fireSpitterEffects[0].objectID == fireSpitter
                && fireSpitterTick.fireSpitterEffects[0].output.action == 0
                && fireSpitterTick.fireSpitterEffects[0].output.scale == 0.998,
            "fire-spitter idle scaling route is preserved"
        )

        let firePiranhaEngine = SM64SwiftEngineState(objectCapacity: 16)
        let firePiranhaBridge = SM64BehaviorDispatchBridge()
        let firePiranha = try firePiranhaBridge.spawnFirePiranhaPlant(
            in: firePiranhaEngine,
            behaviorVariant: 0,
            distanceToMario: 300
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FirePiranhaPlantObjectBridge.defaultBehaviorIdentity) == .firePiranhaPlant,
            "fire Piranha Plant identity route"
        )
        _ = firePiranhaEngine.objects.mutate(firePiranha) { record in record.timer = 101; record.angleToMario = 0x2000 }
        let firePiranhaTick = firePiranhaBridge.tick(state: firePiranhaEngine)
        require(
            firePiranhaTick.firePiranhaPlantEffects.count == 1
                && firePiranhaTick.firePiranhaPlantEffects[0].objectID == firePiranha
                && firePiranhaTick.firePiranhaPlantEffects[0].output.action == .grow
                && firePiranhaTick.firePiranhaPlantEffects[0].output.active,
            "fire Piranha Plant activation route is preserved"
        )

        let flamethrowerParentEngine = SM64SwiftEngineState(objectCapacity: 16)
        let flamethrowerParentBridge = SM64BehaviorDispatchBridge()
        let flamethrowerParent = try flamethrowerParentBridge.spawnFlamethrower(
            in: flamethrowerParentEngine,
            behaviorParam: 0,
            distanceToMario: 1000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FlamethrowerObjectBridge.defaultBehaviorIdentity) == .flamethrower,
            "flamethrower parent identity route"
        )
        let flamethrowerParentTick = flamethrowerParentBridge.tick(state: flamethrowerParentEngine)
        require(
            flamethrowerParentTick.flamethrowerEffects.count == 1
                && flamethrowerParentTick.flamethrowerEffects[0].objectID == flamethrowerParent
                && flamethrowerParentTick.flamethrowerEffects[0].output.action == 1
                && !flamethrowerParentTick.flamethrowerEffects[0].output.spawnFlame,
            "flamethrower parent activation route is preserved"
        )

        let sparkleEngine = SM64SwiftEngineState(objectCapacity: 8)
        let sparkleBridge = SM64BehaviorDispatchBridge()
        let sparkle = try sparkleBridge.spawnCelebrationStarSparkle(
            in: sparkleEngine,
            position: SM64ObjectVector3(x: 10, y: 100, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CelebrationStarSparkleObjectBridge.defaultBehaviorIdentity) == .celebrationStarSparkle,
            "celebration-star sparkle identity route"
        )
        let sparkleTick = sparkleBridge.tick(state: sparkleEngine)
        require(
            sparkleTick.celebrationStarSparkleEffects.count == 1
                && sparkleTick.celebrationStarSparkleEffects[0].objectID == sparkle
                && sparkleTick.celebrationStarSparkleEffects[0].output.position == .init(x: 10, y: 85, z: -4),
            "celebration-star sparkle movement route is preserved"
        )

        let groundParticleEngine = SM64SwiftEngineState(objectCapacity: 32)
        let groundParticleBridge = SM64BehaviorDispatchBridge()
        let dirtSpawner = try groundParticleBridge.spawnGroundParticleSpawner(
            in: groundParticleEngine,
            kind: .dirt,
            activeParticleFlags: 0x4000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64GroundParticleSpawnerObjectBridge.dirtBehaviorIdentity) == .dirtParticleSpawner
                && SM64BehaviorDispatchBridge.route(for: SM64GroundParticleSpawnerObjectBridge.snowBehaviorIdentity) == .snowParticleSpawner,
            "ground particle spawner identities route"
        )
        let groundParticleTick = groundParticleBridge.tick(state: groundParticleEngine)
        require(
            groundParticleTick.groundParticleSpawnerEffects.count == 1
                && groundParticleTick.groundParticleSpawnerEffects[0].objectID == dirtSpawner
                && groundParticleTick.groundParticleSpawnerEffects[0].spawnedChildren.count == 4
                && groundParticleEngine.objects.record(for: dirtSpawner) != nil,
            "ground particle spawner allocation/teardown route is preserved"
        )
        _ = groundParticleBridge.tick(state: groundParticleEngine)
        require(groundParticleEngine.objects.record(for: dirtSpawner) == nil, "ground particle spawner delay teardown is preserved")

        let animatedTextureEngine = SM64SwiftEngineState(objectCapacity: 8)
        let animatedTextureBridge = SM64BehaviorDispatchBridge()
        let animatedTexture = try animatedTextureBridge.spawnAnimatedTexture(
            in: animatedTextureEngine,
            position: SM64ObjectVector3(x: 1, y: 2, z: 3),
            animationState: 5
        )
        _ = animatedTextureEngine.objects.mutate(animatedTexture) { record in
            record.position = SM64ObjectVector3(x: 100, y: 200, z: 300)
        }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64AnimatedTextureObjectBridge.defaultBehaviorIdentity) == .animatedTexture,
            "animated texture identity route"
        )
        let animatedTextureTick = animatedTextureBridge.tick(state: animatedTextureEngine)
        require(
            animatedTextureTick.animatedTextureEffects.count == 1
                && animatedTextureTick.animatedTextureEffects[0].objectID == animatedTexture
                && animatedTextureTick.animatedTextureEffects[0].output.position == .init(x: 1, y: 2, z: 3)
                && animatedTextureTick.animatedTextureEffects[0].output.animationState == 6,
            "animated texture home snap and cadence route are preserved"
        )

        let rawSparkleEngine = SM64SwiftEngineState(objectCapacity: 8)
        let rawSparkleBridge = SM64BehaviorDispatchBridge()
        let rawSparkle = try rawSparkleBridge.spawnSparkle(
            in: rawSparkleEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SparkleObjectBridge.defaultBehaviorIdentity) == .sparkle,
            "sparkle identity route"
        )
        let rawSparkleTick = rawSparkleBridge.tick(state: rawSparkleEngine)
        require(
            rawSparkleTick.sparkleEffects.count == 1
                && rawSparkleTick.sparkleEffects[0].objectID == rawSparkle
                && rawSparkleTick.sparkleEffects[0].output.animationState == 8
                && rawSparkleTick.sparkleEffects[0].output.shouldDeactivate
                && rawSparkleEngine.objects.record(for: rawSparkle) == nil,
            "sparkle animation/deactivation route is preserved"
        )

        let sparkleSpawnerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let sparkleSpawnerBridge = SM64BehaviorDispatchBridge()
        let sparkleSpawner = try sparkleSpawnerBridge.spawnSparkleSpawner(
            in: sparkleSpawnerEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            randomOffset: SM64ObjectVector3(x: 1, y: 2, z: 3),
            randomScale: 0.5
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SparkleSpawnerObjectBridge.defaultBehaviorIdentity) == .sparkleSpawner,
            "sparkle spawner identity route"
        )
        let sparkleSpawnerTick = sparkleSpawnerBridge.tick(state: sparkleSpawnerEngine)
        require(
            sparkleSpawnerTick.sparkleSpawnerEffects.count == 1
                && sparkleSpawnerTick.sparkleSpawnerEffects[0].objectID == sparkleSpawner
                && sparkleSpawnerTick.sparkleSpawnerEffects[0].output.childPosition == .init(x: 11, y: 22, z: -1)
                && sparkleSpawnerTick.sparkleSpawnerEffects[0].output.childScale == 0.5
                && sparkleSpawnerTick.sparkleSpawnerEffects[0].spawnedSparkle != nil
                && sparkleSpawnerEngine.objects.record(for: sparkleSpawner) != nil,
            "sparkle spawner child allocation route is preserved"
        )
        _ = sparkleSpawnerBridge.tick(state: sparkleSpawnerEngine)
        _ = sparkleSpawnerBridge.tick(state: sparkleSpawnerEngine)
        require(sparkleSpawnerEngine.objects.record(for: sparkleSpawner) == nil, "sparkle spawner timer teardown is preserved")

        let ambientSoundsEngine = SM64SwiftEngineState(objectCapacity: 8)
        let ambientSoundsBridge = SM64BehaviorDispatchBridge()
        let ambientSounds = try ambientSoundsBridge.spawnAmbientSounds(
            in: ambientSoundsEngine,
            cameraBehindMario: false
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64AmbientSoundsObjectBridge.defaultBehaviorIdentity) == .ambientSounds,
            "ambient sounds identity route"
        )
        let ambientSoundsTick = ambientSoundsBridge.tick(state: ambientSoundsEngine)
        require(
            ambientSoundsTick.ambientSoundsEffects.count == 1
                && ambientSoundsTick.ambientSoundsEffects[0].objectID == ambientSounds
                && ambientSoundsTick.ambientSoundsEffects[0].output.playCastleOutdoorsAmbient,
            "ambient sounds camera gate route is preserved"
        )

        let coinSparklesEngine = SM64SwiftEngineState(objectCapacity: 16)
        let coinSparklesBridge = SM64BehaviorDispatchBridge()
        let coinSparkles = try coinSparklesBridge.spawnCoinSparkles(
            in: coinSparklesEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CoinSparklesObjectBridge.defaultBehaviorIdentity) == .coinSparkles,
            "coin sparkles identity route"
        )
        let coinSparklesTick = coinSparklesBridge.tick(state: coinSparklesEngine)
        require(
            coinSparklesTick.coinSparklesEffects.count == 1
                && coinSparklesTick.coinSparklesEffects[0].objectID == coinSparkles
                && coinSparklesTick.coinSparklesEffects[0].output.animationState == 7
                && coinSparklesTick.coinSparklesEffects[0].output.scale == 0.6
                && coinSparklesEngine.objects.record(for: coinSparkles) == nil,
            "coin sparkles animation/deactivation route is preserved"
        )

        let goldenCoinSparklesEngine = SM64SwiftEngineState(objectCapacity: 32)
        let goldenCoinSparklesBridge = SM64BehaviorDispatchBridge()
        let goldenCoinSparkles = try goldenCoinSparklesBridge.spawnGoldenCoinSparkles(
            in: goldenCoinSparklesEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            randomOffsets: [
                .init(x: 1, y: 0, z: 2),
                .init(x: -3, y: 0, z: 4),
                .init(x: 5, y: 0, z: -6),
            ]
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64GoldenCoinSparklesObjectBridge.defaultBehaviorIdentity) == .goldenCoinSparkles,
            "golden coin sparkles identity route"
        )
        let goldenCoinSparklesTick = goldenCoinSparklesBridge.tick(state: goldenCoinSparklesEngine)
        require(
            goldenCoinSparklesTick.goldenCoinSparklesEffects.count == 1
                && goldenCoinSparklesTick.goldenCoinSparklesEffects[0].objectID == goldenCoinSparkles
                && goldenCoinSparklesTick.goldenCoinSparklesEffects[0].spawnedChildren.count == 3
                && goldenCoinSparklesTick.goldenCoinSparklesEffects[0].output.childPositions == [
                    .init(x: 11, y: 20, z: -2),
                    .init(x: 7, y: 20, z: 0),
                    .init(x: 15, y: 20, z: -10),
                ]
                && goldenCoinSparklesEngine.objects.record(for: goldenCoinSparkles) == nil,
            "golden coin sparkle child allocation/teardown route is preserved"
        )

        let purpleParticleEngine = SM64SwiftEngineState(objectCapacity: 16)
        let purpleParticleBridge = SM64BehaviorDispatchBridge()
        let purpleParticle = try purpleParticleBridge.spawnPurpleParticle(
            in: purpleParticleEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            moveYaw: 0x4000,
            randomForwardUnit: 0.5,
            randomVerticalUnit: 0.25
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64PurpleParticleObjectBridge.defaultBehaviorIdentity) == .purpleParticle,
            "purple particle identity route"
        )
        let purpleParticleTick = purpleParticleBridge.tick(state: purpleParticleEngine)
        require(
            purpleParticleTick.purpleParticleEffects.count == 1
                && purpleParticleTick.purpleParticleEffects[0].objectID == purpleParticle
                && purpleParticleTick.purpleParticleEffects[0].output.forwardVelocity == 30
                && purpleParticleTick.purpleParticleEffects[0].output.velocityY == 25
                && !purpleParticleTick.purpleParticleEffects[0].output.shouldDeactivate,
            "purple particle random velocity/movement route is preserved"
        )
        for _ in 0..<9 { _ = purpleParticleBridge.tick(state: purpleParticleEngine) }
        require(purpleParticleEngine.objects.record(for: purpleParticle) == nil, "purple particle ten-frame teardown is preserved")

        let tinyStarParticleEngine = SM64SwiftEngineState(objectCapacity: 16)
        let tinyStarParticleBridge = SM64BehaviorDispatchBridge()
        let wallTinyStar = try tinyStarParticleBridge.spawnTinyStarParticle(
            in: tinyStarParticleEngine,
            kind: .wall,
            position: .zero,
            marioPosition: SM64ObjectVector3(x: 100, y: 50, z: -20),
            marioYaw: 0,
            moveYaw: 0,
            forwardVelocity: 25,
            velocityY: 10
        )
        let poundTinyStar = try tinyStarParticleBridge.spawnTinyStarParticle(
            in: tinyStarParticleEngine,
            kind: .pound,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            moveYaw: 0,
            forwardVelocity: 0,
            velocityY: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TinyStarParticleObjectBridge.wallBehaviorIdentity) == .wallTinyStarParticle
                && SM64BehaviorDispatchBridge.route(for: SM64TinyStarParticleObjectBridge.poundBehaviorIdentity) == .poundTinyStarParticle,
            "tiny star particle identities route"
        )
        let tinyStarParticleTick = tinyStarParticleBridge.tick(state: tinyStarParticleEngine)
        require(
            tinyStarParticleTick.tinyStarParticleEffects.count == 2
                && tinyStarParticleTick.tinyStarParticleEffects.contains(where: { $0.objectID == wallTinyStar && $0.output.position == .init(x: 100, y: 90, z: 115) })
                && tinyStarParticleTick.tinyStarParticleEffects.contains(where: { $0.objectID == poundTinyStar && $0.output.position == .init(x: 10, y: 14, z: 21) && $0.output.forwardVelocity == 25 }),
            "tiny star particle placement/movement route is preserved"
        )
        for _ in 0..<9 { _ = tinyStarParticleBridge.tick(state: tinyStarParticleEngine) }
        require(
            tinyStarParticleEngine.objects.record(for: wallTinyStar) == nil
                && tinyStarParticleEngine.objects.record(for: poundTinyStar) == nil,
            "tiny star particle ten-frame teardown is preserved"
        )

        let tinyStarSpawnerEngine = SM64SwiftEngineState(objectCapacity: 32)
        let tinyStarSpawnerBridge = SM64BehaviorDispatchBridge()
        let verticalStarSpawner = try tinyStarSpawnerBridge.spawnTinyStarParticleSpawner(
            in: tinyStarSpawnerEngine,
            kind: .vertical,
            activeParticleFlags: 0x2000,
            particleFlag: 0x2000,
            seeds: [
                .init(moveYaw: 0, forwardVelocity: 25, velocityY: 10),
                .init(moveYaw: 0x4000, forwardVelocity: 20, velocityY: 15),
            ],
            marioPosition: .init(x: 100, y: 50, z: -20)
        )
        let horizontalStarSpawner = try tinyStarSpawnerBridge.spawnTinyStarParticleSpawner(
            in: tinyStarSpawnerEngine,
            kind: .horizontal,
            activeParticleFlags: 0x8000,
            particleFlag: 0x8000,
            seeds: [.init(moveYaw: 0, forwardVelocity: 25, velocityY: 14)]
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TinyStarParticleSpawnerObjectBridge.verticalBehaviorIdentity) == .vertStarParticleSpawner
                && SM64BehaviorDispatchBridge.route(for: SM64TinyStarParticleSpawnerObjectBridge.horizontalBehaviorIdentity) == .horStarParticleSpawner,
            "tiny star particle spawner identities route"
        )
        let tinyStarSpawnerTick = tinyStarSpawnerBridge.tick(state: tinyStarSpawnerEngine)
        require(
            tinyStarSpawnerTick.tinyStarParticleSpawnerEffects.count == 2
                && tinyStarSpawnerTick.tinyStarParticleSpawnerEffects.contains(where: { $0.objectID == verticalStarSpawner && $0.spawnedChildren.count == 2 && $0.output.clearParticleFlag })
                && tinyStarSpawnerTick.tinyStarParticleSpawnerEffects.contains(where: { $0.objectID == horizontalStarSpawner && $0.spawnedChildren.count == 1 && $0.output.clearParticleFlag })
                && tinyStarSpawnerEngine.objects.record(for: verticalStarSpawner) != nil
                && tinyStarSpawnerEngine.objects.record(for: horizontalStarSpawner) != nil,
            "tiny star particle spawner child allocation/flag clearing is preserved"
        )
        _ = tinyStarSpawnerBridge.tick(state: tinyStarSpawnerEngine)
        require(
            tinyStarSpawnerEngine.objects.record(for: verticalStarSpawner) == nil
                && tinyStarSpawnerEngine.objects.record(for: horizontalStarSpawner) == nil,
            "tiny star particle spawner delay teardown is preserved"
        )

        let triangleParticleEngine = SM64SwiftEngineState(objectCapacity: 32)
        let triangleParticleBridge = SM64BehaviorDispatchBridge()
        let triangleParticle = try triangleParticleBridge.spawnTriangleParticle(
            in: triangleParticleEngine,
            marioPosition: SM64ObjectVector3(x: 100, y: 50, z: -20),
            moveYaw: 0,
            forwardVelocity: 25,
            velocityY: 14
        )
        let triangleSpawner = try triangleParticleBridge.spawnTriangleParticleSpawner(
            in: triangleParticleEngine,
            activeParticleFlags: 0x8000,
            particleFlag: 0x8000,
            seeds: [.init(moveYaw: 0, forwardVelocity: 25, velocityY: 14)],
            marioPosition: SM64ObjectVector3(x: 100, y: 50, z: -20)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TriangleParticleObjectBridge.defaultBehaviorIdentity) == .triangleParticle
                && SM64BehaviorDispatchBridge.route(for: SM64TriangleParticleSpawnerObjectBridge.defaultBehaviorIdentity) == .triangleParticleSpawner,
            "triangle particle identities route"
        )
        let triangleParticleTick = triangleParticleBridge.tick(state: triangleParticleEngine)
        require(
            triangleParticleTick.triangleParticleEffects.contains(where: { $0.objectID == triangleParticle && $0.output.position == .init(x: 100, y: 124, z: 105) })
                && triangleParticleTick.triangleParticleSpawnerEffects.count == 1
                && triangleParticleTick.triangleParticleSpawnerEffects[0].objectID == triangleSpawner
                && triangleParticleTick.triangleParticleSpawnerEffects[0].spawnedChildren.count == 1
                && triangleParticleTick.triangleParticleSpawnerEffects[0].output.clearParticleFlag
                && triangleParticleEngine.objects.record(for: triangleSpawner) != nil,
            "triangle particle placement/spawner route is preserved"
        )
        _ = triangleParticleBridge.tick(state: triangleParticleEngine)
        require(triangleParticleEngine.objects.record(for: triangleSpawner) == nil, "triangle particle spawner delay teardown is preserved")

        let treeLeafEngine = SM64SwiftEngineState(objectCapacity: 16)
        let treeLeafBridge = SM64BehaviorDispatchBridge()
        let treeLeaf = try treeLeafBridge.spawnTreeLeaf(
            in: treeLeafEngine,
            position: SM64ObjectVector3(x: 10, y: 100, z: -4),
            floorHeight: 0,
            phase: 0x4000,
            phaseRate: 0x800,
            forwardVelocity: 5,
            velocityY: 15
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TreeLeafObjectBridge.defaultBehaviorIdentity) == .treeLeaf,
            "tree leaf identity route"
        )
        let treeLeafTick = treeLeafBridge.tick(state: treeLeafEngine)
        require(
            treeLeafTick.treeLeafEffects.count == 1
                && treeLeafTick.treeLeafEffects[0].objectID == treeLeaf
                && treeLeafTick.treeLeafEffects[0].output.position == .init(x: 10, y: 112, z: 0)
                && treeLeafTick.treeLeafEffects[0].output.forwardVelocity == 4.7,
            "tree leaf phase/gravity movement route is preserved"
        )

        let treeSpawnerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let treeSpawnerBridge = SM64BehaviorDispatchBridge()
        let treeSpawner = try treeSpawnerBridge.spawnTreeParticleSpawner(
            in: treeSpawnerEngine,
            activeParticleFlags: 0x2000,
            particleFlag: 0x2000,
            snowMode: false,
            spawnDecision: 0.2,
            randomScale: 0.5,
            randomYaw: 0x4000,
            randomForwardUnit: 0.4,
            randomVerticalUnit: 0.5,
            randomFacePitch: 100,
            randomFaceRoll: 200
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TreeParticleSpawnerObjectBridge.defaultBehaviorIdentity) == .treeParticleSpawner,
            "tree particle spawner identity route"
        )
        let treeSpawnerTick = treeSpawnerBridge.tick(state: treeSpawnerEngine)
        require(
            treeSpawnerTick.treeParticleSpawnerEffects.count == 1
                && treeSpawnerTick.treeParticleSpawnerEffects[0].objectID == treeSpawner
                && treeSpawnerTick.treeParticleSpawnerEffects[0].output.childKind == .leaf
                && treeSpawnerTick.treeParticleSpawnerEffects[0].output.childScale == 1.5
                && treeSpawnerTick.treeParticleSpawnerEffects[0].spawnedChild != nil
                && treeSpawnerTick.treeParticleSpawnerEffects[0].output.clearParticleFlag
                && treeSpawnerEngine.objects.record(for: treeSpawner) != nil,
            "tree particle spawner randomized child/flag route is preserved"
        )
        _ = treeSpawnerBridge.tick(state: treeSpawnerEngine)
        require(treeSpawnerEngine.objects.record(for: treeSpawner) == nil, "tree particle spawner delay teardown is preserved")

        let mistCircEngine = SM64SwiftEngineState(objectCapacity: 64)
        let mistCircBridge = SM64BehaviorDispatchBridge()
        let mistCirc = try mistCircBridge.spawnMistCircParticleSpawner(
            in: mistCircEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            activeParticleFlags: 0x8000,
            particleFlag: 0x8000,
            seeds: [.init(randomScaleUnit: 0.5, randomYaw: 0, randomForwardUnit: 0.4)]
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64MistCircParticleSpawnerObjectBridge.defaultBehaviorIdentity) == .mistCircParticleSpawner,
            "mist-circle particle spawner identity route"
        )
        let mistCircTick = mistCircBridge.tick(state: mistCircEngine)
        require(
            mistCircTick.mistCircParticleSpawnerEffects.count == 1
                && mistCircTick.mistCircParticleSpawnerEffects[0].objectID == mistCirc
                && mistCircTick.mistCircParticleSpawnerEffects[0].spawnedChildren.count == 1
                && mistCircTick.mistCircParticleSpawnerEffects[0].output.children[0].position == .init(x: 10, y: 40, z: -4)
                && mistCircTick.mistCircParticleSpawnerEffects[0].output.clearParticleFlag
                && mistCircEngine.objects.record(for: mistCirc) != nil,
            "mist-circle particle child allocation/flag route is preserved"
        )
        _ = mistCircBridge.tick(state: mistCircEngine)
        require(mistCircEngine.objects.record(for: mistCirc) == nil, "mist-circle particle spawner delay teardown is preserved")

        let sparkleParticleSpawnerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let sparkleParticleSpawnerBridge = SM64BehaviorDispatchBridge()
        let sparkleParticleSpawner = try sparkleParticleSpawnerBridge.spawnSparkleParticleSpawner(
            in: sparkleParticleSpawnerEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            activeParticleFlags: 0x800,
            particleFlag: 0x800,
            randomOffset: SM64ObjectVector3(x: 1, y: -2, z: 3)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SparkleParticleSpawnerObjectBridge.defaultBehaviorIdentity) == .sparkleParticleSpawner,
            "sparkle particle spawner identity route"
        )
        let sparkleParticleSpawnerTick = sparkleParticleSpawnerBridge.tick(state: sparkleParticleSpawnerEngine)
        require(
            sparkleParticleSpawnerTick.sparkleParticleSpawnerEffects.count == 1
                && sparkleParticleSpawnerTick.sparkleParticleSpawnerEffects[0].objectID == sparkleParticleSpawner
                && sparkleParticleSpawnerTick.sparkleParticleSpawnerEffects[0].output.position == .init(x: 11, y: 18, z: -1)
                && sparkleParticleSpawnerTick.sparkleParticleSpawnerEffects[0].output.animationState == 0
                && sparkleParticleSpawnerTick.sparkleParticleSpawnerEffects[0].output.clearParticleFlag,
            "sparkle particle spawner offset/animation/flag route is preserved"
        )

        let simpleAnimationEngine = SM64SwiftEngineState(objectCapacity: 16)
        let simpleAnimationBridge = SM64BehaviorDispatchBridge()
        let randomAnimatedTexture = try simpleAnimationBridge.spawnSimpleAnimation(in: simpleAnimationEngine, kind: .randomTexture)
        let unusedSimpleAnimation = try simpleAnimationBridge.spawnSimpleAnimation(in: simpleAnimationEngine, kind: .unusedSixFrame)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SimpleAnimationObjectBridge.randomTextureBehaviorIdentity) == .randomAnimatedTexture
                && SM64BehaviorDispatchBridge.route(for: SM64SimpleAnimationObjectBridge.unusedSixFrameBehaviorIdentity) == .unusedSimpleAnimation,
            "simple animation identities route"
        )
        let simpleAnimationTick = simpleAnimationBridge.tick(state: simpleAnimationEngine)
        require(
            simpleAnimationTick.simpleAnimationEffects.contains(where: { $0.objectID == randomAnimatedTexture && $0.output.animationState == 0 && $0.output.graphYOffset == -16 })
                && simpleAnimationTick.simpleAnimationEffects.contains(where: { $0.objectID == unusedSimpleAnimation && $0.output.animationState == 0 }),
            "simple animation progression route is preserved"
        )
        for _ in 0..<5 { _ = simpleAnimationBridge.tick(state: simpleAnimationEngine) }
        require(simpleAnimationEngine.objects.record(for: unusedSimpleAnimation) == nil, "unused simple animation teardown is preserved")

        let fakeStarEngine = SM64SwiftEngineState(objectCapacity: 8)
        let fakeStarBridge = SM64BehaviorDispatchBridge()
        let fakeStar = try fakeStarBridge.spawnUnusedFakeStar(in: fakeStarEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64UnusedFakeStarObjectBridge.defaultBehaviorIdentity) == .unusedFakeStar,
            "unused fake star identity route"
        )
        let fakeStarTick = fakeStarBridge.tick(state: fakeStarEngine)
        require(
            fakeStarTick.unusedFakeStarEffects.count == 1
                && fakeStarTick.unusedFakeStarEffects[0].objectID == fakeStar
                && fakeStarTick.unusedFakeStarEffects[0].output.facePitch == 0x100
                && fakeStarTick.unusedFakeStarEffects[0].output.faceYaw == 0x100,
            "unused fake star rotation route is preserved"
        )

        let cloudPartEngine = SM64SwiftEngineState(objectCapacity: 8)
        let cloudPartBridge = SM64BehaviorDispatchBridge()
        let cloudPart = try cloudPartBridge.spawnCloudPart(
            in: cloudPartEngine,
            parentCenterX: 100,
            parentCenterY: 50,
            parentPositionZ: -20,
            parentScale: 3,
            partIndex: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CloudPartObjectBridge.defaultBehaviorIdentity) == .cloudPart,
            "cloud part identity route"
        )
        let cloudPartTick = cloudPartBridge.tick(state: cloudPartEngine)
        require(
            cloudPartTick.cloudPartEffects.count == 1
                && cloudPartTick.cloudPartEffects[0].objectID == cloudPart
                && abs(cloudPartTick.cloudPartEffects[0].output.position.x - 104) < 0.1
                && abs(cloudPartTick.cloudPartEffects[0].output.position.y - 76) < 0.1
                && abs(cloudPartTick.cloudPartEffects[0].output.position.z - 34) < 0.1
                && cloudPartTick.cloudPartEffects[0].output.scaleY == 2,
            "cloud part transform/scale route is preserved"
        )

        let breakTriangleEngine = SM64SwiftEngineState(objectCapacity: 16)
        let breakTriangleBridge = SM64BehaviorDispatchBridge()
        let breakTriangle = try breakTriangleBridge.spawnBreakBoxTriangle(
            in: breakTriangleEngine,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            moveYaw: 0,
            forwardVelocity: 5,
            velocityY: 15,
            gravity: -1
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BreakBoxTriangleObjectBridge.defaultBehaviorIdentity) == .breakBoxTriangle,
            "break-box triangle identity route"
        )
        let breakTriangleTick = breakTriangleBridge.tick(state: breakTriangleEngine)
        require(
            breakTriangleTick.breakBoxTriangleEffects.count == 1
                && breakTriangleTick.breakBoxTriangleEffects[0].objectID == breakTriangle
                && breakTriangleTick.breakBoxTriangleEffects[0].output.position == .init(x: 10, y: 34, z: 1)
                && breakTriangleTick.breakBoxTriangleEffects[0].output.facePitch == 0x100,
            "break-box triangle physics/rotation route is preserved"
        )

        let cannonUnusedEngine = SM64SwiftEngineState(objectCapacity: 16)
        let cannonUnusedBridge = SM64BehaviorDispatchBridge()
        let cannonUnused = try cannonUnusedBridge.spawnCannonBaseUnused(in: cannonUnusedEngine, position: SM64ObjectVector3(x: 10, y: 20, z: -4), velocityY: 3)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CannonBaseUnusedObjectBridge.defaultBehaviorIdentity) == .cannonBaseUnused,
            "unused cannon base identity route"
        )
        let cannonUnusedTick = cannonUnusedBridge.tick(state: cannonUnusedEngine)
        require(
            cannonUnusedTick.cannonBaseUnusedEffects.count == 1
                && cannonUnusedTick.cannonBaseUnusedEffects[0].objectID == cannonUnused
                && cannonUnusedTick.cannonBaseUnusedEffects[0].output.position == .init(x: 10, y: 23, z: -4)
                && cannonUnusedTick.cannonBaseUnusedEffects[0].output.animationState == 0,
            "unused cannon base animation/vertical movement route is preserved"
        )

        let noOpEngine = SM64SwiftEngineState(objectCapacity: 32)
        let noOpBridge = SM64BehaviorDispatchBridge()
        let noOp = try noOpBridge.spawnNoOp(in: noOpEngine, behaviorIdentity: SM64NoOpObjectBridge.unused05A8Identity)
        require(
            SM64NoOpObjectBridge.registeredIdentities.allSatisfy {
                SM64BehaviorDispatchBridge.route(for: $0) == .noOp
            },
            "registered no-op behavior identities route"
        )
        let noOpTick = noOpBridge.tick(state: noOpEngine)
        require(
            noOpTick.noOpEffects.count == 1
                && noOpTick.noOpEffects[0].objectID == noOp
                && noOpTick.noOpEffects[0].output.scriptBreaks,
            "break-only behavior remains active without mutation"
        )

        let staticBehaviorEngine = SM64SwiftEngineState(objectCapacity: 16)
        let staticBehaviorBridge = SM64BehaviorDispatchBridge()
        let igloo = try staticBehaviorBridge.spawnNoOp(
            in: staticBehaviorEngine,
            behaviorIdentity: SM64NoOpObjectBridge.iglooIdentity
        )
        let snowman = try staticBehaviorBridge.spawnNoOp(
            in: staticBehaviorEngine,
            behaviorIdentity: SM64NoOpObjectBridge.bigSnowmanWholeIdentity
        )
        let cageChild = try staticBehaviorBridge.spawnNoOp(
            in: staticBehaviorEngine,
            behaviorIdentity: SM64NoOpObjectBridge.ukikiCageChildIdentity,
            position: .zero
        )
        let shipPart = try staticBehaviorBridge.spawnNoOp(
            in: staticBehaviorEngine,
            behaviorIdentity: SM64NoOpObjectBridge.sunkenShipPart2Identity
        )
        let tower = try staticBehaviorBridge.spawnNoOp(
            in: staticBehaviorEngine,
            behaviorIdentity: SM64NoOpObjectBridge.towerIdentity
        )
        let shipCollision = try staticBehaviorBridge.spawnNoOp(
            in: staticBehaviorEngine,
            behaviorIdentity: SM64NoOpObjectBridge.inSunkenShip2Identity
        )
        require(
            staticBehaviorEngine.objects.record(for: igloo)?.interactionType == (1 << 30)
                && staticBehaviorEngine.objects.record(for: igloo)?.hitboxRadius == 100
                && staticBehaviorEngine.objects.record(for: igloo)?.hitboxHeight == 200
                && staticBehaviorEngine.objects.record(for: snowman)?.interactionType == (1 << 23)
                && staticBehaviorEngine.objects.record(for: snowman)?.graphYOffset == 180
                && staticBehaviorEngine.objects.record(for: snowman)?.hitboxRadius == 210
                && staticBehaviorEngine.objects.record(for: cageChild)?.position == .init(x: 2560, y: 1457, z: 1898)
                && staticBehaviorEngine.objects.record(for: shipPart)?.faceAngles == .init(pitch: 0xE958, yaw: 0xEE6C, roll: 0x0C80)
                && staticBehaviorEngine.objects.record(for: shipPart)?.drawingDistance == 6000
                && staticBehaviorEngine.objects.record(for: tower)?.objectList == .surface
                && staticBehaviorEngine.objects.record(for: tower)?.collisionDistance == 3000
                && staticBehaviorEngine.objects.record(for: tower)?.drawingDistance == 20000
                && staticBehaviorEngine.objects.record(for: shipCollision)?.collisionDistance == 4000
                && staticBehaviorEngine.objects.record(for: shipCollision)?.faceAngles == .init(pitch: 0xE958, yaw: 0xEE6C, roll: 0x0C80),
            "static terminal owner field setup"
        )
        let staticBehaviorTick = staticBehaviorBridge.tick(state: staticBehaviorEngine)
        require(
            staticBehaviorTick.noOpEffects.count == 6
                && staticBehaviorTick.noOpEffects.filter { $0.objectID == igloo || $0.objectID == snowman }.allSatisfy { !$0.output.scriptBreaks },
            "static interaction owner update/reset semantics"
        )
        require(
            staticBehaviorEngine.platformCollisionOwners.contains(tower)
                && staticBehaviorEngine.platformCollisionOwners.contains(shipCollision),
            "static collision owner registration"
        )

        let cannonBarrelEngine = SM64SwiftEngineState(objectCapacity: 32)
        let cannonBarrelBridge = SM64BehaviorDispatchBridge()
        let cannonBarrel = try cannonBarrelBridge.spawnCannonBarrelBubbles(
            in: cannonBarrelEngine,
            parentPosition: SM64ObjectVector3(x: 10, y: 20, z: -4),
            parentFaceYaw: 0x1000,
            parentMovePitch: 0x2000,
            cannonActive: true
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CannonBarrelBubblesObjectBridge.defaultBehaviorIdentity) == .cannonBarrelBubbles,
            "cannon barrel bubbles identity route"
        )
        let cannonBarrelTick = cannonBarrelBridge.tick(state: cannonBarrelEngine)
        require(
            cannonBarrelTick.cannonBarrelBubblesEffects.count == 1
                && cannonBarrelTick.cannonBarrelBubblesEffects[0].objectID == cannonBarrel
                && cannonBarrelTick.cannonBarrelBubblesEffects[0].output.spawnBomb
                && cannonBarrelTick.cannonBarrelBubblesEffects[0].spawnedBomb != nil
                && cannonBarrelTick.cannonBarrelBubblesEffects[0].output.forwardVelocity == 35,
            "cannon barrel water-bomb child route is preserved"
        )

        let cloudEngine = SM64SwiftEngineState(objectCapacity: 32)
        let cloudBridge = SM64BehaviorDispatchBridge()
        let cloud = try cloudBridge.spawnCloud(
            in: cloudEngine,
            kind: .fwoosh,
            position: SM64ObjectVector3(x: 10, y: 20, z: -4),
            scale: 3,
            action: .spawnParts
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CloudObjectBridge.defaultBehaviorIdentity) == .cloud,
            "cloud identity route"
        )
        let cloudTick = cloudBridge.tick(state: cloudEngine)
        require(
            cloudTick.cloudEffects.count == 1
                && cloudTick.cloudEffects[0].objectID == cloud
                && cloudTick.cloudEffects[0].output.childPartCount == 6
                && cloudTick.cloudEffects[0].spawnedParts.count == 6
                && cloudEngine.objects.record(for: cloud) != nil,
            "cloud parent/child spawn route is preserved"
        )

        cloudEngine.beginFrame()
        let blowingCloud = try cloudBridge.spawnCloud(
            in: cloudEngine,
            kind: .fwoosh,
            position: SM64ObjectVector3(x: 40, y: 50, z: 60),
            distanceToMario: 500,
            scale: 3,
            action: .main,
            timer: 9,
            blowing: true,
            growSpeed: -0.11
        )
        let blowingCloudTick = cloudBridge.tick(state: cloudEngine)
        let blowingEffect = blowingCloudTick.cloudEffects.first { $0.objectID == blowingCloud }
        require(
            blowingEffect?.output.spawnWindParticles == true
                && blowingEffect?.output.soundIntent == .blow
                && blowingEffect?.spawnedWindParticles.count == 3
                && (blowingEffect?.spawnedWindParticles ?? []).allSatisfy { cloudEngine.objects.record(for: $0) != nil },
            "cloud wind effect sink allocates authored particle variants"
        )

        let celebrationEngine = SM64SwiftEngineState(objectCapacity: 32)
        let celebrationBridge = SM64BehaviorDispatchBridge()
        let celebrationStar = try celebrationBridge.spawnCelebrationStar(
            in: celebrationEngine,
            variant: .star,
            marioPosition: SM64ObjectVector3(x: 12, y: 40, z: -8),
            marioYaw: 0x8000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CelebrationStarObjectBridge.defaultBehaviorIdentity) == .celebrationStar,
            "celebration star identity route"
        )
        let celebrationTick = celebrationBridge.tick(state: celebrationEngine)
        let celebrationEffect = celebrationTick.celebrationStarEffects.first { $0.objectID == celebrationStar }
        require(
            celebrationEffect?.output.spawnSparkle == true
                && celebrationEffect?.spawnedSparkle != nil
                && celebrationEffect?.output.position == SM64ObjectVector3(x: 12, y: 75, z: 42)
                && celebrationEffect?.output.diameter == 101
                && celebrationEffect?.spawnedSparkle.flatMap { celebrationEngine.objects.record(for: $0)?.parent } == celebrationStar,
            "celebration star parent orbit and sparkle child route are preserved"
        )

        let warpEngine = SM64SwiftEngineState(objectCapacity: 16)
        let warpBridge = SM64BehaviorDispatchBridge()
        let normalWarp = try warpBridge.spawnWarp(in: warpEngine, variant: .normal, behaviorByte: 7)
        let fadingWarp = try warpBridge.spawnWarp(in: warpEngine, variant: .fading, behaviorByte: 0)
        let pipeWarp = try warpBridge.spawnWarp(in: warpEngine, variant: .pipe, behaviorByte: 0xFF)
        let exitPodiumWarp = try warpBridge.spawnWarp(in: warpEngine, variant: .exitPodium, behaviorByte: 0xFF)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WarpObjectBridge.normalBehaviorIdentity) == .warp
                && SM64BehaviorDispatchBridge.route(for: SM64WarpObjectBridge.fadingBehaviorIdentity) == .warp
                && SM64BehaviorDispatchBridge.route(for: SM64WarpObjectBridge.pipeBehaviorIdentity) == .warp
                && SM64BehaviorDispatchBridge.route(for: SM64WarpObjectBridge.exitPodiumBehaviorIdentity) == .warp,
            "warp family identity routes"
        )
        _ = warpEngine.objects.mutate(normalWarp) { $0.interactionStatus = 9 }
        let warpTick = warpBridge.tick(state: warpEngine)
        let normalWarpEffect = warpTick.warpEffects.first { $0.objectID == normalWarp }
        let fadingWarpEffect = warpTick.warpEffects.first { $0.objectID == fadingWarp }
        let pipeWarpEffect = warpTick.warpEffects.first { $0.objectID == pipeWarp }
        let exitPodiumWarpEffect = warpTick.warpEffects.first { $0.objectID == exitPodiumWarp }
        require(
            normalWarpEffect?.output.hitboxRadius == 70
                && fadingWarpEffect?.output.hitboxRadius == 85
                && pipeWarpEffect?.output.hitboxRadius == 10_000
                && pipeWarpEffect?.output.collisionModel == true
                && exitPodiumWarpEffect?.output.hitboxRadius == 50
                && exitPodiumWarpEffect?.output.collisionDataIdentity == 0x74746D5F706F6469
                && warpEngine.objects.record(for: normalWarp)?.interactionStatus == 0,
            "warp hitbox/reset/collision routes are preserved"
        )

        let dddWarpEngine = SM64SwiftEngineState(objectCapacity: 8)
        let dddWarpBridge = SM64BehaviorDispatchBridge()
        let dddWarp = try dddWarpBridge.spawnDddWarp(in: dddWarpEngine, paintingBeaten: false)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64DddWarpObjectBridge.defaultBehaviorIdentity) == .dddWarp,
            "DDD warp identity route"
        )
        let dddBeforeTick = dddWarpBridge.tick(state: dddWarpEngine)
        let dddBeforeEffect = dddBeforeTick.dddWarpEffects.first { $0.objectID == dddWarp }
        require(
            dddBeforeEffect?.output.collisionDataIdentity == SM64DddWarpBehavior.preBossCollisionIdentity
                && dddBeforeEffect?.output.collisionDistance == 30_000,
            "DDD warp pre-boss collision route"
        )
        _ = dddWarpBridge.dddWarp.setPaintingBeaten(true, for: dddWarp)
        let dddAfterTick = dddWarpBridge.tick(state: dddWarpEngine)
        require(
            dddAfterTick.dddWarpEffects.first { $0.objectID == dddWarp }?.output.collisionDataIdentity == SM64DddWarpBehavior.postBossCollisionIdentity,
            "DDD warp post-boss collision route"
        )

        let selectorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let selectorBridge = SM64BehaviorDispatchBridge()
        let selectorStar = try selectorBridge.spawnActSelectorStarType(
            in: selectorEngine,
            type: .selected,
            position: .zero,
            size: 1.25
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ActSelectorStarTypeObjectBridge.defaultBehaviorIdentity) == .actSelectorStarType,
            "act-selector star type identity route"
        )
        let selectorTick = selectorBridge.tick(state: selectorEngine)
        let selectorEffect = selectorTick.actSelectorStarTypeEffects.first { $0.objectID == selectorStar }
        require(
            selectorEffect?.output.size == 1.3
                && selectorEffect?.output.faceYaw == 0x800
                && selectorEffect?.output.timer == 1,
            "act-selector star pulse/rotation route is preserved"
        )

        let collectStarEngine = SM64SwiftEngineState(objectCapacity: 8)
        let collectStarBridge = SM64BehaviorDispatchBridge()
        let freshStar = try collectStarBridge.spawnCollectStar(in: collectStarEngine, starCollected: false, position: .zero)
        let transparentStar = try collectStarBridge.spawnCollectStar(in: collectStarEngine, starCollected: true, position: .zero)
        _ = collectStarEngine.objects.mutate(freshStar) { $0.interactionStatus = 1 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CollectStarObjectBridge.defaultBehaviorIdentity) == .collectStar,
            "collectible star identity route"
        )
        let collectStarTick = collectStarBridge.tick(state: collectStarEngine)
        let freshEffect = collectStarTick.collectStarEffects.first { $0.objectID == freshStar }
        let transparentEffect = collectStarTick.collectStarEffects.first { $0.objectID == transparentStar }
        require(
            freshEffect?.output.shouldDelete == true
                && transparentEffect?.output.model == .transparentStar
                && transparentEffect?.output.faceYaw == 0x800
                && (collectStarEngine.objects.record(for: freshStar) == nil || collectStarEngine.objects.record(for: freshStar)?.interactionStatus == 0),
            "collectible star model/rotation/interaction route is preserved"
        )

        let starSpawnEngine = SM64SwiftEngineState(objectCapacity: 32)
        let starSpawnBridge = SM64BehaviorDispatchBridge()
        let starSpawn = try starSpawnBridge.spawnStarSpawnCoordinates(
            in: starSpawnEngine,
            starCollected: true,
            position: .zero,
            homePosition: SM64ObjectVector3(x: 0, y: 30, z: 30)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64StarSpawnCoordinatesObjectBridge.defaultBehaviorIdentity) == .starSpawnCoordinates,
            "star-spawn coordinates identity route"
        )
        let starSpawnTick = starSpawnBridge.tick(state: starSpawnEngine)
        let starSpawnEffect = starSpawnTick.starSpawnCoordinatesEffects.first { $0.objectID == starSpawn }
        require(
            starSpawnEffect?.output.action == .intro
                && starSpawnEffect?.output.model == .transparentStar
                && starSpawnEffect?.output.faceYaw == 0x1000
                && starSpawnEngine.globals.timeStopState.contains(.enabled)
                && starSpawnEngine.globals.timeStopState.contains(.marioAndDoors),
            "star-spawn coordinates intro/time-stop route is preserved"
        )

        let spawnedStarEngine = SM64SwiftEngineState(objectCapacity: 32)
        let spawnedStarBridge = SM64BehaviorDispatchBridge()
        let spawnedStar = try spawnedStarBridge.spawnSpawnedStar(
            in: spawnedStarEngine,
            noExit: true,
            starCollected: true,
            position: .init(x: 0, y: 10, z: 0),
            homePosition: .init(x: 0, y: 0, z: 0)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SpawnedStarObjectBridge.defaultBehaviorIdentity) == .spawnedStar
                && SM64BehaviorDispatchBridge.route(for: SM64SpawnedStarObjectBridge.noLevelExitBehaviorIdentity) == .spawnedStarNoLevelExit,
            "spawned-star identity routes"
        )
        let spawnedStarTick = spawnedStarBridge.tick(state: spawnedStarEngine)
        let spawnedStarEffect = spawnedStarTick.spawnedStarEffects.first { $0.objectID == spawnedStar }
        require(
            spawnedStarEffect?.output.model == .transparentStar
                && spawnedStarEffect?.output.spawnSparkle == true
                && spawnedStarEngine.globals.timeStopState.contains(.enabled)
                && spawnedStarEngine.globals.timeStopState.contains(.marioAndDoors),
            "spawned-star intro/transparent/time-stop route is preserved"
        )

        let unlockDoorStarEngine = SM64SwiftEngineState(objectCapacity: 32)
        let unlockDoorStarBridge = SM64BehaviorDispatchBridge()
        let unlockDoorStar = try unlockDoorStarBridge.spawnUnlockDoorStar(
            in: unlockDoorStarEngine,
            position: SM64ObjectVector3(x: 4, y: 8, z: 12)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64UnlockDoorStarObjectBridge.defaultBehaviorIdentity) == .spawnedStar,
            "unlock-door star identity shares the star dispatch lane"
        )
        let unlockDoorStarTick = unlockDoorStarBridge.tick(state: unlockDoorStarEngine)
        let unlockDoorStarEffect = unlockDoorStarTick.unlockDoorStarEffects.first { $0.objectID == unlockDoorStar }
        require(
            unlockDoorStarEffect?.output.state == 0
                && unlockDoorStarEffect?.output.timer == 1
                && unlockDoorStarEffect?.output.moveYaw == 0x8860
                && unlockDoorStarEffect?.output.yawVelocity == 0x1060
                && unlockDoorStarEngine.objects.record(for: unlockDoorStar)?.position.y == 11.4,
            "unlock-door star rising owner route is preserved"
        )

        let ccmEngine = SM64SwiftEngineState(objectCapacity: 32)
        let ccmBridge = SM64BehaviorDispatchBridge()
        let ccmTrigger = try ccmBridge.spawnCcmTouchedStarSpawn(
            in: ccmEngine,
            position: SM64ObjectVector3(x: 1, y: 2, z: 3),
            enteredSlide: true
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CcmTouchedStarSpawnObjectBridge.defaultBehaviorIdentity) == .ccmTouchedStarSpawn,
            "CCM touched-star identity route"
        )
        let ccmTick = ccmBridge.tick(state: ccmEngine)
        let ccmEffect = ccmTick.ccmTouchedStarSpawnEffects.first { $0.objectID == ccmTrigger }
        require(
            ccmEffect?.output.position == SM64ObjectVector3(x: 2780, y: 102, z: 4666)
                && ccmEffect?.spawnedStar != nil
                && ccmEffect?.spawnedStar.flatMap { ccmEngine.objects.record(for: $0)?.homePosition } == SM64ObjectVector3(x: 2500, y: -4350, z: 5750),
            "CCM touched-star reposition/spawn/retirement route is preserved"
        )

        let hiddenStarEngine = SM64SwiftEngineState(objectCapacity: 32)
        let hiddenStarBridge = SM64BehaviorDispatchBridge()
        let hiddenStar = try hiddenStarBridge.spawnHiddenStar(in: hiddenStarEngine, position: .zero, initialTriggerCounter: 4)
        let hiddenTrigger = try hiddenStarBridge.spawnHiddenStarTrigger(in: hiddenStarEngine, parent: hiddenStar, collidedWithMario: true)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64HiddenStarObjectBridge.hiddenStarBehaviorIdentity) == .hiddenStar
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenStarObjectBridge.triggerBehaviorIdentity) == .hiddenStarTrigger,
            "hidden-star identity routes"
        )
        let hiddenTick = hiddenStarBridge.tick(state: hiddenStarEngine)
        require(
            hiddenTick.hiddenStarTriggerEffects.first { $0.objectID == hiddenTrigger }?.output.triggerCounter == 5
                && hiddenTick.hiddenStarTriggerEffects.first { $0.objectID == hiddenTrigger }?.output.shouldDelete == true,
            "hidden-star trigger counter route is preserved"
        )
        let bowserHiddenStar = try hiddenStarBridge.spawnBowserCourseRedCoinStar(in: hiddenStarEngine, position: SM64ObjectVector3(x: 2, y: 3, z: 4), initialTriggerCounter: 8)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64HiddenStarObjectBridge.bowserCourseRedCoinStarBehaviorIdentity) == .hiddenStar,
            "Bowser red-coin hidden-star identity route"
        )
        let bowserHiddenTick = hiddenStarBridge.tick(state: hiddenStarEngine)
        require(
            bowserHiddenTick.hiddenStarEffects.first { $0.objectID == bowserHiddenStar }?.output.action == .reveal,
            "Bowser red-coin hidden-star threshold route is preserved"
        )

        let grateEngine = SM64SwiftEngineState(objectCapacity: 8)
        let grateBridge = SM64BehaviorDispatchBridge()
        let grate = try grateBridge.spawnCastleCannonGrate(in: grateEngine, totalStarCount: 120)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CastleCannonGrateObjectBridge.defaultBehaviorIdentity) == .castleCannonGrate,
            "120-star cannon grate identity route"
        )
        let grateTick = grateBridge.tick(state: grateEngine)
        require(
            grateTick.castleCannonGrateEffects.first { $0.objectID == grate }?.output.shouldDeactivate == true,
            "120-star cannon grate deactivation route is preserved"
        )

        let blueCoinEngine = SM64SwiftEngineState(objectCapacity: 64)
        let blueCoinBridge = SM64BehaviorDispatchBridge()
        let blueCoinSwitch = try blueCoinBridge.spawnBlueCoinSwitch(
            in: blueCoinEngine,
            position: SM64ObjectVector3(x: 10, y: 100, z: 20)
        )
        let hiddenBlueCoin = try blueCoinBridge.spawnHiddenBlueCoin(
            in: blueCoinEngine,
            position: SM64ObjectVector3(x: 12, y: 100, z: 20)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlueCoinObjectBridge.blueCoinSwitchBehaviorIdentity) == .blueCoinSwitch
                && SM64BehaviorDispatchBridge.route(for: SM64BlueCoinObjectBridge.hiddenBlueCoinBehaviorIdentity) == .hiddenBlueCoin,
            "blue-coin switch/hidden-coin identity routes"
        )
        let blueCoinWaitingTick = blueCoinBridge.tick(state: blueCoinEngine)
        require(
            blueCoinWaitingTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.output.action == .waiting
                && blueCoinWaitingTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.switchID == blueCoinSwitch,
            "hidden blue coin nearest-switch binding route is preserved"
        )
        require(blueCoinBridge.blueCoin.setSwitchAction(.ticking, for: blueCoinSwitch), "blue-coin switch test transition")
        let blueCoinActiveTick = blueCoinBridge.tick(state: blueCoinEngine)
        require(
            blueCoinActiveTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.output.action == .active
                && blueCoinActiveTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.output.visible == false,
            "hidden blue coin ticking activation edge is preserved"
        )
        require(blueCoinBridge.blueCoin.setInteraction(true, for: hiddenBlueCoin), "hidden blue coin interaction test input")
        let blueCoinCollectedTick = blueCoinBridge.tick(state: blueCoinEngine)
        require(
            blueCoinCollectedTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.output.spawnGoldenSparkles == true
                && blueCoinCollectedTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.output.shouldDelete == true
                && blueCoinCollectedTick.hiddenBlueCoinEffects.first { $0.objectID == hiddenBlueCoin }?.spawnedSparkles != nil,
            "hidden blue coin interaction/sparkle retirement route is preserved"
        )

        let redCoinEngine = SM64SwiftEngineState(objectCapacity: 64)
        let redCoinBridge = SM64BehaviorDispatchBridge()
        let hiddenRedCoinStar = try redCoinBridge.spawnHiddenRedCoinStar(
            in: redCoinEngine,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            redCoinCount: 1
        )
        let redCoin = try redCoinBridge.spawnRedCoin(
            in: redCoinEngine,
            position: SM64ObjectVector3(x: 102, y: 200, z: 300),
            parent: hiddenRedCoinStar
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RedCoinObjectBridge.hiddenRedCoinStarBehaviorIdentity) == .hiddenRedCoinStar
                && SM64BehaviorDispatchBridge.route(for: SM64RedCoinObjectBridge.redCoinStarMarkerBehaviorIdentity) == .redCoinStarMarker
                && SM64BehaviorDispatchBridge.route(for: SM64RedCoinObjectBridge.redCoinBehaviorIdentity) == .redCoin,
            "red-coin star identity routes"
        )
        let redWaitingTick = redCoinBridge.tick(state: redCoinEngine)
        require(
            redWaitingTick.hiddenRedCoinStarEffects.first { $0.objectID == hiddenRedCoinStar }?.output.redCoinsCollected == 7
                && redWaitingTick.hiddenRedCoinStarEffects.first { $0.objectID == hiddenRedCoinStar }?.spawnedMarker != nil
                && redWaitingTick.redCoinEffects.first { $0.objectID == redCoin }?.output.shouldDelete == false,
            "red-coin star waiting/marker route is preserved"
        )
        require(redCoinBridge.redCoin.setRedCoinInteraction(true, for: redCoin), "red-coin interaction test input")
        let redCollectedTick = redCoinBridge.tick(state: redCoinEngine)
        require(
            redCollectedTick.redCoinEffects.first { $0.objectID == redCoin }?.output.parentCounter == 8
                && redCollectedTick.redCoinEffects.first { $0.objectID == redCoin }?.output.soundOrdinal == 7
                && redCollectedTick.redCoinEffects.first { $0.objectID == redCoin }?.output.spawnGoldenSparkles == true
                && redCollectedTick.redCoinEffects.first { $0.objectID == redCoin }?.spawnedSparkles != nil,
            "red-coin counter/sparkle route is preserved"
        )
        _ = redCoinBridge.tick(state: redCoinEngine)
        _ = redCoinBridge.tick(state: redCoinEngine)
        _ = redCoinBridge.tick(state: redCoinEngine)
        _ = redCoinBridge.tick(state: redCoinEngine)
        let redRevealTick = redCoinBridge.tick(state: redCoinEngine)
        require(
            redRevealTick.hiddenRedCoinStarEffects.first { $0.objectID == hiddenRedCoinStar }?.output.spawnNoExitStar == true
                && redRevealTick.hiddenRedCoinStarEffects.first { $0.objectID == hiddenRedCoinStar }?.output.shouldDeactivate == true,
            "red-coin star reveal/star-spawn route is preserved"
        )

        let starDoorEngine = SM64SwiftEngineState(objectCapacity: 16)
        let starDoorBridge = SM64BehaviorDispatchBridge()
        let firstStarDoor = try starDoorBridge.spawnStarDoor(in: starDoorEngine, position: .zero, moveYaw: 0)
        let secondStarDoor = try starDoorBridge.spawnStarDoor(in: starDoorEngine, position: SM64ObjectVector3(x: 100, y: 0, z: 0), moveYaw: 0)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64StarDoorObjectBridge.defaultBehaviorIdentity) == .starDoor,
            "star-door identity route"
        )
        require(starDoorBridge.starDoor.setInteraction(true, for: firstStarDoor), "star-door interaction test input")
        let starDoorOpeningTick = starDoorBridge.tick(state: starDoorEngine)
        require(
            starDoorOpeningTick.starDoorEffects.first { $0.objectID == firstStarDoor }?.output.action == .opening
                && starDoorOpeningTick.starDoorEffects.first { $0.objectID == secondStarDoor }?.output.action == .opening
                && starDoorOpeningTick.starDoorEffects.first { $0.objectID == firstStarDoor }?.output.sound == SM64StarDoorSound.none,
            "paired star-door opening route is preserved"
        )
        let starDoorSoundTick = starDoorBridge.tick(state: starDoorEngine)
        require(
            starDoorSoundTick.starDoorEffects.first { $0.objectID == firstStarDoor }?.output.sound == .open,
            "star-door opening sound edge is preserved"
        )
        require(starDoorBridge.starDoor.setRoomVisible(false, for: secondStarDoor), "star-door room visibility test input")
        let starDoorVisibilityTick = starDoorBridge.tick(state: starDoorEngine)
        require(
            starDoorVisibilityTick.starDoorEffects.first { $0.objectID == secondStarDoor }?.output.visible == false
                && starDoorVisibilityTick.starDoorEffects.first { $0.objectID == secondStarDoor }?.output.tangible == false,
            "star-door visibility/intangible route is preserved"
        )

        let capSwitchEngine = SM64SwiftEngineState(objectCapacity: 32)
        let capSwitchBridge = SM64BehaviorDispatchBridge()
        let capSwitch = try capSwitchBridge.spawnCapSwitch(in: capSwitchEngine, position: .zero, variant: 0)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CapSwitchObjectBridge.capSwitchBehaviorIdentity) == .capSwitch
                && SM64BehaviorDispatchBridge.route(for: SM64CapSwitchObjectBridge.capSwitchBaseBehaviorIdentity) == .capSwitchBase,
            "cap-switch identity routes"
        )
        let capInitTick = capSwitchBridge.tick(state: capSwitchEngine)
        require(
            capInitTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.action == .waiting
                && capInitTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.spawnBase != nil,
            "cap-switch initialization/base route is preserved"
        )
        let metalCapEngine = SM64SwiftEngineState(objectCapacity: 8)
        let metalCapBridge = SM64BehaviorDispatchBridge()
        let metalCap = try metalCapBridge.spawnMetalCap(in: metalCapEngine, forwardVelocity: 2)
        require(SM64BehaviorDispatchBridge.route(for: SM64MetalCapObjectBridge.defaultBehaviorIdentity) == .capSwitch, "metal-cap identity shares cap dispatch lane")
        let metalCapTick = metalCapBridge.tick(state: metalCapEngine)
        require(
            metalCapTick.metalCapEffects.first { $0.objectID == metalCap }?.output.faceYaw == 256
                && metalCapTick.metalCapEffects.first { $0.objectID == metalCap }?.output.tangible == false,
            "metal-cap physics/tangibility owner route"
        )
        let vanishCapEngine = SM64SwiftEngineState(objectCapacity: 8)
        let vanishCapBridge = SM64BehaviorDispatchBridge()
        let vanishCap = try vanishCapBridge.spawnVanishCap(in: vanishCapEngine, forwardVelocity: 2)
        require(SM64BehaviorDispatchBridge.route(for: SM64VanishCapObjectBridge.defaultBehaviorIdentity) == .capSwitch, "vanish-cap identity shares cap dispatch lane")
        let vanishCapTick = vanishCapBridge.tick(state: vanishCapEngine)
        require(
            vanishCapTick.vanishCapEffects.first { $0.objectID == vanishCap }?.output.faceYaw == 256
                && vanishCapTick.vanishCapEffects.first { $0.objectID == vanishCap }?.output.opacity == 150,
            "vanish-cap physics/opacity owner route"
        )
        let wingCapEngine = SM64SwiftEngineState(objectCapacity: 8)
        let wingCapBridge = SM64BehaviorDispatchBridge()
        let wingCap = try wingCapBridge.spawnWingCap(in: wingCapEngine, forwardVelocity: 2)
        require(SM64BehaviorDispatchBridge.route(for: SM64WingCapObjectBridge.defaultBehaviorIdentity) == .capSwitch, "wing-cap identity shares cap dispatch lane")
        let wingCapTick = wingCapBridge.tick(state: wingCapEngine)
        require(
            wingCapTick.wingCapEffects.first { $0.objectID == wingCap }?.output.faceYaw == 256
                && wingCapTick.wingCapEffects.first { $0.objectID == wingCap }?.output.opacity == 255,
            "wing-cap physics/opacity owner route"
        )
        let normalCapEngine = SM64SwiftEngineState(objectCapacity: 8)
        let normalCapBridge = SM64BehaviorDispatchBridge()
        let normalCap = try normalCapBridge.spawnNormalCap(in: normalCapEngine, forwardVelocity: 2, course: .ssl)
        require(SM64BehaviorDispatchBridge.route(for: SM64NormalCapObjectBridge.defaultBehaviorIdentity) == .capSwitch, "normal-cap identity shares cap dispatch lane")
        let normalCapTick = normalCapBridge.tick(state: normalCapEngine)
        require(
            normalCapTick.normalCapEffects.first { $0.objectID == normalCap }?.output.faceYaw == 256
                && normalCapTick.normalCapEffects.first { $0.objectID == normalCap }?.output.facePitch == 160,
            "normal-cap physics owner route"
        )
        require(capSwitchBridge.capSwitch.setMarioOnPlatform(true, for: capSwitch), "cap-switch activation test input")
        let capActivateTick = capSwitchBridge.tick(state: capSwitchEngine)
        require(
            capActivateTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.action == .pressing
                && capActivateTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.saveFlagToSet == (1 << 1)
                && capActivateTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.playSound == true,
            "cap-switch activation/save route is preserved"
        )
        _ = capSwitchBridge.tick(state: capSwitchEngine)
        _ = capSwitchBridge.tick(state: capSwitchEngine)
        _ = capSwitchBridge.tick(state: capSwitchEngine)
        _ = capSwitchBridge.tick(state: capSwitchEngine)
        let capEffectTick = capSwitchBridge.tick(state: capSwitchEngine)
        require(
            capEffectTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.spawnMist == true
                && capEffectTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.spawnTriangleBreak == true,
            "cap-switch press particle/rumble route is preserved"
        )
        require(capSwitchBridge.capSwitch.setDialogComplete(true, for: capSwitch), "cap-switch dialog completion input")
        let capFinishTick = capSwitchBridge.tick(state: capSwitchEngine)
        require(capFinishTick.capSwitchEffects.first { $0.objectID == capSwitch }?.output.action == .pressed, "cap-switch pressed transition is preserved")

        let towerDoorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let towerDoorBridge = SM64BehaviorDispatchBridge()
        let towerDoor = try towerDoorBridge.spawnTowerDoor(in: towerDoorEngine, position: .zero, faceYaw: 0x5000)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TowerDoorObjectBridge.defaultBehaviorIdentity) == .towerDoor,
            "tower-door identity route"
        )
        let towerIdleTick = towerDoorBridge.tick(state: towerDoorEngine)
        require(
            towerIdleTick.towerDoorEffects.first { $0.objectID == towerDoor }?.output.faceYaw == 0x1000
                && towerIdleTick.towerDoorEffects.first { $0.objectID == towerDoor }?.output.shouldDelete == false,
            "tower-door first-frame yaw route is preserved"
        )
        require(towerDoorBridge.towerDoor.setMarioAttacking(true, for: towerDoor), "tower-door attack test input")
        let towerAttackTick = towerDoorBridge.tick(state: towerDoorEngine)
        require(
            towerAttackTick.towerDoorEffects.first { $0.objectID == towerDoor }?.output.spawnMist == true
                && towerAttackTick.towerDoorEffects.first { $0.objectID == towerDoor }?.output.spawnTriangleBreak == true
                && towerAttackTick.towerDoorEffects.first { $0.objectID == towerDoor }?.output.playWallExplosionSound == true
                && towerAttackTick.towerDoorEffects.first { $0.objectID == towerDoor }?.output.shouldDelete == true,
            "tower-door attack/explosion route is preserved"
        )

        let grillEngine = SM64SwiftEngineState(objectCapacity: 32)
        let grillBridge = SM64BehaviorDispatchBridge()
        let grill = try grillBridge.spawnOpenableGrill(in: grillEngine, position: .zero, variant: 1)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64OpenableGrillObjectBridge.grillBehaviorIdentity) == .openableGrill
                && SM64BehaviorDispatchBridge.route(for: SM64OpenableGrillObjectBridge.cageDoorBehaviorIdentity) == .openableCageDoor,
            "openable-grill identity routes"
        )
        let grillSpawnTick = grillBridge.tick(state: grillEngine)
        let grillChildren = grillSpawnTick.openableGrillEffects.first { $0.objectID == grill }?.spawnedChildren ?? []
        require(grillChildren.count == 2 && grillSpawnTick.openableGrillEffects.first { $0.objectID == grill }?.output.action == .waitForSwitch, "openable-grill child spawn route is preserved")
        require(grillBridge.openableGrill.setFloorSwitch(found: true, action: 0, for: grill), "openable-grill floor-switch discovery input")
        _ = grillBridge.tick(state: grillEngine)
        require(grillBridge.openableGrill.setFloorSwitch(found: true, action: 2, for: grill), "openable-grill floor-switch activation input")
        let grillOpenTick = grillBridge.tick(state: grillEngine)
        require(grillOpenTick.openableGrillEffects.first { $0.objectID == grill }?.output.signalChildren == true && grillOpenTick.openableGrillEffects.first { $0.objectID == grill }?.output.playPuzzleJingle == true, "openable-grill open signal route is preserved")
        let grillChildStartTick = grillBridge.tick(state: grillEngine)
        require(grillChildStartTick.openableCageDoorEffects.count == 2 && grillChildStartTick.openableCageDoorEffects.allSatisfy { $0.output.action == 1 }, "openable cage-door activation route is preserved")
        let grillChildMoveTick = grillBridge.tick(state: grillEngine)
        require(grillChildMoveTick.openableCageDoorEffects.contains { $0.output.faceYaw != 0 }, "openable cage-door movement route is preserved")

        let doorEngine = SM64SwiftEngineState(objectCapacity: 16)
        let doorBridge = SM64BehaviorDispatchBridge()
        let normalDoor = try doorBridge.spawnDoor(in: doorEngine, warp: false, metalDoor: false)
        let warpDoor = try doorBridge.spawnDoor(in: doorEngine, warp: true, metalDoor: true, position: SM64ObjectVector3(x: 100, y: 0, z: 0))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64DoorObjectBridge.normalBehaviorIdentity) == .door
                && SM64BehaviorDispatchBridge.route(for: SM64DoorObjectBridge.warpBehaviorIdentity) == .door,
            "door identity routes"
        )
        require(doorBridge.door.setInteractionStatus(0x10000, for: normalDoor), "normal door interaction input")
        let normalDoorTick = doorBridge.tick(state: doorEngine)
        require(
            normalDoorTick.doorEffects.first { $0.objectID == normalDoor }?.output.action == .openingWood
                && normalDoorTick.doorEffects.first { $0.objectID == normalDoor }?.output.sound == .openWood
                && normalDoorTick.doorEffects.first { $0.objectID == normalDoor }?.output.setMarioOpenedDoorTimeStop == true,
            "normal door opening/sound route is preserved"
        )
        require(doorBridge.door.setInteractionStatus(0x40000, for: warpDoor), "warp door interaction input")
        let warpDoorTick = doorBridge.tick(state: doorEngine)
        require(
            warpDoorTick.doorEffects.first { $0.objectID == warpDoor }?.output.action == .warpOpening
                && warpDoorTick.doorEffects.first { $0.objectID == warpDoor }?.output.cameraEvent == .warpDoor,
            "warp door action/camera route is preserved"
        )
        require(doorBridge.door.setAnimationNearEnd(true, for: normalDoor), "door animation-end input")
        let doorResetTick = doorBridge.tick(state: doorEngine)
        require(doorResetTick.doorEffects.first { $0.objectID == normalDoor }?.output.action == .closed && doorResetTick.doorEffects.first { $0.objectID == normalDoor }?.output.loadCollisionModel == true, "door animation reset/collision route is preserved")

        let hiddenObjectEngine = SM64SwiftEngineState(objectCapacity: 16)
        let hiddenObjectBridge = SM64BehaviorDispatchBridge()
        let hiddenObject = try hiddenObjectBridge.spawnHiddenObject(in: hiddenObjectEngine, position: .zero, variant: 0, switchAction: nil)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64HiddenObjectObjectBridge.defaultBehaviorIdentity) == .hiddenObject,
            "hidden-object identity route"
        )
        let hiddenObjectTick = hiddenObjectBridge.tick(state: hiddenObjectEngine)
        require(hiddenObjectTick.hiddenObjectEffects.first { $0.objectID == hiddenObject }?.output.visible == false, "hidden-object hidden route is preserved")
        require(hiddenObjectBridge.hiddenObject.setSwitchAction(2, for: hiddenObject), "hidden-object switch activation input")
        let hiddenObjectShowTick = hiddenObjectBridge.tick(state: hiddenObjectEngine)
        require(hiddenObjectShowTick.hiddenObjectEffects.first { $0.objectID == hiddenObject }?.output.action == .visible, "hidden-object reveal route is preserved")
        require(hiddenObjectBridge.hiddenObject.setAttacked(true, for: hiddenObject), "hidden-object attack input")
        let hiddenObjectBreakTick = hiddenObjectBridge.tick(state: hiddenObjectEngine)
        require(
            hiddenObjectBreakTick.hiddenObjectEffects.first { $0.objectID == hiddenObject }?.output.spawnMist == true
                && hiddenObjectBreakTick.hiddenObjectEffects.first { $0.objectID == hiddenObject }?.output.playBreakSound == true
                && hiddenObjectBreakTick.hiddenObjectEffects.first { $0.objectID == hiddenObject }?.output.action == .broken,
            "hidden-object break route is preserved"
        )

        let recoveryHeartEngine = SM64SwiftEngineState(objectCapacity: 8)
        let recoveryHeartBridge = SM64BehaviorDispatchBridge()
        let recoveryHeart = try recoveryHeartBridge.spawnRecoveryHeart(in: recoveryHeartEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64RecoveryHeartObjectBridge.defaultBehaviorIdentity) == .recoveryHeart,
            "recovery-heart identity route"
        )
        require(recoveryHeartBridge.recoveryHeart.setMarioCollision(true, forwardVelocity: 10, for: recoveryHeart), "recovery-heart collision input")
        let recoveryHeartTick = recoveryHeartBridge.tick(state: recoveryHeartEngine)
        require(
            recoveryHeartTick.recoveryHeartEffects.first { $0.objectID == recoveryHeart }?.output.soundSpin == true
                && recoveryHeartTick.recoveryHeartEffects.first { $0.objectID == recoveryHeart }?.output.yawVelocity == 3000,
            "recovery-heart spin/sound route is preserved"
        )

        let coinEngine = SM64SwiftEngineState(objectCapacity: 16)
        let coinBridge = SM64BehaviorDispatchBridge()
        let yellowCoin = try coinBridge.spawnCoin(in: coinEngine, kind: .yellow, position: .zero, floorDistance: 600, oneCoin: true)
        let temporaryCoin = try coinBridge.spawnCoin(in: coinEngine, kind: .temporary, position: SM64ObjectVector3(x: 100, y: 0, z: 0))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.oneCoinBehaviorIdentity) == .coin
                && SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.temporaryYellowCoinBehaviorIdentity) == .coin,
            "coin identity routes"
        )
        let coinTick = coinBridge.tick(state: coinEngine)
        require(
            coinTick.coinEffects.first { $0.objectID == yellowCoin }?.output.modelNoShadow == true
                && coinTick.coinEffects.first { $0.objectID == temporaryCoin }?.output.kind == .temporary,
            "yellow/temporary coin route is preserved"
        )
        require(coinBridge.coin.setInteraction(true, for: yellowCoin), "coin interaction input")
        let coinCollectedTick = coinBridge.tick(state: coinEngine)
        require(
            coinCollectedTick.coinEffects.first { $0.objectID == yellowCoin }?.output.spawnGoldenSparkles == true
                && coinCollectedTick.coinEffects.first { $0.objectID == yellowCoin }?.spawnedSparkles != nil,
            "coin sparkle retirement route is preserved"
        )

        let formationEngine = SM64SwiftEngineState(objectCapacity: 32)
        let formationBridge = SM64BehaviorDispatchBridge()
        let threeCoinFormation = try formationBridge.spawnCoinFormation(in: formationEngine, count: 3, position: .init(x: 50, y: 10, z: -20))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.threeCoinsSpawnBehaviorIdentity) == .coin
                && SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.tenCoinsSpawnBehaviorIdentity) == .coin
                && SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.singleCoinGetsSpawnedBehaviorIdentity) == .coin,
            "coin formation identity routes"
        )
        let formationTick = formationBridge.tick(state: formationEngine)
        require(
            formationTick.coinSpawnerEffects.first?.objectID == threeCoinFormation
                && formationTick.coinSpawnerEffects.first?.count == 3
                && formationTick.coinSpawnerEffects.first?.spawnedCoins.count == 3
                && formationTick.coinSpawnerEffects.first?.deactivated == true
                && formationTick.coinEffects.isEmpty,
            "coin formation child allocation/deactivation route is preserved"
        )
        let formationChildTick = formationBridge.tick(state: formationEngine)
        require(formationChildTick.coinEffects.count == 3, "coin formation children execute on the next level-list pass")
        let patternedFormation = try formationBridge.coin.spawnPatternFormation(
            in: formationEngine,
            pattern: 4,
            distanceToMario: 100,
            position: .init(x: -100, y: 20, z: 40)
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.coinFormationBehaviorIdentity) == .coin
                && SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.coinFormationSpawnBehaviorIdentity) == .coin,
            "patterned coin formation identity routes"
        )
        let patternedTick = formationBridge.tick(state: formationEngine)
        require(
            patternedTick.coinSpawnerEffects.first { $0.objectID == patternedFormation }?.count == 8
                && patternedTick.coinSpawnerEffects.first { $0.objectID == patternedFormation }?.childPositions.last == .init(x: 0, y: 320, z: 90),
            "patterned coin formation offsets/child ordering are preserved"
        )
        let insideBooEngine = SM64SwiftEngineState(objectCapacity: 8)
        let insideBooBridge = SM64BehaviorDispatchBridge()
        let insideBooParent = try insideBooEngine.spawnObject(in: .generalActor, behaviorIdentity: 0x424F4F)
        _ = insideBooEngine.objects.mutate(insideBooParent) { $0.position = .init(x: 30, y: 40, z: 50) }
        let insideBooCoin = try insideBooBridge.spawnCoinInsideBoo(
            in: insideBooEngine,
            parent: insideBooParent,
            position: .zero,
            levelIsBBH: true
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CoinObjectBridge.coinInsideBooBehaviorIdentity) == .coin
                && insideBooBridge.coin.setCoinInsideBooInput(parentDying: true, marioMoveYaw: 0x4000, for: insideBooCoin),
            "coin-inside-Boo identity/release input route"
        )
        let insideBooTick = insideBooBridge.tick(state: insideBooEngine)
        require(
            insideBooTick.coinEffects.first { $0.objectID == insideBooCoin }?.output.modelNoShadow == true
                && insideBooEngine.objects.record(for: insideBooCoin)?.action == 1
                && insideBooEngine.objects.record(for: insideBooCoin)?.velocity.y == 35,
            "coin-inside-Boo parent release/blue-model route"
        )

        let blueFishEngine = SM64SwiftEngineState(objectCapacity: 32)
        let blueFishBridge = SM64BehaviorDispatchBridge()
        let blueFish = try blueFishBridge.spawnBlueFish(
            in: blueFishEngine,
            randomAngle: 0x100,
            randomVelocity: 2,
            randomTime: 0,
            angleVelocityPitch: 0
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlueFishObjectBridge.defaultBehaviorIdentity) == .blueFish,
            "blue-fish identity route"
        )
        let blueFishDiveTick = blueFishBridge.tick(state: blueFishEngine)
        require(
            blueFishDiveTick.blueFishEffects.first?.objectID == blueFish
                && blueFishDiveTick.blueFishEffects.first?.output.forwardVelocity == 5
                && blueFishEngine.objects.record(for: blueFish)?.position.z == 5,
            "blue-fish dive movement/animation route"
        )
        _ = blueFishEngine.objects.mutate(blueFish) { record in
            record.action = SM64BlueFishAction.turn.rawValue
            record.timer = 15
        }
        let blueFishTurnTick = blueFishBridge.tick(state: blueFishEngine)
        require(
            blueFishTurnTick.blueFishEffects.first?.output.action == .ascend
                && blueFishTurnTick.blueFishEffects.first?.output.moveYaw == 0x100,
            "blue-fish turn-to-ascend transition"
        )
        let tankFishGroup = try blueFishBridge.spawnTankFishGroup(in: blueFishEngine, room: 15, position: .init(x: 100, y: 200, z: 300))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BlueFishObjectBridge.tankFishGroupBehaviorIdentity) == .blueFish,
            "tank-fish group identity route"
        )
        let tankFishTick = blueFishBridge.tick(state: blueFishEngine)
        require(
            tankFishTick.tankFishGroupEffects.first { $0.objectID == tankFishGroup }?.spawnedChildren.count == 15
                && tankFishTick.events.filter { $0.route == .blueFish }.count >= 16,
            "tank-fish group room gate/child ordering"
        )
        let clamEngine = SM64SwiftEngineState(objectCapacity: 32)
        let clamBridge = SM64BehaviorDispatchBridge()
        let clam = try clamBridge.spawnClamShell(in: clamEngine, position: .init(x: 20, y: 30, z: 40))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ClamShellObjectBridge.defaultBehaviorIdentity) == .clamShell,
            "clam-shell identity route"
        )
        _ = clamEngine.objects.mutate(clam) { record in
            record.timer = 151
            record.distanceToMario = 400
        }
        let clamOpenTick = clamBridge.tick(state: clamEngine)
        require(clamOpenTick.clamShellEffects.first?.output.action == .opening, "clam-shell close-to-open transition")
        require(clamBridge.clamShell.setAnimationInputs(frame8: true, for: clam), "clam-shell bubble animation input")
        let clamBubbleTick = clamBridge.tick(state: clamEngine)
        require(
            clamBubbleTick.clamShellEffects.first?.spawnedBubbles.count == 12
                && clamBubbleTick.clamShellEffects.first?.output.scale.y == 1.5,
            "clam-shell bubble burst/scale route"
        )
        let anchorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let anchorBridge = SM64BehaviorDispatchBridge()
        let anchorParent = try anchorEngine.spawnObject(in: .generalActor, behaviorIdentity: 0x424F5742)
        _ = anchorEngine.objects.mutate(anchorParent) { record in
            record.position = .init(x: 10, y: 20, z: 30)
            record.moveAngles.yaw = 0x2000
            record.action = 2
        }
        let anchor = try anchorBridge.spawnBobombAnchorMario(in: anchorEngine, parent: anchorParent)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BobombAnchorMarioObjectBridge.defaultBehaviorIdentity) == .bobombAnchorMario,
            "Bob-omb Mario anchor identity route"
        )
        let anchorTick = anchorBridge.tick(state: anchorEngine)
        require(
            anchorTick.bobombAnchorMarioEffects.first?.objectID == anchor
                && anchorTick.bobombAnchorMarioEffects.first?.output.parentRelativePosition == .init(x: 100, y: 0, z: 150)
                && anchorTick.bobombAnchorMarioEffects.first?.output.throwForwardVelocity == 50,
            "Bob-omb Mario anchor transform/throw route"
        )
        let cageEngine = SM64SwiftEngineState(objectCapacity: 8)
        let cageBridge = SM64BehaviorDispatchBridge()
        let cageBoo = try cageBridge.spawnBooWithCage(in: cageEngine, totalStars: 12)
        require(SM64BehaviorDispatchBridge.route(for: SM64BooObjectBridge.withCageBehaviorIdentity) == .boo, "Boo-with-cage identity route")
        require(cageBridge.boo.setInput(SM64BooTickInput(distanceToMario: 300, randomValue: 3), for: cageBoo), "Boo-with-cage chase input")
        let cageTick = cageBridge.tick(state: cageEngine)
        require(
            cageTick.booEffects.first { $0.objectID == cageBoo }?.action == .chase
                && cageEngine.objects.record(for: cageBoo)?.hitboxRadius == 180
                && cageEngine.objects.record(for: cageBoo)?.scale.x == 2,
            "Boo-with-cage shared kernel/scale route"
        )
        require(cageTick.booCageEffects.count == 1, "Boo-with-cage child allocation route")
        let bubEngine = SM64SwiftEngineState(objectCapacity: 32)
        let bubBridge = SM64BehaviorDispatchBridge()
        let bubSpawner = try bubBridge.spawnBubSpawner(in: bubEngine, childCount: 2, position: .init(x: 10, y: 20, z: 30))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BubObjectBridge.bubBehaviorIdentity) == .bub
                && SM64BehaviorDispatchBridge.route(for: SM64BubObjectBridge.chirpChirpBehaviorIdentity) == .bub
                && SM64BehaviorDispatchBridge.route(for: SM64BubObjectBridge.chirpChirpUnusedBehaviorIdentity) == .bub,
            "Bub/spawner identity routes"
        )
        _ = bubEngine.objects.mutate(bubSpawner) { $0.distanceToMario = 100 }
        let bubTick = bubBridge.tick(state: bubEngine)
        require(
            bubTick.bubEffects.first { $0.objectID == bubSpawner }?.spawnedChildren.count == 2,
            "Bub spawner child allocation route"
        )
        let bubChildTick = bubBridge.tick(state: bubEngine)
        require(bubChildTick.bubEffects.filter { $0.output.role == .bub }.count == 2, "Bub children execute in general-actor order")
        let bubbaEngine = SM64SwiftEngineState(objectCapacity: 16)
        let bubbaBridge = SM64BehaviorDispatchBridge()
        let bubba = try bubbaBridge.spawnBubba(in: bubbaEngine, position: .init(x: 40, y: 150, z: 60))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BubbaObjectBridge.defaultBehaviorIdentity) == .bubba,
            "Bubba identity route"
        )
        _ = bubbaEngine.objects.mutate(bubba) { record in
            record.timer = 31
            record.distanceToMario = 1_000
        }
        let bubbaWakeTick = bubbaBridge.tick(state: bubbaEngine)
        require(bubbaWakeTick.bubbaEffects.first?.output.action == 1, "Bubba patrol-to-attack transition")
        require(
            bubbaBridge.bubba.setInput(
                distanceToMario: 400,
                nearAndFacingMario: true,
                pitchAligned: true,
                for: bubba
            ),
            "Bubba bite input"
        )
        let bubbaBiteTick = bubbaBridge.tick(state: bubbaEngine)
        require(
            bubbaBiteTick.bubbaEffects.first?.output.attackTimer == 30
                && bubbaBiteTick.bubbaEffects.first?.output.animationState == 1
                && bubbaEngine.objects.record(for: bubba)?.interactionType == SM64BubbaObjectBridge.interactionType,
            "Bubba attack/hitbox owner route"
        )
        let bowlingEngine = SM64SwiftEngineState(objectCapacity: 32)
        let bowlingBridge = SM64BehaviorDispatchBridge()
        let bowlingSpawner = try bowlingBridge.spawnBobBowlingBallSpawner(in: bowlingEngine, behaviorParam: 0, position: .init(x: 10, y: 100, z: 20))
        let ttmBowlingSpawner = try bowlingBridge.spawnTtmBowlingBallSpawner(in: bowlingEngine, behaviorParam: 1, position: .init(x: 20, y: 100, z: 20))
        let thiBowlingSpawner = try bowlingBridge.spawnThiBowlingBallSpawner(in: bowlingEngine, behaviorParam: 3, position: .init(x: 30, y: 100, z: 20))
        let freeBowling = try bowlingBridge.spawnFreeBowlingBall(in: bowlingEngine, position: .init(x: 30, y: 40, z: 50))
        let pitBowling = try bowlingBridge.spawnPitBowlingBall(in: bowlingEngine, position: .init(x: 40, y: 40, z: 50))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BowlingBallObjectBridge.bobBowlingBallSpawnerBehaviorIdentity) == .bowlingBall
                && SM64BehaviorDispatchBridge.route(for: SM64BowlingBallObjectBridge.ttmBowlingBallSpawnerBehaviorIdentity) == .bowlingBall
                && SM64BehaviorDispatchBridge.route(for: SM64BowlingBallObjectBridge.thiBowlingBallSpawnerBehaviorIdentity) == .bowlingBall
                && SM64BehaviorDispatchBridge.route(for: SM64BowlingBallObjectBridge.pitBowlingBallBehaviorIdentity) == .bowlingBall
                && SM64BehaviorDispatchBridge.route(for: SM64BowlingBallObjectBridge.bowlingBallBehaviorIdentity) == .bowlingBall
                && SM64BehaviorDispatchBridge.route(for: SM64BowlingBallObjectBridge.freeBowlingBallBehaviorIdentity) == .bowlingBall,
            "bowling-ball identity routes"
        )
        _ = bowlingEngine.objects.mutate(bowlingSpawner) { record in
            record.timer = 0
            record.distanceToMario = 5_000
        }
        require(
            bowlingBridge.bowlingBall.setInput(distanceToMario: 5_000, spawnAdmission: true, for: bowlingSpawner),
            "bowling-ball spawner admission input"
        )
        _ = bowlingEngine.objects.mutate(ttmBowlingSpawner) { record in record.timer = 0; record.distanceToMario = 5_000 }
        _ = bowlingEngine.objects.mutate(thiBowlingSpawner) { record in record.timer = 0; record.distanceToMario = 5_000 }
        require(
            bowlingBridge.bowlingBall.setInput(distanceToMario: 5_000, spawnAdmission: true, for: ttmBowlingSpawner)
                && bowlingBridge.bowlingBall.setInput(distanceToMario: 5_000, spawnAdmission: true, for: thiBowlingSpawner),
            "TTM/THI bowling-ball spawner admission input"
        )
        require(bowlingBridge.bowlingBall.setInput(floorFlat: true, for: pitBowling), "pit bowling-ball floor input")
        let bowlingSpawnTick = bowlingBridge.tick(state: bowlingEngine)
        let spawnedBowlingBall = bowlingSpawnTick.bowlingBallEffects.first { $0.objectID == bowlingSpawner }?.spawnedBall
        require(spawnedBowlingBall != nil, "bowling-ball spawner child allocation route")
        require(
            bowlingSpawnTick.bowlingBallEffects.first { $0.objectID == ttmBowlingSpawner }?.spawnedBall != nil
                && bowlingSpawnTick.bowlingBallEffects.first { $0.objectID == thiBowlingSpawner }?.spawnedBall != nil,
            "TTM/THI bowling-ball spawner child allocation routes"
        )
        require(
            bowlingSpawnTick.bowlingBallEffects.first { $0.objectID == pitBowling }?.output.forwardVelocity == 28
                && bowlingSpawnTick.bowlingBallEffects.first { $0.objectID == pitBowling }?.output.cameraShake == true
                && bowlingSpawnTick.bowlingBallEffects.first { $0.objectID == pitBowling }?.output.playRollSound == true,
            "pit bowling-ball physics/effect route"
        )
        require(bowlingBridge.bowlingBall.setInput(distanceToMario: 2_000, for: freeBowling), "free bowling-ball wake input")
        let freeWakeTick = bowlingBridge.tick(state: bowlingEngine)
        require(freeWakeTick.bowlingBallEffects.first { $0.objectID == freeBowling }?.output.action == 1, "free bowling-ball wake route")
        _ = bowlingEngine.objects.mutate(freeBowling) { $0.forwardVelocity = 15 }
        require(bowlingBridge.bowlingBall.setInput(distanceToMario: 7_000, for: freeBowling), "free bowling-ball reset input")
        let freeResetTick = bowlingBridge.tick(state: bowlingEngine)
        require(
            freeResetTick.bowlingBallEffects.first { $0.objectID == freeBowling }?.output.resetToHome == true
                && bowlingEngine.objects.record(for: freeBowling)?.activeFlags != 0,
            "free bowling-ball reset/intangible route"
        )
        let dddPoleEngine = SM64SwiftEngineState(objectCapacity: 8)
        let dddPoleBridge = SM64BehaviorDispatchBridge()
        let dddPole = try dddPoleBridge.spawnDDDPole(in: dddPoleEngine, behaviorParam: 1, saveUnlocked: true)
        let lockedDddPole = try dddPoleBridge.spawnDDDPole(in: dddPoleEngine, behaviorParam: 1, saveUnlocked: false)
        require(SM64BehaviorDispatchBridge.route(for: SM64DDDPoleObjectBridge.defaultBehaviorIdentity) == .dddPole, "DDD pole identity route")
        _ = dddPoleEngine.objects.mutate(dddPole) { record in
            record.timer = 21
            record.graphYOffset = 95
            record.forwardVelocity = 10
        }
        let dddPoleTick = dddPoleBridge.tick(state: dddPoleEngine)
        require(
            dddPoleTick.dddPoleEffects.first { $0.objectID == dddPole }?.output.bounced == true
                && dddPoleTick.dddPoleEffects.first { $0.objectID == dddPole }?.output.offset == 100
                && dddPoleTick.dddPoleEffects.first { $0.objectID == lockedDddPole }?.output.shouldDelete == true,
            "DDD pole oscillation/bounce route"
        )
        let donutEngine = SM64SwiftEngineState(objectCapacity: 64)
        let donutBridge = SM64BehaviorDispatchBridge()
        let donutSpawner = try donutBridge.spawnDonutPlatformSpawner(in: donutEngine, position: .init(x: 100, y: 200, z: 300))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64DonutPlatformObjectBridge.spawnerBehaviorIdentity) == .donutPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64DonutPlatformObjectBridge.platformBehaviorIdentity) == .donutPlatform,
            "Donut Platform identity routes"
        )
        require(donutBridge.donutPlatform.setSpawnerSpawnMask(0b11, for: donutSpawner), "Donut Platform spawn mask input")
        let donutSpawnTick = donutBridge.tick(state: donutEngine)
        let donutChildren = donutSpawnTick.donutPlatformEffects.first { $0.objectID == donutSpawner }?.spawnedPlatforms ?? []
        require(donutChildren.count == 2, "Donut Platform two-child spawn route")
        let donutChild = donutChildren[0]
        _ = donutEngine.objects.mutate(donutChild) { record in
            record.timer = 1
            record.gravity = -0.1
        }
        require(donutBridge.donutPlatform.setPlatformInput(distanceToMario: 3_000, for: donutChild), "Donut Platform distance input")
        let donutDeleteTick = donutBridge.tick(state: donutEngine)
        require(donutDeleteTick.donutPlatformEffects.first { $0.objectID == donutChild }?.output.shouldDelete == true, "Donut Platform far deletion route")
        let courtyardEngine = SM64SwiftEngineState(objectCapacity: 16)
        let courtyardBridge = SM64BehaviorDispatchBridge()
        let courtyard = try courtyardBridge.spawnCourtyardBooTriplet(in: courtyardEngine, totalStars: 12, position: .init(x: 50, y: 60, z: 70))
        require(SM64BehaviorDispatchBridge.route(for: SM64CourtyardBooTripletObjectBridge.defaultBehaviorIdentity) == .courtyardBooTriplet, "courtyard Boo triplet identity route")
        let courtyardTick = courtyardBridge.tick(state: courtyardEngine)
        require(
            courtyardTick.courtyardBooTripletEffects.first { $0.objectID == courtyard }?.spawnedChildren.count == 3
                && courtyardBridge.boo.registeredIDs.count == 3,
            "courtyard Boo triplet three-child route"
        )
        let lockedCourtyardEngine = SM64SwiftEngineState(objectCapacity: 8)
        let lockedCourtyardBridge = SM64BehaviorDispatchBridge()
        let lockedCourtyard = try lockedCourtyardBridge.spawnCourtyardBooTriplet(in: lockedCourtyardEngine, totalStars: 11)
        let lockedCourtyardTick = lockedCourtyardBridge.tick(state: lockedCourtyardEngine)
        require(lockedCourtyardTick.courtyardBooTripletEffects.first { $0.objectID == lockedCourtyard }?.spawnedChildren.isEmpty == true, "courtyard Boo triplet star gate route")
        let fallingBowserEngine = SM64SwiftEngineState(objectCapacity: 8)
        let fallingBowserBridge = SM64BehaviorDispatchBridge()
        let fallingPlatform = try fallingBowserBridge.spawnFallingBowserPlatform(in: fallingBowserEngine, variant: 2)
        require(SM64BehaviorDispatchBridge.route(for: SM64FallingBowserPlatformObjectBridge.defaultBehaviorIdentity) == .fallingBowserPlatform, "falling Bowser platform identity route")
        require(fallingBowserBridge.fallingBowserPlatform.setBowserInput(bowserPresent: true, for: fallingPlatform), "falling Bowser platform presence input")
        let fallingActivationTick = fallingBowserBridge.tick(state: fallingBowserEngine)
        require(fallingActivationTick.fallingBowserPlatformEffects.first?.output.action == 1, "falling Bowser platform activation route")
        require(
            fallingBowserBridge.fallingBowserPlatform.setBowserInput(bowserOnPlatform: true, bowserAction: 13, bowserFireFlag: true, for: fallingPlatform),
            "falling Bowser platform trigger input"
        )
        let fallingTriggerTick = fallingBowserBridge.tick(state: fallingBowserEngine)
        require(fallingTriggerTick.fallingBowserPlatformEffects.first?.output.action == 2, "falling Bowser platform fall trigger route")
        let fallingMotionTick = fallingBowserBridge.tick(state: fallingBowserEngine)
        require(fallingMotionTick.fallingBowserPlatformEffects.first?.output.cameraShake == true, "falling Bowser platform shake/fall route")
        let giantPoleEngine = SM64SwiftEngineState(objectCapacity: 8)
        let giantPoleBridge = SM64BehaviorDispatchBridge()
        let giantPole = try giantPoleBridge.spawnGiantPole(in: giantPoleEngine, position: .init(x: 10, y: 20, z: 30), hitboxHeight: 2_100)
        require(SM64BehaviorDispatchBridge.route(for: SM64GiantPoleObjectBridge.defaultBehaviorIdentity) == .giantPole, "Giant Pole identity route")
        let giantPoleTick = giantPoleBridge.tick(state: giantPoleEngine)
        let topBall = giantPoleTick.giantPoleEffects.first { $0.objectID == giantPole }?.spawnedTopBall
        require(
            topBall != nil
                && giantPoleEngine.objects.record(for: topBall!)?.position == .init(x: 10, y: 2_170, z: 30)
                && giantPoleEngine.objects.record(for: giantPole)?.hitboxHeight == 2_100,
            "Giant Pole top-ball/height route"
        )
        let koopaFlagEngine = SM64SwiftEngineState(objectCapacity: 8)
        let koopaFlagBridge = SM64BehaviorDispatchBridge()
        let koopaFlag = try koopaFlagBridge.spawnKoopaFlag(in: koopaFlagEngine, hitboxHeight: 700)
        require(SM64BehaviorDispatchBridge.route(for: SM64KoopaFlagObjectBridge.defaultBehaviorIdentity) == .giantPole, "Koopa Flag shared pole route")
        _ = koopaFlagEngine.objects.mutate(koopaFlag) { $0.timer = 11 }
        require(koopaFlagBridge.koopaFlag.setMario(marioY: 300, punching: false, for: koopaFlag), "Koopa Flag collision input")
        let koopaFlagTick = koopaFlagBridge.tick(state: koopaFlagEngine)
        require(koopaFlagTick.koopaFlagEffects.first?.output.pushMarioAway == true, "Koopa Flag push route")
        require(koopaFlagBridge.koopaFlag.setMario(marioY: 300, punching: true, for: koopaFlag), "Koopa Flag punch input")
        let koopaFlagPunchTick = koopaFlagBridge.tick(state: koopaFlagEngine)
        require(koopaFlagPunchTick.koopaFlagEffects.first?.output.pushMarioAway == false, "Koopa Flag punch exemption route")
        let poleGrabbing = try koopaFlagBridge.spawnPoleGrabbing(in: koopaFlagEngine, hitboxHeight: 1_500)
        let tree = try koopaFlagBridge.spawnTree(in: koopaFlagEngine, hitboxHeight: 500)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64KoopaFlagObjectBridge.poleGrabbingBehaviorIdentity) == .giantPole
                && SM64BehaviorDispatchBridge.route(for: SM64KoopaFlagObjectBridge.treeBehaviorIdentity) == .giantPole,
            "shared pole-base identity routes"
        )
        _ = koopaFlagEngine.objects.mutate(poleGrabbing) { $0.timer = 11 }
        _ = koopaFlagEngine.objects.mutate(tree) { $0.timer = 11 }
        require(koopaFlagBridge.koopaFlag.setMario(marioY: 300, punching: false, for: poleGrabbing), "pole-grabbing input")
        require(koopaFlagBridge.koopaFlag.setMario(marioY: 300, punching: false, for: tree), "tree pole input")
        let sharedPoleTick = koopaFlagBridge.tick(state: koopaFlagEngine)
        require(
            sharedPoleTick.koopaFlagEffects.first { $0.objectID == poleGrabbing }?.output.pushMarioAway == true
                && sharedPoleTick.koopaFlagEffects.first { $0.objectID == tree }?.output.pushMarioAway == true
                && koopaFlagEngine.objects.record(for: poleGrabbing)?.hitboxHeight == 1_500
                && koopaFlagEngine.objects.record(for: tree)?.hitboxHeight == 500,
            "shared pole-base height/push routes"
        )
        let koopaRaceEngine = SM64SwiftEngineState(objectCapacity: 8)
        let koopaRaceBridge = SM64BehaviorDispatchBridge()
        let koopaRace = try koopaRaceBridge.spawnKoopaRaceEndpoint(in: koopaRaceEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64KoopaRaceEndpointObjectBridge.defaultBehaviorIdentity) == .giantPole, "Koopa race endpoint shared pole route")
        require(koopaRaceBridge.koopaRaceEndpoint.setRaceState(raceBegun: true, distanceToMario: 300, for: koopaRace), "Koopa race endpoint race input")
        let koopaRaceTick = koopaRaceBridge.tick(state: koopaRaceEngine)
        require(
            koopaRaceTick.koopaRaceEndpointEffects.first?.output.raceEnded == true
                && koopaRaceTick.koopaRaceEndpointEffects.first?.output.raceStatus == 1
                && koopaRaceTick.koopaRaceEndpointEffects.first?.output.playFanfare == true
                && koopaRaceTick.koopaRaceEndpointEffects.first?.spawnedFlag != nil
                && koopaRaceEngine.objects.record(for: koopaRace)?.action == 1,
            "Koopa race endpoint completion route"
        )
        let endActorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let endActorBridge = SM64BehaviorDispatchBridge()
        let endPeach = try endActorBridge.spawnEndPeach(in: endActorEngine)
        let endToad = try endActorBridge.spawnEndToad(in: endActorEngine, position: .init(x: -10, y: 0, z: 0))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64EndCutsceneActorObjectBridge.endPeachBehaviorIdentity) == .endCutsceneActor
                && SM64BehaviorDispatchBridge.route(for: SM64EndCutsceneActorObjectBridge.endToadBehaviorIdentity) == .endCutsceneActor,
            "end cutscene actor identity routes"
        )
        _ = endActorEngine.objects.mutate(endPeach) { $0.animationState = 2 }
        _ = endActorEngine.objects.mutate(endToad) { $0.animationState = 2 }
        require(endActorBridge.endCutsceneActor.setNearAnimationEnd(true, for: endPeach), "ending Peach animation input")
        require(endActorBridge.endCutsceneActor.setNearAnimationEnd(true, for: endToad), "ending Toad animation input")
        let endActorTick = endActorBridge.tick(state: endActorEngine)
        require(
            endActorTick.endCutsceneActorEffects.first { $0.objectID == endPeach }?.output.animationIndex == 3
                && endActorTick.endCutsceneActorEffects.first { $0.objectID == endToad }?.output.animationIndex == 3,
            "end cutscene animation progression route"
        )
        let endBirdEngine = SM64SwiftEngineState(objectCapacity: 12)
        let endBirdBridge = SM64BehaviorDispatchBridge()
        let endBirds1 = try endBirdBridge.spawnEndBirds1(in: endBirdEngine)
        let endBirds2 = try endBirdBridge.spawnEndBirds2(in: endBirdEngine, targetPosition: .init(x: 0, y: 0, z: 14_000))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64EndBirdsObjectBridge.birds1BehaviorIdentity) == .endCutsceneActor
                && SM64BehaviorDispatchBridge.route(for: SM64EndBirdsObjectBridge.birds2BehaviorIdentity) == .endCutsceneActor,
            "end birds shared cutscene route"
        )
        let endBirdInitTick = endBirdBridge.tick(state: endBirdEngine)
        require(
            endBirdInitTick.endBirdsEffects.first { $0.objectID == endBirds1 }?.output.action == 1
                && endBirdInitTick.endBirdsEffects.first { $0.objectID == endBirds2 }?.output.action == 1,
            "end birds initialization route"
        )
        require(endBirdBridge.endBirds.setCutsceneTimer(0, for: endBirds1), "end birds deletion timer input")
        let endBirdDeleteTick = endBirdBridge.tick(state: endBirdEngine)
        require(endBirdDeleteTick.endBirdsEffects.first { $0.objectID == endBirds1 }?.output.shouldDelete == true, "end birds one-shot deletion route")
        let beginningPeachEngine = SM64SwiftEngineState(objectCapacity: 8)
        let beginningPeachBridge = SM64BehaviorDispatchBridge()
        let beginningPeach = try beginningPeachBridge.spawnBeginningPeach(in: beginningPeachEngine, cameraTargetPosition: .init(x: 100, y: 200, z: 300))
        require(SM64BehaviorDispatchBridge.route(for: SM64BeginningPeachObjectBridge.defaultBehaviorIdentity) == .endCutsceneActor, "Beginning Peach shared cutscene route")
        _ = beginningPeachEngine.objects.mutate(beginningPeach) { record in
            record.action = 1
            record.timer = 21
            record.opacity = 255
        }
        let beginningPeachTick = beginningPeachBridge.tick(state: beginningPeachEngine)
        require(
            beginningPeachTick.beginningPeachEffects.first?.output.action == 2
                && beginningPeachTick.beginningPeachEffects.first?.output.opacity == 0
                && beginningPeachEngine.objects.record(for: beginningPeach)?.position == .init(x: 100, y: 200, z: 300),
            "Beginning Peach opacity/camera route"
        )
        let bookshelfEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bookshelfBridge = SM64BehaviorDispatchBridge()
        let bookshelf = try bookshelfBridge.spawnHauntedBookshelf(in: bookshelfEngine, position: .init(x: 10, y: 20, z: 30))
        require(SM64BehaviorDispatchBridge.route(for: SM64HauntedBookshelfObjectBridge.defaultBehaviorIdentity) == .bookSwitch, "haunted bookshelf shared book route")
        require(bookshelfBridge.hauntedBookshelf.setShouldOpen(true, for: bookshelf), "haunted bookshelf open input")
        let bookshelfOpenTick = bookshelfBridge.tick(state: bookshelfEngine)
        require(bookshelfOpenTick.hauntedBookshelfEffects.first?.output.action == 1, "haunted bookshelf recede admission route")
        _ = bookshelfEngine.objects.mutate(bookshelf) { record in record.timer = 102 }
        let bookshelfDeleteTick = bookshelfBridge.tick(state: bookshelfEngine)
        require(bookshelfDeleteTick.hauntedBookshelfEffects.first?.output.shouldDelete == true, "haunted bookshelf retirement route")
        let bookshelfManagerEngine = SM64SwiftEngineState(objectCapacity: 24)
        let bookshelfManagerBridge = SM64BehaviorDispatchBridge()
        let managerShelf = try bookshelfManagerBridge.spawnHauntedBookshelf(in: bookshelfManagerEngine, position: .init(x: 100, y: 0, z: 0))
        let manager = try bookshelfManagerBridge.spawnHauntedBookshelfManager(in: bookshelfManagerEngine, shelf: managerShelf)
        require(SM64BehaviorDispatchBridge.route(for: SM64HauntedBookshelfManagerObjectBridge.defaultBehaviorIdentity) == .bookSwitch, "haunted bookshelf manager shared book route")
        let managerSpawnTick = bookshelfManagerBridge.tick(state: bookshelfManagerEngine)
        require(managerSpawnTick.hauntedBookshelfManagerEffects.first { $0.objectID == manager }?.spawnedSwitches.count == 3, "haunted bookshelf manager switch allocation route")
        _ = bookshelfManagerEngine.objects.mutate(manager) { record in record.action = 2; record.timer = 101 }
        require(bookshelfManagerBridge.hauntedBookshelfManager.setInput(sequence: 3, for: manager), "haunted bookshelf manager solved sequence input")
        let managerSolvedTick = bookshelfManagerBridge.tick(state: bookshelfManagerEngine)
        require(managerSolvedTick.hauntedBookshelfManagerEffects.first { $0.objectID == manager }?.output.openShelf == true, "haunted bookshelf manager shelf-open route")
        let chairEngine = SM64SwiftEngineState(objectCapacity: 8)
        let chairBridge = SM64BehaviorDispatchBridge()
        let chair = try chairBridge.spawnHauntedChair(in: chairEngine, hasPianoParent: false)
        require(SM64BehaviorDispatchBridge.route(for: SM64HauntedChairObjectBridge.defaultBehaviorIdentity) == .bookSwitch, "haunted chair shared book route")
        _ = chairEngine.objects.mutate(chair) { $0.timer = 31 }
        let chairRiseTick = chairBridge.tick(state: chairEngine)
        require(chairRiseTick.hauntedChairEffects.first?.output.action == 1, "haunted chair lift admission route")
        _ = chairEngine.objects.mutate(chair) { $0.timer = 70 }
        require(chairBridge.hauntedChair.setInput(launchCountdown: 1, for: chair), "haunted chair launch input")
        let chairLaunchTick = chairBridge.tick(state: chairEngine)
        require(chairLaunchTick.hauntedChairEffects.first?.output.playLaunchSound == true && chairLaunchTick.hauntedChairEffects.first?.output.forwardVelocity == 50, "haunted chair launch route")
        let butterflyEngine = SM64SwiftEngineState(objectCapacity: 8)
        let butterflyBridge = SM64BehaviorDispatchBridge()
        let butterfly = try butterflyBridge.spawnButterfly(in: butterflyEngine, position: .zero)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ButterflyObjectBridge.defaultBehaviorIdentity) == .butterfly,
            "butterfly identity route"
        )
        require(butterflyBridge.butterfly.setInput(distanceToMario: 500, homeDistance: 0, angleToMario: 0, for: butterfly), "butterfly follow input")
        let butterflyRestTick = butterflyBridge.tick(state: butterflyEngine)
        require(
            butterflyRestTick.butterflyEffects.first?.output.action == .followMario,
            "butterfly rest-to-follow transition"
        )
        require(butterflyBridge.butterfly.setInput(distanceToMario: 500, homeDistance: 0, angleToMario: 0, for: butterfly), "butterfly movement input")
        let butterflyFollowTick = butterflyBridge.tick(state: butterflyEngine)
        require(butterflyFollowTick.butterflyEffects.first?.output.action == .followMario && butterflyEngine.objects.record(for: butterfly)?.position.z == 7, "butterfly follow movement route")
        require(butterflyBridge.butterfly.setInput(distanceToMario: 500, homeDistance: 1300, angleToMario: 0, angleToHome: 0x2000, for: butterfly), "butterfly return input")
        let butterflyReturnTick = butterflyBridge.tick(state: butterflyEngine)
        require(butterflyReturnTick.butterflyEffects.first?.output.action == .returnHome, "butterfly return-home transition")
        let tiltEngine = SM64SwiftEngineState(objectCapacity: 8)
        let tiltBridge = SM64BehaviorDispatchBridge()
        let bitfsTilt = try tiltBridge.spawnTiltingPyramid(in: tiltEngine, variant: .bitfs)
        let anotherTilt = try tiltBridge.spawnTiltingPyramid(in: tiltEngine, variant: .another)
        let lllTilt = try tiltBridge.spawnTiltingPyramid(in: tiltEngine, variant: .lll)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TiltingPyramidObjectBridge.bitfsBehaviorIdentity) == .tiltingPyramid
                && SM64BehaviorDispatchBridge.route(for: SM64TiltingPyramidObjectBridge.anotherBehaviorIdentity) == .tiltingPyramid
                && SM64BehaviorDispatchBridge.route(for: SM64TiltingPyramidObjectBridge.lllBehaviorIdentity) == .tiltingPyramid,
            "tilting-pyramid identity routes"
        )
        require(tiltBridge.tiltingPyramid.setMarioOn(true, for: bitfsTilt), "tilting-pyramid Mario input")
        let tiltTick = tiltBridge.tick(state: tiltEngine)
        require(
            (tiltTick.tiltingPyramidEffects.first { $0.objectID == bitfsTilt }?.output.normalY ?? -1) > 0
                && tiltTick.tiltingPyramidEffects.first { $0.objectID == bitfsTilt }?.output.collisionLoaded == true
                && tiltTick.tiltingPyramidEffects.first { $0.objectID == anotherTilt }?.output.collisionLoaded == false
                && tiltTick.tiltingPyramidEffects.first { $0.objectID == lllTilt }?.output.collisionLoaded == true,
            "tilting-pyramid normals/collision variants"
        )
        let bookendEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bookendBridge = SM64BehaviorDispatchBridge()
        let bookendSpawner = try bookendBridge.spawnBookendSpawner(in: bookendEngine, position: .zero)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BookendObjectBridge.spawnerBehaviorIdentity) == .bookend
                && SM64BehaviorDispatchBridge.route(for: SM64BookendObjectBridge.flyingBehaviorIdentity) == .bookend,
            "bookend identity routes"
        )
        _ = bookendEngine.objects.mutate(bookendSpawner) { record in record.timer = 41; record.distanceToMario = 500 }
        require(bookendBridge.bookend.setSpawnerInput(distanceToMario: 500, facingMario: true, for: bookendSpawner), "bookend spawn input")
        let bookendTick = bookendBridge.tick(state: bookendEngine)
        require(bookendTick.bookendEffects.first { $0.objectID == bookendSpawner }?.spawnedChild != nil, "bookend proximity spawn route")
        let bookendChildTick = bookendBridge.tick(state: bookendEngine)
        require(bookendChildTick.bookendEffects.contains { $0.output.role == .flying }, "flying bookend child route")
        let switchEngine = SM64SwiftEngineState(objectCapacity: 8)
        let switchBridge = SM64BehaviorDispatchBridge()
        let bookSwitch = try switchBridge.spawnBookSwitch(in: switchEngine, behaviorParam: 0)
        require(SM64BehaviorDispatchBridge.route(for: SM64BookSwitchObjectBridge.defaultBehaviorIdentity) == .bookSwitch, "book-switch identity route")
        require(switchBridge.bookSwitch.setInput(parentSequence: 0, parentEnabled: true, distanceToMario: 50, for: bookSwitch), "book-switch enable input")
        let switchTick = switchBridge.tick(state: switchEngine)
        require(switchTick.bookSwitchEffects.first?.output.action == 1 && switchTick.bookSwitchEffects.first?.output.progress == 20, "book-switch depression route")
        _ = switchEngine.objects.mutate(bookSwitch) { $0.action = 2 }
        require(switchBridge.bookSwitch.setInput(parentSequence: 1, parentEnabled: false, distanceToMario: 500, for: bookSwitch), "book-switch failure input")
        let switchFailureTick = switchBridge.tick(state: switchEngine)
        require(switchFailureTick.bookSwitchEffects.first?.spawnedBookend != nil, "book-switch failure bookend route")
        let fishEngine = SM64SwiftEngineState(objectCapacity: 32)
        let fishBridge = SM64BehaviorDispatchBridge()
        let fishGroup = try fishBridge.spawnFishGroup(in: fishEngine, variant: .blue5, position: .init(x: 10, y: 20, z: 30), distanceToMario: 100)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FishObjectBridge.fishBehaviorIdentity) == .fish
                && SM64BehaviorDispatchBridge.route(for: SM64FishObjectBridge.fish2BehaviorIdentity) == .fish
                && SM64BehaviorDispatchBridge.route(for: SM64FishObjectBridge.fish3BehaviorIdentity) == .fish
                && SM64BehaviorDispatchBridge.route(for: SM64FishObjectBridge.fishGroupBehaviorIdentity) == .fish
                && SM64BehaviorDispatchBridge.route(for: SM64FishObjectBridge.largeFishGroupBehaviorIdentity) == .fish,
            "fish/group identity routes"
        )
        let fishTick = fishBridge.tick(state: fishEngine)
        require(fishTick.fishEffects.first { $0.objectID == fishGroup }?.spawnedChildren.count == 5, "fish group five-child allocation route")
        let fishChildTick = fishBridge.tick(state: fishEngine)
        require(fishChildTick.fishEffects.filter { $0.role == .fish }.count == 5, "fish children execute in list order")
        let barrelEngine = SM64SwiftEngineState(objectCapacity: 8)
        let barrelBridge = SM64BehaviorDispatchBridge()
        let barrelParent = try barrelEngine.spawnObject(in: .level, behaviorIdentity: 0x43414E4E)
        _ = barrelEngine.objects.mutate(barrelParent) { record in
            record.position = .init(x: 4, y: 5, z: 6)
            record.moveAngles.yaw = 0x2000
            record.faceAngles.pitch = 0x1000
        }
        let barrel = try barrelBridge.spawnCannonBarrel(in: barrelEngine, parent: barrelParent)
        require(SM64BehaviorDispatchBridge.route(for: SM64CannonBarrelObjectBridge.defaultBehaviorIdentity) == .cannonBarrel, "cannon-barrel identity route")
        let barrelTick = barrelBridge.tick(state: barrelEngine)
        require(
            barrelTick.cannonBarrelEffects.first?.objectID == barrel
                && barrelEngine.objects.record(for: barrel)?.position == .init(x: 4, y: 5, z: 6)
                && barrelEngine.objects.record(for: barrel)?.moveAngles.yaw == 0x2000,
            "cannon-barrel parent copy route"
        )
        _ = barrelEngine.objects.mutate(barrelParent) { $0.activeFlags = 0 }
        let barrelHiddenTick = barrelBridge.tick(state: barrelEngine)
        require(barrelHiddenTick.cannonBarrelEffects.first?.output.visible == false, "cannon-barrel parent deactivation route")
        let cannonEngine = SM64SwiftEngineState(objectCapacity: 8)
        let cannonBridge = SM64BehaviorDispatchBridge()
        let cannon = try cannonBridge.spawnCannon(in: cannonEngine, behaviorByte: 2)
        require(SM64BehaviorDispatchBridge.route(for: SM64CannonObjectBridge.defaultBehaviorIdentity) == .cannon, "cannon identity route")
        require(cannonBridge.cannon.setInput(distanceToMario: 300, interacted: true, for: cannon), "cannon interaction input")
        let cannonTick = cannonBridge.tick(state: cannonEngine)
        require(cannonTick.cannonEffects.first?.objectID == cannon && cannonTick.cannonEffects.first?.output.action == 4 && cannonTick.cannonEffects.first?.output.interactionAccepted == true, "cannon open interaction route")
        let merryManagerEngine = SM64SwiftEngineState(objectCapacity: 16)
        let merryManagerBridge = SM64BehaviorDispatchBridge()
        let merryManager = try merryManagerBridge.spawnMerryGoRoundBooManager(in: merryManagerEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64MerryGoRoundBooManagerObjectBridge.defaultBehaviorIdentity) == .merryGoRoundBooManager, "merry-go-round Boo manager identity route")
        _ = merryManagerEngine.objects.mutate(merryManager) { $0.distanceToMario = 500 }
        let merrySpawnTick = merryManagerBridge.tick(state: merryManagerEngine)
        require(merrySpawnTick.merryGoRoundBooManagerEffects.first?.spawnedChildren.count == 1, "merry-go-round Boo small spawn route")
        require(merryManagerBridge.merryGoRoundBooManager.setBoosKilled(5, for: merryManager), "merry-go-round Boo kill count input")
        _ = merryManagerEngine.objects.mutate(merryManager) { $0.action = 0; $0.distanceToMario = 500 }
        let merryGoalTick = merryManagerBridge.tick(state: merryManagerEngine)
        require(merryGoalTick.merryGoRoundBooManagerEffects.first?.output.spawnBigBoo == true, "merry-go-round Boo goal spawn route")

        let movingCoinEngine = SM64SwiftEngineState(objectCapacity: 16)
        let movingCoinBridge = SM64BehaviorDispatchBridge()
        let movingYellow = try movingCoinBridge.spawnMovingCoin(in: movingCoinEngine, kind: .yellow)
        let movingBlue = try movingCoinBridge.spawnMovingCoin(in: movingCoinEngine, kind: .blue, position: SM64ObjectVector3(x: 100, y: 0, z: 0))
        require(
            SM64BehaviorDispatchBridge.route(for: SM64MovingCoinObjectBridge.movingYellowCoinBehaviorIdentity) == .movingCoin
                && SM64BehaviorDispatchBridge.route(for: SM64MovingCoinObjectBridge.movingBlueCoinBehaviorIdentity) == .movingCoin,
            "moving-coin identity routes"
        )
        require(movingCoinBridge.movingCoin.setInputs(grounded: true, for: movingYellow), "moving yellow coin collision input")
        require(movingCoinBridge.movingCoin.setInputs(grounded: true, withinMarioRadius: true, for: movingBlue), "moving blue coin radius input")
        let movingCoinTick = movingCoinBridge.tick(state: movingCoinEngine)
        require(
            movingCoinTick.movingCoinEffects.first { $0.objectID == movingYellow }?.output.soundCoinDrop == true
                && movingCoinTick.movingCoinEffects.first { $0.objectID == movingBlue }?.output.action == 1,
            "moving-coin collision/admission route is preserved"
        )
        let blueSliding = try movingCoinBridge.spawnMovingCoin(in: movingCoinEngine, kind: .blueSliding)
        let blueJumping = try movingCoinBridge.spawnMovingCoin(in: movingCoinEngine, kind: .blueJumping)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64MovingCoinObjectBridge.blueCoinSlidingBehaviorIdentity) == .movingCoin
                && SM64BehaviorDispatchBridge.route(for: SM64MovingCoinObjectBridge.blueCoinJumpingBehaviorIdentity) == .movingCoin,
            "unused blue-coin motion identity routes"
        )
        require(
            movingCoinBridge.movingCoin.setInputs(
                grounded: false,
                angleToMario: 0x1000,
                withinMario500: true,
                withinMario1000: true,
                for: blueSliding
            ),
            "blue sliding admission input"
        )
        let blueMotionTick = movingCoinBridge.tick(state: movingCoinEngine)
        require(
            blueMotionTick.movingCoinEffects.first { $0.objectID == blueSliding }?.output.action == 1
                && blueMotionTick.movingCoinEffects.first { $0.objectID == blueJumping }?.output.velocityY == 50
                && blueMotionTick.movingCoinEffects.first { $0.objectID == blueJumping }?.output.tangible == false,
            "unused blue-coin sliding/jumping action routes are preserved"
        )

        let waterLevelEngine = SM64SwiftEngineState(objectCapacity: 16)
        let waterLevelBridge = SM64BehaviorDispatchBridge()
        let waterDiamond = try waterLevelBridge.spawnWaterLevelDiamond(in: waterLevelEngine, position: SM64ObjectVector3(x: 0, y: 100, z: 0), currentLevel: 0)
        let waterInitializer = try waterLevelBridge.spawnChangingWaterLevel(in: waterLevelEngine, regionsAvailable: true)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterLevelObjectBridge.diamondBehaviorIdentity) == .waterLevelDiamond
                && SM64BehaviorDispatchBridge.route(for: SM64WaterLevelObjectBridge.initializerBehaviorIdentity) == .changingWaterLevel,
            "water-level identity routes"
        )
        let waterInitTick = waterLevelBridge.tick(state: waterLevelEngine)
        require(
            waterInitTick.waterLevelDiamondEffects.first { $0.objectID == waterDiamond }?.output.faceYaw == 0
                && waterInitTick.changingWaterLevelEffects.first { $0.objectID == waterInitializer }?.output.action == 1,
            "water-level initialization route is preserved"
        )
        for _ in 0..<11 { _ = waterLevelBridge.tick(state: waterLevelEngine) }
        require(waterLevelBridge.waterLevel.setMarioCollision(true, for: waterDiamond), "water-level diamond collision input")
        let waterActivateTick = waterLevelBridge.tick(state: waterLevelEngine)
        require(waterActivateTick.waterLevelDiamondEffects.first { $0.objectID == waterDiamond }?.output.globalChanging == true, "water-level change gate is preserved")
        let waterPillar = try waterLevelBridge.spawnWaterPillar(in: waterLevelEngine, position: SM64ObjectVector3(x: 200, y: 100, z: 0), environmentLevel: 0)
        require(SM64BehaviorDispatchBridge.route(for: SM64WaterPillarObjectBridge.defaultBehaviorIdentity) == .waterPillar, "water-pillar identity route")
        require(waterLevelBridge.waterPillar.setGroundPounded(true, for: waterPillar), "water-pillar ground-pound input")
        let waterPillarTick = waterLevelBridge.tick(state: waterLevelEngine)
        require(
            waterPillarTick.waterPillarEffects.first { $0.objectID == waterPillar }?.output.action == .sinking
                && waterPillarTick.waterPillarEffects.first { $0.objectID == waterPillar }?.output.spawnMist == true,
            "water-pillar sink route is preserved"
        )
        let floorSwitch = try waterLevelBridge.spawnFloorSwitch(in: waterLevelEngine, behaviorByte: 1, position: SM64ObjectVector3(x: 300, y: 0, z: 0), variant: .animates)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FloorSwitchObjectBridge.animatesBehaviorIdentity) == .floorSwitch,
            "floor-switch identity route"
        )
        require(waterLevelBridge.floorSwitch.setMarioState(platformOn: true, lateralDistance: 100, for: floorSwitch), "floor-switch Mario state input")
        let floorPressedTick = waterLevelBridge.tick(state: waterLevelEngine)
        require(floorPressedTick.floorSwitchEffects.first { $0.objectID == floorSwitch }?.output.action == .pressed, "floor-switch press admission route is preserved")
        let animatedFloorSwitch = try waterLevelBridge.spawnAnimatedFloorSwitch(in: waterLevelEngine, behaviorByte: 0, position: SM64ObjectVector3(x: 350, y: 0, z: 0), parent: floorSwitch)
        require(SM64BehaviorDispatchBridge.route(for: SM64AnimatedFloorSwitchObjectBridge.defaultBehaviorIdentity) == .animatedFloorSwitch, "animated floor-switch identity route")
        for _ in 0..<5 { _ = waterLevelBridge.tick(state: waterLevelEngine) }
        let animatedFloorTick = waterLevelBridge.tick(state: waterLevelEngine)
        require(animatedFloorTick.animatedFloorSwitchEffects.first { $0.objectID == animatedFloorSwitch }?.output.animationActive == true, "animated floor-switch child route is preserved")

        let hiddenOneUpEngine = SM64SwiftEngineState(objectCapacity: 24)
        let hiddenOneUpBridge = SM64BehaviorDispatchBridge()
        let hiddenOneUp = try hiddenOneUpBridge.spawnHiddenOneUp(in: hiddenOneUpEngine, role: .hidden, behaviorByte: 1)
        let hiddenOneUpTrigger = try hiddenOneUpBridge.spawnHiddenOneUp(in: hiddenOneUpEngine, role: .trigger)
        let poleSpawner = try hiddenOneUpBridge.spawnHiddenOneUp(in: hiddenOneUpEngine, role: .poleSpawner)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.hiddenBehaviorIdentity) == .hiddenOneUp
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.triggerBehaviorIdentity) == .hiddenOneUp
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.poleSpawnerBehaviorIdentity) == .hiddenOneUp,
            "hidden one-up identity routes"
        )
        require(hiddenOneUpBridge.hiddenOneUp.setTouchedMario(true, for: hiddenOneUpTrigger), "hidden one-up trigger input")
        require(hiddenOneUpBridge.hiddenOneUp.setMarioNear(true, for: poleSpawner), "pole one-up spawner input")
        let hiddenOneUpTick = hiddenOneUpBridge.tick(state: hiddenOneUpEngine)
        require(
            hiddenOneUpTick.hiddenOneUpEffects.first { $0.objectID == hiddenOneUpTrigger }?.output.consumeTrigger == true
                && hiddenOneUpTick.hiddenOneUpEffects.first { $0.objectID == poleSpawner }?.spawnedChildren.count == 3,
            "hidden one-up trigger/spawner routes are preserved"
        )
        require(hiddenOneUpTick.hiddenOneUpEffects.first { $0.objectID == hiddenOneUp }?.output.visible == false, "hidden one-up remains gated until trigger count")

        let regularOneUpEngine = SM64SwiftEngineState(objectCapacity: 24)
        let regularOneUpBridge = SM64BehaviorDispatchBridge()
        let stationaryOneUp = try regularOneUpBridge.spawnHiddenOneUp(in: regularOneUpEngine, role: .oneUp)
        let walkingOneUp = try regularOneUpBridge.spawnHiddenOneUp(in: regularOneUpEngine, role: .walking)
        let runningOneUp = try regularOneUpBridge.spawnHiddenOneUp(in: regularOneUpEngine, role: .runningAway)
        let slidingOneUp = try regularOneUpBridge.spawnHiddenOneUp(in: regularOneUpEngine, role: .sliding)
        let jumpOneUp = try regularOneUpBridge.spawnHiddenOneUp(in: regularOneUpEngine, role: .jumpOnApproach)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.oneUpBehaviorIdentity) == .hiddenOneUp
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.walkingBehaviorIdentity) == .hiddenOneUp
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.runningAwayBehaviorIdentity) == .hiddenOneUp
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.slidingBehaviorIdentity) == .hiddenOneUp
                && SM64BehaviorDispatchBridge.route(for: SM64HiddenOneUpObjectBridge.jumpOnApproachBehaviorIdentity) == .hiddenOneUp,
            "regular one-up identity routes"
        )
        require(regularOneUpBridge.hiddenOneUp.setTouchedMario(true, for: stationaryOneUp), "stationary one-up interaction input")
        require(regularOneUpBridge.hiddenOneUp.setMarioNear(true, for: slidingOneUp), "sliding one-up approach input")
        require(regularOneUpBridge.hiddenOneUp.setMarioNear(true, for: jumpOneUp), "jump one-up approach input")
        let regularOneUpTick = regularOneUpBridge.tick(state: regularOneUpEngine)
        require(
            regularOneUpTick.hiddenOneUpEffects.first { $0.objectID == stationaryOneUp }?.output.shouldDelete == true
                && regularOneUpTick.hiddenOneUpEffects.first { $0.objectID == slidingOneUp }?.output.action == 1
                && regularOneUpTick.hiddenOneUpEffects.first { $0.objectID == jumpOneUp }?.output.action == 1
                && regularOneUpTick.hiddenOneUpEffects.first { $0.objectID == walkingOneUp }?.output.playAppearSound == true
                && regularOneUpTick.hiddenOneUpEffects.first { $0.objectID == runningOneUp }?.output.playAppearSound == true,
            "regular one-up routes are preserved"
        )

        let breakableBoxEngine = SM64SwiftEngineState(objectCapacity: 16)
        let breakableBoxBridge = SM64BehaviorDispatchBridge()
        let largeBreakableBox = try breakableBoxBridge.spawnBreakableBox(in: breakableBoxEngine, kind: .large)
        let smallBreakableBox = try breakableBoxBridge.spawnBreakableBox(in: breakableBoxEngine, kind: .small)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BreakableBoxObjectBridge.largeBehaviorIdentity) == .breakableBox
                && SM64BehaviorDispatchBridge.route(for: SM64BreakableBoxObjectBridge.smallBehaviorIdentity) == .breakableBox,
            "breakable-box identity routes"
        )
        require(breakableBoxBridge.breakableBox.setInputs(for: largeBreakableBox, attacked: true), "large breakable-box attack input")
        require(breakableBoxBridge.breakableBox.setInputs(for: smallBreakableBox, moveFlags: 2), "small breakable-box collision input")
        let breakableBoxTick = breakableBoxBridge.tick(state: breakableBoxEngine)
        require(
            breakableBoxTick.breakableBoxEffects.first { $0.objectID == largeBreakableBox }?.output.spawnCoins == 1
                && breakableBoxTick.breakableBoxEffects.first { $0.objectID == smallBreakableBox }?.output.spawnCoins == 3,
            "breakable-box break routes are preserved"
        )
        let jumpingBoxEngine = SM64SwiftEngineState(objectCapacity: 8)
        let jumpingBoxBridge = SM64BehaviorDispatchBridge()
        let jumpingBox = try jumpingBoxBridge.spawnJumpingBox(in: jumpingBoxEngine, threshold: 10)
        require(SM64BehaviorDispatchBridge.route(for: SM64JumpingBoxObjectBridge.defaultBehaviorIdentity) == .breakableBox, "Jumping Box shared breakable route")
        _ = jumpingBoxEngine.objects.mutate(jumpingBox) { $0.timer = 11 }
        let jumpingBoxTick = jumpingBoxBridge.tick(state: jumpingBoxEngine)
        require(jumpingBoxTick.jumpingBoxEffects.first?.output.jump == true, "Jumping Box jump cadence route")
        require(jumpingBoxBridge.jumpingBox.setInput(stopRiding: true, for: jumpingBox), "Jumping Box break input")
        let jumpingBoxBreakTick = jumpingBoxBridge.tick(state: jumpingBoxEngine)
        require(jumpingBoxBreakTick.jumpingBoxEffects.first?.output.explode == true && jumpingBoxBreakTick.jumpingBoxEffects.first?.output.shouldDelete == true, "Jumping Box break retirement route")
        let kickableEngine = SM64SwiftEngineState(objectCapacity: 8)
        let kickableBridge = SM64BehaviorDispatchBridge()
        let kickable = try kickableBridge.spawnKickableBoard(in: kickableEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64KickableBoardObjectBridge.defaultBehaviorIdentity) == .breakableBox, "Kickable Board shared breakable route")
        require(kickableBridge.kickableBoard.setInput(attacked: true, attackType: 1, attackAboveBoard: false, for: kickable), "Kickable Board initial attack input")
        let kickableRockTick = kickableBridge.tick(state: kickableEngine)
        require(kickableRockTick.kickableBoardEffects.first?.output.action == 1, "Kickable Board rocking route")
        require(kickableBridge.kickableBoard.setInput(attacked: true, attackType: 2, attackAboveBoard: true, for: kickable), "Kickable Board fall attack input")
        _ = kickableEngine.objects.mutate(kickable) { $0.timer = 31 }
        let kickableTriggerTick = kickableBridge.tick(state: kickableEngine)
        require(kickableTriggerTick.kickableBoardEffects.first?.output.action == 2, "Kickable Board fall trigger route")
        _ = kickableEngine.objects.mutate(kickable) { $0.faceAngles.pitch = -0x3FFF; $0.angleVelocity.pitch = -0x80 }
        let kickableFallTick = kickableBridge.tick(state: kickableEngine)
        require(kickableFallTick.kickableBoardEffects.first?.output.action == 3 && kickableFallTick.kickableBoardEffects.first?.output.playFallSound == true, "Kickable Board fell state route")

        let wfWallEngine = SM64SwiftEngineState(objectCapacity: 8)
        let wfWallBridge = SM64BehaviorDispatchBridge()
        let wfWallLeft = try wfWallBridge.spawnWfBreakableWall(in: wfWallEngine, rightVariant: false)
        let wfWallRight = try wfWallBridge.spawnWfBreakableWall(in: wfWallEngine, rightVariant: true)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WfBreakableWallObjectBridge.leftBehaviorIdentity) == .breakableBox
                && SM64BehaviorDispatchBridge.route(for: SM64WfBreakableWallObjectBridge.rightBehaviorIdentity) == .breakableBox,
            "WF breakable wall shared route"
        )
        require(wfWallBridge.wfBreakableWall.setInput(marioShotFromCannon: true, collidedWithMario: true, for: wfWallLeft), "WF left wall cannon input")
        require(wfWallBridge.wfBreakableWall.setInput(marioShotFromCannon: true, collidedWithMario: true, for: wfWallRight), "WF right wall cannon input")
        let wfWallTick = wfWallBridge.tick(state: wfWallEngine)
        require(
            wfWallTick.wfBreakableWallEffects.first { $0.objectID == wfWallLeft }?.output.spawnCoins == 1
                && wfWallTick.wfBreakableWallEffects.first { $0.objectID == wfWallRight }?.output.playPuzzleJingle == true,
            "WF breakable wall explosion/jingle routes"
        )
        let unusedPoundEngine = SM64SwiftEngineState(objectCapacity: 8)
        let unusedPoundBridge = SM64BehaviorDispatchBridge()
        let unusedPound = try unusedPoundBridge.spawnUnusedPoundablePlatform(in: unusedPoundEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64UnusedPoundablePlatformObjectBridge.defaultBehaviorIdentity) == .breakableBox, "unused poundable platform route")
        require(unusedPoundBridge.unusedPoundablePlatform.setGroundPounded(true, for: unusedPound), "unused poundable ground-pound input")
        let unusedPoundTick = unusedPoundBridge.tick(state: unusedPoundEngine)
        require(unusedPoundTick.unusedPoundablePlatformEffects.first?.output.spawnTriangleParticles == true, "unused poundable break particles route")
        let yellowBackgroundEngine = SM64SwiftEngineState(objectCapacity: 8)
        let yellowBackgroundBridge = SM64BehaviorDispatchBridge()
        let yellowBackground = try yellowBackgroundBridge.spawnYellowBackgroundMenu(in: yellowBackgroundEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64YellowBackgroundMenuObjectBridge.defaultBehaviorIdentity) == .noOp, "yellow background menu route")
        let yellowBackgroundTick = yellowBackgroundBridge.tick(state: yellowBackgroundEngine)
        require(
            yellowBackgroundTick.yellowBackgroundMenuEffects.first { $0.objectID == yellowBackground }?.output.faceAngleYaw == -32768
                && yellowBackgroundTick.yellowBackgroundMenuEffects.first { $0.objectID == yellowBackground }?.output.scale == 9,
            "yellow background menu scale/rotation route"
        )
        let snowMoundEngine = SM64SwiftEngineState(objectCapacity: 16)
        let snowMoundBridge = SM64BehaviorDispatchBridge()
        let snowMound = try snowMoundBridge.spawnSlidingSnowMound(in: snowMoundEngine, position: .init(x: 0, y: 10, z: 4))
        let snowSpawner = try snowMoundBridge.spawnSnowMoundSpawner(in: snowMoundEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SnowMoundObjectBridge.slidingBehaviorIdentity) == .floatingPlatform
                && SM64BehaviorDispatchBridge.route(for: SM64SnowMoundObjectBridge.spawnerBehaviorIdentity) == .floatingPlatform,
            "snow mound shared route"
        )
        _ = snowMoundEngine.objects.mutate(snowMound) { $0.timer = 118 }
        let snowMoundTick = snowMoundBridge.tick(state: snowMoundEngine)
        require(snowMoundTick.snowMoundSlidingEffects.first { $0.objectID == snowMound }?.output.action == 1, "sliding snow mound transition route")
        require(snowMoundBridge.snowMound.setSpawnerInput(distanceToMario: 100, marioY: 0, for: snowSpawner), "snow mound spawner input")
        _ = snowMoundEngine.objects.mutate(snowSpawner) { $0.timer = 256 }
        let snowSpawnerTick = snowMoundBridge.tick(state: snowMoundEngine)
        require(snowSpawnerTick.snowMoundSpawnerEffects.first { $0.objectID == snowSpawner }?.output.spawnChild == true, "snow mound cadence route")
        let cruiserEngine = SM64SwiftEngineState(objectCapacity: 8)
        let cruiserBridge = SM64BehaviorDispatchBridge()
        let cruiserWing = try cruiserBridge.spawnRrCruiserWing(in: cruiserEngine, baseYaw: 100, basePitch: 200, reverse: false)
        require(SM64BehaviorDispatchBridge.route(for: SM64RrCruiserWingObjectBridge.defaultBehaviorIdentity) == .tumblingBridge, "RR cruiser wing route")
        let cruiserTick = cruiserBridge.tick(state: cruiserEngine)
        require(cruiserTick.rrCruiserWingEffects.first { $0.objectID == cruiserWing }?.output.facePitch == 2248, "RR cruiser wing oscillation route")
        let spindriftEngine = SM64SwiftEngineState(objectCapacity: 8)
        let spindriftBridge = SM64BehaviorDispatchBridge()
        let spindrift = try spindriftBridge.spawnSpindrift(in: spindriftEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64SpindriftObjectBridge.defaultBehaviorIdentity) == .bomp, "Spindrift shared enemy route")
        require(spindriftBridge.spindrift.setInput(attacked: true, for: spindrift), "Spindrift attack input")
        let spindriftTick = spindriftBridge.tick(state: spindriftEngine)
        require(spindriftTick.spindriftEffects.first { $0.objectID == spindrift }?.output.playDyingSound == true, "Spindrift attack/death route")
        let spindelEngine = SM64SwiftEngineState(objectCapacity: 8)
        let spindelBridge = SM64BehaviorDispatchBridge()
        let spindel = try spindelBridge.spawnSpindel(in: spindelEngine, position: .init(x: 0, y: 10, z: 0))
        require(SM64BehaviorDispatchBridge.route(for: SM64SpindelObjectBridge.defaultBehaviorIdentity) == .tumblingBridge, "Spindel shared mechanism route")
        let spindelTick = spindelBridge.tick(state: spindelEngine)
        require(spindelTick.spindelEffects.first { $0.objectID == spindel }?.output.angleVelocityPitch == 256, "Spindel phase motion route")
        let rotatingBridgeEngine = SM64SwiftEngineState(objectCapacity: 16)
        let rotatingBridgeDispatch = SM64BehaviorDispatchBridge()
        let rotatingBridgeObject = try rotatingBridgeDispatch.spawnRrRotatingBridgePlatform(in: rotatingBridgeEngine, position: .zero, distanceToMario: 100, activationAllowed: true)
        require(SM64BehaviorDispatchBridge.route(for: SM64RrRotatingBridgePlatformObjectBridge.defaultBehaviorIdentity) == .flamethrower, "RR rotating bridge shared flamethrower route")
        let rotatingBridgeTick = rotatingBridgeDispatch.tick(state: rotatingBridgeEngine)
        require(rotatingBridgeTick.rrRotatingBridgePlatformEffects.first { $0.objectID == rotatingBridgeObject }?.rotation.angleVelocityYaw == -128, "RR rotating bridge yaw route")
        let snowmanWindEngine = SM64SwiftEngineState(objectCapacity: 8)
        let snowmanWindBridge = SM64BehaviorDispatchBridge()
        let snowmanWind = try snowmanWindBridge.spawnSnowmanWind(in: snowmanWindEngine, originalYaw: 100)
        require(SM64BehaviorDispatchBridge.route(for: SM64SnowmanWindObjectBridge.defaultBehaviorIdentity) == .wind, "Snowman wind shared route")
        require(snowmanWindBridge.snowmanWind.setInput(canActivateText: true, for: snowmanWind), "Snowman wind textbox input")
        let snowmanWindTick = snowmanWindBridge.tick(state: snowmanWindEngine)
        require(snowmanWindTick.snowmanWindEffects.first { $0.objectID == snowmanWind }?.output.subAction == 1, "Snowman wind textbox route")
        let snowballEngine = SM64SwiftEngineState(objectCapacity: 8)
        let snowballBridge = SM64BehaviorDispatchBridge()
        let snowball = try snowballBridge.spawnMrBlizzardSnowball(in: snowballEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64MrBlizzardSnowballObjectBridge.defaultBehaviorIdentity) == .bomp, "Mr Blizzard snowball shared enemy route")
        require(snowballBridge.mrBlizzardSnowball.setInput(parentHolding: false, parentThrowing: true, parentYaw: 1000, distanceToMario: 100, for: snowball), "Mr Blizzard snowball launch input")
        _ = snowballEngine.objects.mutate(snowball) { $0.action = 1; $0.timer = 1 }
        let snowballTick = snowballBridge.tick(state: snowballEngine)
        require(snowballTick.mrBlizzardSnowballEffects.first { $0.objectID == snowball }?.output.action == 2, "Mr Blizzard snowball launch route")

        let exclamationBoxEngine = SM64SwiftEngineState(objectCapacity: 16)
        let exclamationBoxBridge = SM64BehaviorDispatchBridge()
        let exclamationBox = try exclamationBoxBridge.spawnExclamationBox(in: exclamationBoxEngine, behaviorByte: 0)
        require(SM64BehaviorDispatchBridge.route(for: SM64ExclamationBoxObjectBridge.defaultBehaviorIdentity) == .exclamationBox, "exclamation-box identity route")
        require(exclamationBoxBridge.exclamationBox.setInputs(for: exclamationBox, saveCollected: false), "exclamation-box save input")
        let exclamationInitTick = exclamationBoxBridge.tick(state: exclamationBoxEngine)
        require(exclamationInitTick.exclamationBoxEffects.first { $0.objectID == exclamationBox }?.output.action == 1, "exclamation-box closed state route")
        require(exclamationInitTick.exclamationBoxEffects.first { $0.objectID == exclamationBox }?.rotatingMarkID != nil, "exclamation-box rotating mark child route")

        let orangeNumberEngine = SM64SwiftEngineState(objectCapacity: 16)
        let orangeNumberBridge = SM64BehaviorDispatchBridge()
        let orangeNumber = try orangeNumberBridge.spawnOrangeNumber(in: orangeNumberEngine, animationState: 4, position: .zero)
        require(SM64BehaviorDispatchBridge.route(for: SM64OrangeNumberObjectBridge.defaultBehaviorIdentity) == .orangeNumber, "orange-number identity route")
        let orangeNumberTick = orangeNumberBridge.tick(state: orangeNumberEngine)
        require(orangeNumberTick.orangeNumberEffects.first { $0.objectID == orangeNumber }?.output.timer == 1, "orange-number owner route")

        let soundRockEngine = SM64SwiftEngineState(objectCapacity: 16)
        let soundRockBridge = SM64BehaviorDispatchBridge()
        let soundSpawner = try soundRockBridge.spawnSoundSpawner(in: soundRockEngine, soundID: 0x1234)
        let rockSolid = try soundRockBridge.spawnRockSolid(in: soundRockEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SoundSpawnerObjectBridge.defaultBehaviorIdentity) == .soundSpawner
                && SM64BehaviorDispatchBridge.route(for: SM64RockSolidObjectBridge.defaultBehaviorIdentity) == .rockSolid,
            "sound/rock identity routes"
        )
        let soundRockTick = soundRockBridge.tick(state: soundRockEngine)
        require(
            soundRockTick.soundSpawnerEffects.first { $0.objectID == soundSpawner }?.output.timer == 1
                && soundRockTick.rockSolidEffects.first { $0.objectID == rockSolid }?.output.loadCollisionModel == true,
            "sound/rock owner routes"
        )

        let toxBoxEngine = SM64SwiftEngineState(objectCapacity: 8)
        let toxBoxBridge = SM64BehaviorDispatchBridge()
        let toxBox = try toxBoxBridge.spawnToxBox(in: toxBoxEngine, initialDirectionAction: 6, nextDirectionAction: 4)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ToxBoxObjectBridge.defaultBehaviorIdentity) == .rockSolid,
            "Tox Box shares the collision dispatch lane"
        )
        let toxBoxTick = toxBoxBridge.tick(state: toxBoxEngine)
        require(
            toxBoxTick.toxBoxEffects.first { $0.objectID == toxBox }?.output.action == 6
                && toxBoxTick.toxBoxEffects.first { $0.objectID == toxBox }?.output.loadCollisionModel == true,
            "Tox Box action/collision owner route"
        )

        let pyramidWallEngine = SM64SwiftEngineState(objectCapacity: 8)
        let pyramidWallBridge = SM64BehaviorDispatchBridge()
        let pyramidWall = try pyramidWallBridge.spawnSslMovingPyramidWall(in: pyramidWallEngine, positionY: 1_000, start: .middle)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SslMovingPyramidWallObjectBridge.defaultBehaviorIdentity) == .lllSinkingRockBlock,
            "SSL pyramid-wall identity shares the LLL environment lane"
        )
        let pyramidWallTick = pyramidWallBridge.tick(state: pyramidWallEngine)
        require(
            pyramidWallTick.sslMovingPyramidWallEffects.first { $0.objectID == pyramidWall }?.output.positionY == 738.88
                && pyramidWallTick.sslMovingPyramidWallEffects.first { $0.objectID == pyramidWall }?.output.velocityY == -5.12,
            "SSL moving pyramid-wall owner route"
        )

        let thiTopEngine = SM64SwiftEngineState(objectCapacity: 12)
        let thiTopBridge = SM64BehaviorDispatchBridge()
        let hugeTop = try thiTopBridge.spawnThiIslandTop(in: thiTopEngine, role: .huge)
        let tinyTop = try thiTopBridge.spawnThiIslandTop(in: thiTopEngine, role: .tiny)
        _ = thiTopEngine.objects.mutate(hugeTop) { record in record.behaviorParams = 1 }
        _ = thiTopEngine.objects.mutate(tinyTop) { record in record.distanceToMario = 400; record.behaviorParams2ndByte = 1 }
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ThiIslandTopObjectBridge.hugeBehaviorIdentity) == .environmentGate
                && SM64BehaviorDispatchBridge.route(for: SM64ThiIslandTopObjectBridge.tinyBehaviorIdentity) == .environmentGate,
            "THI island-top identities share the environment lane"
        )
        let thiTopTick = thiTopBridge.tick(state: thiTopEngine)
        require(
            thiTopTick.thiIslandTopEffects.first { $0.objectID == hugeTop }?.output.hidden == true
                && thiTopTick.thiIslandTopEffects.first { $0.objectID == hugeTop }?.output.environmentSet == 3_000
                && thiTopTick.thiIslandTopEffects.first { $0.objectID == tinyTop }?.output.spawnParticles == true,
            "THI huge/tiny island-top owner routes"
        )

        let environmentGateEngine = SM64SwiftEngineState(objectCapacity: 24)
        let environmentGateBridge = SM64BehaviorDispatchBridge()
        let subDoor = try environmentGateBridge.spawnEnvironmentGate(in: environmentGateEngine, role: .bowserSubDoor)
        let sub = try environmentGateBridge.spawnEnvironmentGate(in: environmentGateEngine, role: .bowsersSub)
        let grills = try environmentGateBridge.spawnEnvironmentGate(in: environmentGateEngine, role: .moatGrills)
        let bridgeObjects = try environmentGateBridge.spawnEnvironmentGate(in: environmentGateEngine, role: .invisibleObjectsUnderBridge)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64EnvironmentGateObjectBridge.bowserSubDoorBehaviorIdentity) == .environmentGate
                && SM64BehaviorDispatchBridge.route(for: SM64EnvironmentGateObjectBridge.bowsersSubBehaviorIdentity) == .environmentGate
                && SM64BehaviorDispatchBridge.route(for: SM64EnvironmentGateObjectBridge.moatGrillsBehaviorIdentity) == .environmentGate
                && SM64BehaviorDispatchBridge.route(for: SM64EnvironmentGateObjectBridge.invisibleObjectsUnderBridgeBehaviorIdentity) == .environmentGate,
            "environment-gate identity routes"
        )
        require(environmentGateBridge.environmentGate.setInputs(for: subDoor, submarineUnlocked: true), "sub-door unlock input")
        require(environmentGateBridge.environmentGate.setInputs(for: sub, submarineUnlocked: true), "sub unlock input")
        require(environmentGateBridge.environmentGate.setInputs(for: grills, moatDrained: true), "moat-drained input")
        require(environmentGateBridge.environmentGate.setInputs(for: bridgeObjects, moatDrained: true), "bridge moat input")
        let environmentGateTick = environmentGateBridge.tick(state: environmentGateEngine)
        require(
            environmentGateTick.environmentGateEffects.first { $0.objectID == subDoor }?.output.shouldDelete == true
                && environmentGateTick.environmentGateEffects.first { $0.objectID == grills }?.output.modelNone == true
                && environmentGateTick.environmentGateEffects.first { $0.objectID == bridgeObjects }?.output.environmentLevel6 == -800,
            "environment-gate owner routes"
        )

        let clockArmEngine = SM64SwiftEngineState(objectCapacity: 16)
        let clockArmBridge = SM64BehaviorDispatchBridge()
        let hourHand = try clockArmBridge.spawnClockArm(in: clockArmEngine, kind: .hour)
        let minuteHand = try clockArmBridge.spawnClockArm(in: clockArmEngine, kind: .minute, surface: .painting)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ClockArmObjectBridge.hourBehaviorIdentity) == .clockArm
                && SM64BehaviorDispatchBridge.route(for: SM64ClockArmObjectBridge.minuteBehaviorIdentity) == .clockArm,
            "clock-arm identity routes"
        )
        let clockArmTick = clockArmBridge.tick(state: clockArmEngine)
        require(
            clockArmTick.clockArmEffects.first { $0.objectID == hourHand }?.output.rotating == true
                && clockArmTick.clockArmEffects.first { $0.objectID == minuteHand }?.output.action == 0,
            "clock-arm owner routes"
        )

        let castleTrapEngine = SM64SwiftEngineState(objectCapacity: 24)
        let castleTrapBridge = SM64BehaviorDispatchBridge()
        let castleTrap = try castleTrapBridge.spawnCastleFloorTrap(in: castleTrapEngine)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CastleFloorTrapObjectBridge.parentBehaviorIdentity) == .castleFloorTrap
                && SM64BehaviorDispatchBridge.route(for: SM64CastleFloorTrapObjectBridge.childBehaviorIdentity) == .castleFloorTrap,
            "castle floor-trap identity routes"
        )
        require(castleTrapBridge.castleFloorTrap.setInputs(for: castleTrap, interactTurn: true), "castle floor-trap interaction input")
        let castleTrapTick = castleTrapBridge.tick(state: castleTrapEngine)
        require(
            castleTrapTick.castleFloorTrapEffects.first { $0.objectID == castleTrap }?.output.action == 1
                && castleTrapTick.castleFloorTrapEffects.first { $0.objectID == castleTrap }?.spawnedChildren.count == 2,
            "castle floor-trap parent/child route"
        )

        let castleFlagEngine = SM64SwiftEngineState(objectCapacity: 8)
        let castleFlagBridge = SM64BehaviorDispatchBridge()
        let castleFlag = try castleFlagBridge.spawnCastleFlag(in: castleFlagEngine, randomFrame: 18)
        require(SM64BehaviorDispatchBridge.route(for: SM64CastleFlagObjectBridge.defaultBehaviorIdentity) == .castleFlag, "castle-flag identity route")
        let castleFlagTick = castleFlagBridge.tick(state: castleFlagEngine)
        require(castleFlagTick.castleFlagEffects.first { $0.objectID == castleFlag }?.output.animationFrame == 18, "castle-flag owner route")

        let booCageEngine = SM64SwiftEngineState(objectCapacity: 16)
        let booCageBridge = SM64BehaviorDispatchBridge()
        let booCage = try booCageBridge.spawnBooCage(in: booCageEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64BooCageObjectBridge.defaultBehaviorIdentity) == .booCage, "boo-cage identity route")
        require(booCageBridge.booCage.setInputs(for: booCage, parentAlive: false), "boo-cage parent death input")
        let booCageTick = booCageBridge.tick(state: booCageEngine)
        require(booCageTick.booCageEffects.first { $0.objectID == booCage }?.output.playPuzzleJingle == true, "boo-cage owner route")

        let booKeyEngine = SM64SwiftEngineState(objectCapacity: 16)
        let booKeyBridge = SM64BehaviorDispatchBridge()
        let alphaKey = try booKeyBridge.spawnBooKey(in: booKeyEngine, kind: .alpha)
        let betaKey = try booKeyBridge.spawnBooKey(in: booKeyEngine, kind: .beta)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64BooKeyObjectBridge.alphaBehaviorIdentity) == .booKey
                && SM64BehaviorDispatchBridge.route(for: SM64BooKeyObjectBridge.betaBehaviorIdentity) == .booKey,
            "boo-key identity routes"
        )
        require(booKeyBridge.booKey.setInputs(for: alphaKey, collided: true), "alpha key collision input")
        require(booKeyBridge.booKey.setInputs(for: betaKey, parentAlive: false), "beta key drop input")
        let booKeyTick = booKeyBridge.tick(state: booKeyEngine)
        require(
            booKeyTick.booKeyEffects.first { $0.objectID == alphaKey }?.output.spawnSparkles == true
                && booKeyTick.booKeyEffects.first { $0.objectID == betaKey }?.output.action == 1,
            "boo-key owner routes"
        )

        let castleBooEngine = SM64SwiftEngineState(objectCapacity: 16)
        let castleBooBridge = SM64BehaviorDispatchBridge()
        let castleBoo = try castleBooBridge.spawnBooInCastle(in: castleBooEngine, stars: 12, room: 1)
        require(SM64BehaviorDispatchBridge.route(for: SM64BooInCastleObjectBridge.defaultBehaviorIdentity) == .booInCastle, "castle Boo identity route")
        let castleBooTick = castleBooBridge.tick(state: castleBooEngine)
        require(castleBooTick.booInCastleEffects.first { $0.objectID == castleBoo }?.output.action == 1, "castle Boo owner route")

        let merryGoRoundEngine = SM64SwiftEngineState(objectCapacity: 8)
        let merryGoRoundBridge = SM64BehaviorDispatchBridge()
        let merryGoRound = try merryGoRoundBridge.spawnMerryGoRound(in: merryGoRoundEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64MerryGoRoundObjectBridge.defaultBehaviorIdentity) == .merryGoRound, "merry-go-round identity route")
        require(merryGoRoundBridge.merryGoRound.setInputs(for: merryGoRound, marioRoom: 1), "merry-go-round room input")
        let merryGoRoundTick = merryGoRoundBridge.tick(state: merryGoRoundEngine)
        require(merryGoRoundTick.merryGoRoundEffects.first { $0.objectID == merryGoRound }?.output.playMusic == true, "merry-go-round owner route")

        let musicTouchEngine = SM64SwiftEngineState(objectCapacity: 8)
        let musicTouchBridge = SM64BehaviorDispatchBridge()
        let musicTouch = try musicTouchBridge.spawnMusicTouch(in: musicTouchEngine, distanceToMario: 199)
        require(SM64BehaviorDispatchBridge.route(for: SM64MusicTouchObjectBridge.defaultBehaviorIdentity) == .musicTouch, "music-touch identity route")
        let musicTouchTick = musicTouchBridge.tick(state: musicTouchEngine)
        require(musicTouchTick.musicTouchEffects.first { $0.objectID == musicTouch }?.output.playPuzzleJingle == true, "music-touch owner route")

        let textSurfaceEngine = SM64SwiftEngineState(objectCapacity: 8)
        let textSurfaceBridge = SM64BehaviorDispatchBridge()
        let panel = try textSurfaceBridge.spawnTextSurface(in: textSurfaceEngine, kind: .messagePanel)
        let wallSign = try textSurfaceBridge.spawnTextSurface(in: textSurfaceEngine, kind: .signOnWall)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64TextSurfaceObjectBridge.messagePanelBehaviorIdentity) == .textSurface
                && SM64BehaviorDispatchBridge.route(for: SM64TextSurfaceObjectBridge.signOnWallBehaviorIdentity) == .textSurface,
            "text-surface identity routes"
        )
        let textSurfaceTick = textSurfaceBridge.tick(state: textSurfaceEngine)
        require(
            textSurfaceTick.textSurfaceEffects.first { $0.objectID == panel }?.output.loadCollisionModel == true
                && textSurfaceTick.textSurfaceEffects.first { $0.objectID == wallSign }?.output.loadCollisionModel == false,
            "text-surface owner routes"
        )

        let grandStarEngine = SM64SwiftEngineState(objectCapacity: 8)
        let grandStarBridge = SM64BehaviorDispatchBridge()
        let grandStar = try grandStarBridge.spawnGrandStar(in: grandStarEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64GrandStarObjectBridge.defaultBehaviorIdentity) == .grandStar, "grand-star identity route")
        let grandStarTick = grandStarBridge.tick(state: grandStarEngine)
        require(grandStarTick.grandStarEffects.first { $0.objectID == grandStar }?.output.playAppearsSound == true, "grand-star owner route")

        let betaAnchorEngine = SM64SwiftEngineState(objectCapacity: 8)
        let betaAnchorBridge = SM64BehaviorDispatchBridge()
        let betaAnchor = try betaAnchorBridge.spawnBetaBowserAnchor(in: betaAnchorEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64BetaBowserAnchorObjectBridge.defaultBehaviorIdentity) == .betaBowserAnchor, "beta-anchor identity route")
        require(betaAnchorBridge.betaBowserAnchor.setInputs(for: betaAnchor, marioPosition: .init(x: 1, y: 2, z: 3), marioYaw: 0, debugRadius: 20, debugHeight: 40), "beta-anchor input")
        let betaAnchorTick = betaAnchorBridge.tick(state: betaAnchorEngine)
        require(betaAnchorTick.betaBowserAnchorEffects.first { $0.objectID == betaAnchor }?.output.position == .init(x: 1, y: 32, z: 303), "beta-anchor owner route")
        require(SM64BehaviorDispatchBridge.route(for: SM64ElevatorObjectBridge.anotherElevatorBehaviorIdentity) == .elevator, "another-elevator shared route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.cutOutObjectIdentity) == .noOp, "cut-out no-op shared route")
        require(SM64BehaviorDispatchBridge.route(for: SM64FloorSwitchObjectBridge.purpleSwitchHiddenBoxesBehaviorIdentity) == .floorSwitch, "purple hidden-box switch shared route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.rotatingCounterClockwiseIdentity) == .noOp, "rotating-counterclockwise terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.stubIdentity) == .noOp, "stub terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.stub1D0CIdentity) == .noOp, "stub-1D0C terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.stub1D70Identity) == .noOp, "stub-1D70 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.unusedOneIdentity) == .noOp, "unused-one terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.staticObjectIdentity) == .noOp, "static-object terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.yellowBallIdentity) == .noOp, "yellow-ball terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.carrySomething1Identity) == .noOp, "carry-something-1 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.carrySomething2Identity) == .noOp, "carry-something-2 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.carrySomething3Identity) == .noOp, "carry-something-3 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.carrySomething4Identity) == .noOp, "carry-something-4 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.carrySomething5Identity) == .noOp, "carry-something-5 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.carrySomething6Identity) == .noOp, "carry-something-6 terminal route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.iglooIdentity) == .noOp, "igloo barrier route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.bigSnowmanWholeIdentity) == .noOp, "big snowman route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.ukikiCageChildIdentity) == .noOp, "Ukiki cage child route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.sunkenShipPart2Identity) == .noOp, "sunken ship part route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.sunkenShipSetRotationIdentity) == .noOp, "sunken ship rotation helper route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.towerIdentity) == .noOp, "tower collision route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.bulletBillCannonIdentity) == .noOp, "Bullet Bill cannon collision route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.lllHexagonalMeshIdentity) == .noOp, "LLL hex mesh collision route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.hiddenStaircaseStepIdentity) == .noOp, "hidden staircase collision route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.pillarBaseIdentity) == .noOp, "pillar base collision route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.inSunkenShipIdentity) == .noOp, "sunken ship collision alias route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.inSunkenShip2Identity) == .noOp, "sunken ship 2 collision route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.mantaRayRingManagerIdentity) == .noOp, "manta-ray ring manager persistent route")
        require(SM64BehaviorDispatchBridge.route(for: SM64NoOpObjectBridge.betaFishSplashSpawnerIdentity) == .noOp, "beta fish splash spawner persistent route")

        let bompEngine = SM64SwiftEngineState(objectCapacity: 8)
        let bompBridge = SM64BehaviorDispatchBridge()
        let bomp = try bompBridge.spawnBomp(
            in: bompEngine,
            variant: .small,
            position: .init(x: 3400, y: 0, z: 0),
            randomTimer: 100
        )
        require(SM64BehaviorDispatchBridge.route(for: SM64BompObjectBridge.smallBehaviorIdentity) == .bomp, "small Bomp identity route")
        let bompWaitTick = bompBridge.tick(state: bompEngine)
        require(
            bompWaitTick.events.map(\.route) == [.bomp]
                && bompWaitTick.bompEffects.first?.output.action == .wait
                && bompWaitTick.bompEffects.first?.output.timer == 101,
            "Bomp wait state route executes"
        )
        _ = bompEngine.objects.mutate(bomp) { record in
            record.action = Int32(SM64BompAction.pokeOut.rawValue)
            record.timer = 15
            record.position.x = 3400
            record.forwardVelocity = 30
        }
        let bompExtendTick = bompBridge.tick(state: bompEngine)
        require(
            bompExtendTick.bompEffects.first?.output.action == .extend
                && bompExtendTick.bompEffects.first?.output.forwardVelocity == 40
                && bompExtendTick.bompEffects.first?.output.sound == true,
            "Bomp transition/sound route executes"
        )

        let thwompEngine = SM64SwiftEngineState(objectCapacity: 8)
        let thwompBridge = SM64BehaviorDispatchBridge()
        let thwomp = try thwompBridge.spawnThwomp(
            in: thwompEngine,
            variant: .thwomp,
            position: .init(x: 0, y: 100, z: 0),
            distanceToMario: 1000,
            randomWaitTimer: 20,
            randomPauseTimer: 20
        )
        require(SM64BehaviorDispatchBridge.route(for: SM64ThwompObjectBridge.thwompBehaviorIdentity) == .thwomp, "Thwomp identity route")
        let thwompWaitTick = thwompBridge.tick(state: thwompEngine)
        require(
            thwompWaitTick.events.map(\.route) == [.thwomp]
                && thwompWaitTick.thwompEffects.first?.output.action == .wait
                && thwompWaitTick.thwompEffects.first?.output.positionY == 110,
            "Thwomp wait route executes"
        )
        _ = thwompEngine.objects.mutate(thwomp) { record in
            record.action = Int32(SM64ThwompAction.startFall.rawValue)
            record.timer = 21
            record.position.y = 105
        }
        let thwompFallTick = thwompBridge.tick(state: thwompEngine)
        require(
            thwompFallTick.thwompEffects.first?.output.action == .falling
                && thwompEngine.platformCollisionOwners.contains(thwomp),
            "Thwomp action/collision owner route executes"
        )

        let boulderEngine = SM64SwiftEngineState(objectCapacity: 8)
        let boulderBridge = SM64BehaviorDispatchBridge()
        let boulder = try boulderBridge.spawnBoulder(in: boulderEngine, position: .zero, moveYaw: 0)
        require(SM64BehaviorDispatchBridge.route(for: SM64BoulderObjectBridge.defaultBehaviorIdentity) == .boulder, "boulder identity route")
        let boulderTick = boulderBridge.tick(state: boulderEngine)
        require(
            boulderTick.boulderEffects.first?.objectID == boulder
                && boulderTick.boulderEffects.first?.output.action == .rolling
                && boulderTick.boulderEffects.first?.output.forwardVelocity == 40
                && boulderEngine.objects.record(for: boulder)?.hitboxRadius == 210,
            "boulder initialization/hitbox route executes"
        )
        let generatorEngine = SM64SwiftEngineState(objectCapacity: 16)
        let generatorBridge = SM64BehaviorDispatchBridge()
        let generator = try generatorBridge.spawnBoulderGenerator(in: generatorEngine, timer: 0, distanceToMario: 6000, currentRoomIsFour: true)
        require(SM64BehaviorDispatchBridge.route(for: SM64BoulderObjectBridge.generatorBehaviorIdentity) == .boulder, "boulder generator identity route")
        let generatorTick = generatorBridge.tick(state: generatorEngine)
        require(
            generatorTick.boulderGeneratorEffects.first?.objectID == generator
                && generatorTick.boulderGeneratorEffects.first?.output.shouldSpawn == true
                && generatorTick.boulderGeneratorEffects.first?.spawnedBoulder != nil
                && generatorTick.boulderEffects.isEmpty,
            "boulder generator list-order spawn route executes"
        )
        let generatorChildTick = generatorBridge.tick(state: generatorEngine)
        require(generatorChildTick.boulderEffects.count == 1, "boulder generator child executes on next pass")

        let horizontalEngine = SM64SwiftEngineState(objectCapacity: 8)
        let horizontalBridge = SM64BehaviorDispatchBridge()
        let horizontal = try horizontalBridge.spawnHorizontalGrindel(in: horizontalEngine, position: .zero, moveYaw: 0, onGround: true)
        require(SM64BehaviorDispatchBridge.route(for: SM64HorizontalGrindelObjectBridge.defaultBehaviorIdentity) == .horizontalGrindel, "horizontal Grindel identity route")
        _ = horizontalEngine.objects.mutate(horizontal) { record in record.moveFlags = 1; record.angleToHome = 100 }
        let horizontalTick = horizontalBridge.tick(state: horizontalEngine)
        require(
            horizontalTick.horizontalGrindelEffects.first?.objectID == horizontal
                && horizontalTick.horizontalGrindelEffects.first?.output.faceYaw == 0x4000
                && horizontalEngine.platformCollisionOwners.contains(horizontal),
            "horizontal Grindel collision/owner route executes"
        )

        let unusedParticleEngine = SM64SwiftEngineState(objectCapacity: 32)
        let unusedParticleBridge = SM64BehaviorDispatchBridge()
        let unusedParticle = try unusedParticleBridge.spawnUnusedParticleSpawn(in: unusedParticleEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64UnusedParticleSpawnObjectBridge.defaultBehaviorIdentity) == .unusedParticleSpawn, "unused particle spawner identity route")
        require(unusedParticleBridge.unusedParticleSpawn.setCollision(true, for: unusedParticle), "unused particle collision input")
        let unusedParticleTick = unusedParticleBridge.tick(state: unusedParticleEngine)
        require(
            unusedParticleTick.unusedParticleSpawnEffects.first?.objectID == unusedParticle
                && unusedParticleTick.unusedParticleSpawnEffects.first?.spawnedParticles.count == 10
                && unusedParticleTick.unusedParticleSpawnEffects.first?.deactivated == true,
            "unused particle collision spawns ten purple particles"
        )

        let snowmanEngine = SM64SwiftEngineState(objectCapacity: 16)
        let snowmanBridge = SM64BehaviorDispatchBridge()
        let snowmanParent = try snowmanEngine.spawnObject(in: .generalActor, behaviorIdentity: 0x534E4F574D414E)
        let checkpoint = try snowmanBridge.spawnSnowmanCheckpoint(in: snowmanEngine, parent: snowmanParent)
        require(SM64BehaviorDispatchBridge.route(for: SM64SnowmanCheckpointObjectBridge.defaultBehaviorIdentity) == .snowmanCheckpoint, "snowman checkpoint identity route")
        _ = snowmanEngine.objects.mutate(checkpoint) { $0.distanceToMario = 799 }
        let checkpointTick = snowmanBridge.tick(state: snowmanEngine)
        require(
            checkpointTick.snowmanCheckpointEffects.first?.objectID == checkpoint
                && checkpointTick.snowmanCheckpointEffects.first?.output.triggered == true
                && snowmanBridge.snowmanCheckpoint.counter(for: snowmanParent) == 1,
            "snowman checkpoint parent counter/retirement route"
        )

        let snowmanHead = try snowmanBridge.spawnSnowmanHead(in: snowmanEngine, position: .init(x: 0, y: -1000, z: 0))
        require(SM64BehaviorDispatchBridge.route(for: SM64SnowmanHeadObjectBridge.defaultBehaviorIdentity) == .snowmanHead, "snowman head identity route")
        _ = snowmanEngine.objects.mutate(snowmanHead) { record in
            record.action = 3
            record.timer = 12
            record.position.y = -1000
        }
        let snowmanHeadTick = snowmanBridge.tick(state: snowmanEngine)
        require(
            snowmanHeadTick.events.contains { $0.objectID == snowmanHead && $0.route == .snowmanHead }
                && snowmanHeadTick.snowmanHeadEffects.first?.output.action == 4
                && snowmanHeadTick.snowmanHeadEffects.first?.output.explosionJingle == true,
            "snowman head fall/explosion route"
        )

        let bowserAnchorEngine = SM64SwiftEngineState(objectCapacity: 16)
        let bowserAnchorBridge = SM64BehaviorDispatchBridge()
        let bowserParent = try bowserAnchorEngine.spawnObject(in: .generalActor, behaviorIdentity: 0x424F57534552)
        _ = bowserAnchorEngine.objects.mutate(bowserParent) { record in record.position = .init(x: 4, y: 5, z: 6); record.opacity = 255; record.action = 0 }
        let bodyAnchor = try bowserAnchorBridge.spawnBowserBodyAnchor(in: bowserAnchorEngine, parent: bowserParent)
        require(SM64BehaviorDispatchBridge.route(for: SM64BowserBodyAnchorObjectBridge.defaultBehaviorIdentity) == .bowserBodyAnchor, "Bowser body anchor identity route")
        let bodyAnchorTick = bowserAnchorBridge.tick(state: bowserAnchorEngine)
        require(
            bodyAnchorTick.bowserBodyAnchorEffects.first?.objectID == bodyAnchor
                && bodyAnchorTick.bowserBodyAnchorEffects.first?.output.position == .init(x: 4, y: 5, z: 6)
                && bodyAnchorTick.bowserBodyAnchorEffects.first?.output.tangible == true,
            "Bowser body anchor parent transform/interaction route"
        )
        let tailAnchor = try bowserAnchorBridge.spawnBowserTailAnchor(in: bowserAnchorEngine, parent: bowserParent)
        require(SM64BehaviorDispatchBridge.route(for: SM64BowserTailAnchorObjectBridge.defaultBehaviorIdentity) == .bowserTailAnchor, "Bowser tail anchor identity route")
        require(bowserAnchorBridge.bowserTailAnchor.setCollision(true, for: tailAnchor), "Bowser tail anchor collision input")
        let tailAnchorTick = bowserAnchorBridge.tick(state: bowserAnchorEngine)
        require(
            tailAnchorTick.bowserTailAnchorEffects.first?.objectID == tailAnchor
                && tailAnchorTick.bowserTailAnchorEffects.first?.output.action == .intangible
                && tailAnchorTick.bowserTailAnchorEffects.first?.output.parentRelativeX == 90,
            "Bowser tail anchor tangible/collision route"
        )

        let chestEngine = SM64SwiftEngineState(objectCapacity: 16)
        let chestBridge = SM64BehaviorDispatchBridge()
        let chestBottom = try chestBridge.spawnBetaChest(in: chestEngine, position: .zero)
        let chestLid = chestEngine.objects.ids(in: .default).first { chestEngine.objects.record(for: $0)?.behaviorIdentity == SM64BetaChestObjectBridge.lidBehaviorIdentity }
        require(chestLid != nil && SM64BehaviorDispatchBridge.route(for: SM64BetaChestObjectBridge.bottomBehaviorIdentity) == .betaChest, "beta chest identity/child route")
        if let chestLid {
            _ = chestEngine.objects.mutate(chestLid) { $0.distanceToMario = 299 }
            let chestOpenTick = chestBridge.tick(state: chestEngine)
            require(chestOpenTick.betaChestEffects.contains { $0.objectID == chestLid && $0.output.action == .opening }, "beta chest opening route")
            let chestBubbleTick = chestBridge.tick(state: chestEngine)
            require(chestBubbleTick.betaChestEffects.contains { $0.objectID == chestLid && $0.output.spawnBubble && $0.spawnedChild != nil }, "beta chest bubble child route")
        }
        _ = chestBottom

        let trampolineEngine = SM64SwiftEngineState(objectCapacity: 16)
        let trampolineBridge = SM64BehaviorDispatchBridge()
        let trampolineTop = try trampolineBridge.spawnBetaTrampoline(in: trampolineEngine, position: .zero)
        require(SM64BehaviorDispatchBridge.route(for: SM64BetaTrampolineObjectBridge.topBehaviorIdentity) == .betaTrampoline, "beta trampoline identity route")
        let trampolineTick = trampolineBridge.tick(state: trampolineEngine)
        require(
            trampolineTick.betaTrampolineEffects.first { $0.objectID == trampolineTop }?.output.spawnSpring == true
                && trampolineTick.betaTrampolineEffects.contains { $0.role == .spring && $0.output.position.y == -75 },
            "beta trampoline child/scale route"
        )
        let holdableEngine = SM64SwiftEngineState(objectCapacity: 8)
        let holdableBridge = SM64BehaviorDispatchBridge()
        let holdable = try holdableBridge.spawnBetaHoldable(in: holdableEngine)
        require(SM64BehaviorDispatchBridge.route(for: SM64BetaHoldableObjectBridge.defaultBehaviorIdentity) == .betaHoldable, "beta holdable identity route")
        _ = holdableEngine.objects.mutate(holdable) { $0.heldState = UInt32(SM64BetaHoldableState.thrown.rawValue) }
        let holdableTick = holdableBridge.tick(state: holdableEngine)
        require(holdableTick.betaHoldableEffects.first?.output.forwardVelocity == 40 && holdableTick.betaHoldableEffects.first?.output.velocityY == 20, "beta holdable thrown route")

        let seaweedEngine = SM64SwiftEngineState(objectCapacity: 16)
        let seaweedBridge = SM64BehaviorDispatchBridge()
        let seaweedBundle = try seaweedBridge.spawnSeaweedBundle(in: seaweedEngine, position: .zero)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SeaweedObjectBridge.bundleBehaviorIdentity) == .seaweed
                && SM64BehaviorDispatchBridge.route(for: SM64SeaweedObjectBridge.seaweedBehaviorIdentity) == .seaweed,
            "seaweed bundle/child identity routes"
        )
        let seaweedTick = seaweedBridge.tick(state: seaweedEngine)
        let seaweedBundleEffect = seaweedTick.seaweedEffects.first { $0.objectID == seaweedBundle }
        require(
            seaweedTick.events.map(\.route) == Array(repeating: .seaweed, count: 5)
                && seaweedBundleEffect?.spawnedChildren.count == SM64SeaweedBehavior.bundleDescriptors.count
                && seaweedTick.seaweedEffects.contains { $0.descriptor.faceAngles.yaw == 41800 },
            "seaweed bundle expands fixed descriptor children in list order"
        )
        let seaweedSecondTick = seaweedBridge.tick(state: seaweedEngine)
        require(
            seaweedSecondTick.seaweedEffects.allSatisfy { $0.objectID != seaweedBundle || $0.spawnedChildren.isEmpty },
            "seaweed bundle init is one-shot"
        )

        let shipPartEngine = SM64SwiftEngineState(objectCapacity: 8)
        let shipPartBridge = SM64BehaviorDispatchBridge()
        let decorativeShipPart = try shipPartBridge.spawnShipPart3(
            in: shipPartEngine,
            position: .init(x: 10, y: 20, z: 30),
            rollPhase: 0x2000
        )
        let collisionShipPart = try shipPartBridge.spawnShipPart3(
            in: shipPartEngine,
            role: .collision,
            position: .init(x: -10, y: -20, z: -30)
        )
        let sunkenShipPart = try shipPartBridge.spawnSunkenShipPart(in: shipPartEngine, position: .init(x: 0, y: 0, z: 0), distanceToMario: 5_000)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64ShipPart3ObjectBridge.decorativeBehaviorIdentity) == .shipPart3
                && SM64BehaviorDispatchBridge.route(for: SM64ShipPart3ObjectBridge.collisionBehaviorIdentity) == .shipPart3,
            "ship part 3 identity routes"
        )
        let shipPartTick = shipPartBridge.tick(state: shipPartEngine)
        require(
            shipPartTick.events.map(\.route) == [.shipPart3, .shipPart3, .shipPart3]
                && shipPartTick.shipPart3Effects.first { $0.objectID == decorativeShipPart }?.output.position == .init(x: 10, y: 20, z: 30)
                && shipPartTick.shipPart3Effects.first { $0.objectID == collisionShipPart }?.output.collisionLoaded == true,
            "ship part 3 home transform/oscillation and collision route"
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64SunkenShipPartObjectBridge.defaultBehaviorIdentity) == .shipPart3
                && shipPartTick.sunkenShipPartEffects.first { $0.objectID == sunkenShipPart }?.output.opacity == 70
                && ((shipPartEngine.objects.record(for: sunkenShipPart)?.graphFlags ?? 0) & 0x10 != 0),
            "sunken ship part distance opacity/disable-render route"
        )
        let slidingBoxEngine = SM64SwiftEngineState(objectCapacity: 8)
        let slidingBoxBridge = SM64BehaviorDispatchBridge()
        let slidingParent = try slidingBoxBridge.spawnShipPart3(in: slidingBoxEngine, role: .collision, position: .init(x: 10, y: 20, z: 30))
        let slidingBox = try slidingBoxBridge.spawnJrbSlidingBox(in: slidingBoxEngine, parent: slidingParent, relativePosition: .init(x: 1, y: 2, z: 3))
        require(SM64BehaviorDispatchBridge.route(for: SM64JrbSlidingBoxObjectBridge.defaultBehaviorIdentity) == .shipPart3, "JRB sliding box shared ship-part route")
        let slidingBoxTick = slidingBoxBridge.tick(state: slidingBoxEngine)
        require(slidingBoxTick.jrbSlidingBoxEffects.first { $0.objectID == slidingBox }?.output.position == .init(x: 11, y: 22, z: 33), "JRB sliding box parent-relative route")

        let pillarEngine = SM64SwiftEngineState(objectCapacity: 16)
        let pillarBridge = SM64BehaviorDispatchBridge()
        let pillar = try pillarBridge.spawnFallingPillar(
            in: pillarEngine,
            position: .zero,
            distanceToMario: 1_000,
            angleToMario: 0x2000
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64FallingPillarObjectBridge.pillarBehaviorIdentity) == .fallingPillar
                && SM64BehaviorDispatchBridge.route(for: SM64FallingPillarObjectBridge.hitboxBehaviorIdentity) == .fallingPillar,
            "falling pillar identity routes"
        )
        let pillarTick = pillarBridge.tick(state: pillarEngine)
        require(
            pillarTick.events.map(\.route) == Array(repeating: .fallingPillar, count: 5)
                && pillarTick.fallingPillarEffects.first { $0.objectID == pillar }?.spawnedHitboxes.count == 4
                && pillarTick.fallingPillarEffects.filter { $0.role == .hitbox }.count == 4,
            "falling pillar trigger expands parent-tracking hitboxes"
        )

        let coffinEngine = SM64SwiftEngineState(objectCapacity: 16)
        let coffinBridge = SM64BehaviorDispatchBridge()
        let coffinSpawner = try coffinBridge.spawnCoffinSpawner(in: coffinEngine, distanceToMario: 120)
        require(
            SM64BehaviorDispatchBridge.route(for: SM64CoffinObjectBridge.spawnerBehaviorIdentity) == .coffin
                && SM64BehaviorDispatchBridge.route(for: SM64CoffinObjectBridge.coffinBehaviorIdentity) == .coffin,
            "coffin spawner/child identity routes"
        )
        let coffinTick = coffinBridge.tick(state: coffinEngine)
        require(
            coffinTick.events.map(\.route) == Array(repeating: .coffin, count: 7)
                && coffinTick.coffinEffects.first { $0.objectID == coffinSpawner }?.spawnedCoffins.count == 6
                && coffinTick.coffinEffects.filter { $0.output.role == .coffin }.count == 6,
            "coffin spawner expands six deterministic child coffins"
        )

        let mistEngine = SM64SwiftEngineState(objectCapacity: 8)
        let mistBridge = SM64BehaviorDispatchBridge()
        let mist = try mistBridge.spawnWaterMist(
            in: mistEngine,
            moveYaw: 0,
            randomOffsetX: 3,
            randomOffsetZ: -2
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterMistObjectBridge.defaultBehaviorIdentity) == .waterMist,
            "water mist identity route"
        )
        let mistTick = mistBridge.tick(state: mistEngine)
        require(
            mistTick.waterMistEffects.count == 1
                && mistTick.waterMistEffects[0].objectID == mist
                && mistTick.waterMistEffects[0].output.position == .init(x: 23, y: -8, z: -2)
                && mistTick.waterMistEffects[0].output.opacity == 212,
            "water mist movement/opacity route is preserved"
        )

        let mist2Engine = SM64SwiftEngineState(objectCapacity: 8)
        let mist2Bridge = SM64BehaviorDispatchBridge()
        let mist2 = try mist2Bridge.spawnWaterMist2(
            in: mist2Engine,
            position: SM64ObjectVector3(x: 10, y: 0, z: 20),
            waterLevel: 100
        )
        require(
            SM64BehaviorDispatchBridge.route(for: SM64WaterMist2ObjectBridge.defaultBehaviorIdentity) == .waterMist2,
            "water mist 2 identity route"
        )
        let mist2Tick = mist2Bridge.tick(state: mist2Engine)
        require(
            mist2Tick.waterMist2Effects.count == 1
                && mist2Tick.waterMist2Effects[0].objectID == mist2
                && mist2Tick.waterMist2Effects[0].output.position == .init(x: 10, y: 120, z: 20)
                && mist2Tick.waterMist2Effects[0].output.opacity == 200,
            "water mist 2 home-level route is preserved"
        )

        print(String(format: "behaviorDispatchBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern behavior dispatch bridge smoke passed")
    }
}
