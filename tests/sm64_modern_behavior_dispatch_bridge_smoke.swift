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

        print(String(format: "behaviorDispatchBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern behavior dispatch bridge smoke passed")
    }
}
