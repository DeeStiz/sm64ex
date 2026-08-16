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

private func hashEffect(
    _ initial: UInt64,
    effect: SM64BigBooObjectEffectRecord,
    delivery: SM64OwnerThreadEffectDeliveryResult
) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.variant.rawValue))
    hash = hashU64(hash, UInt64(effect.action.rawValue))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.health)))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    for intent in effect.presentedEffects {
        hash = hashU64(hash, UInt64(intent.kind.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    }
    hash = hashU64(hash, UInt64(delivery.deleted.count))
    return hashU64(hash, UInt64(delivery.rejected.count))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBigBooObjectBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BigBooObjectBridge()
        let ghostID = try bridge.spawnBigBoo(in: engine, variant: .ghostHunt)
        guard var ghost = bridge.state(for: ghostID) else {
            preconditionFailure("Big Boo ghost state missing")
        }
        ghost.action = .postDeath
        ghost.timer = 61
        require(bridge.setState(ghost, for: ghostID, in: engine.objects), "Big Boo ghost state reset")

        let ghostTick = bridge.tick(
            state: engine,
            inputs: [ghostID: SM64BigBooTickInput(distanceToMario: 500)],
            presentBossEffects: true,
            spawnBridgeChildren: true
        )
        guard let ghostEffect = ghostTick.effects.first,
              let ghostDelivery = bridge.deliveryLog.last else {
            preconditionFailure("Big Boo ghost owner result missing")
        }
        require(ghostEffect.action == .postDeath, "Big Boo ghost post-death action")
        require(ghostEffect.effects.contains([.spawnBridge, .markForDeletion]),
                "Big Boo ghost bridge effects")
        require(ghostEffect.spawnedChildren.count == 3, "Big Boo staircase child count")
        require(ghostDelivery.deleted == [ghostID], "Big Boo parent retirement")
        require(ghostDelivery.rejected.isEmpty, "Big Boo ghost owner intents accepted")
        for (index, childID) in ghostEffect.spawnedChildren.enumerated() {
            guard let child = engine.objects.record(for: childID) else {
                preconditionFailure("Big Boo staircase child missing")
            }
            require(child.parent == ghostID, "Big Boo staircase parent identity")
            require(child.objectList == .level, "Big Boo staircase object list")
            require(child.model == SM64BigBooObjectBridge.staircaseModel,
                    "Big Boo staircase model")
            require(child.position == [
                SM64ObjectVector3(x: 973, y: 0, z: 717),
                SM64ObjectVector3(x: 973, y: 0, z: 517),
                SM64ObjectVector3(x: 973, y: 0, z: 917)
            ][index], "Big Boo staircase source transform")
        }

        var fingerprint = hashEffect(fnvOffset, effect: ghostEffect, delivery: ghostDelivery)
        let balconyID = try bridge.spawnBigBoo(in: engine, variant: .balcony)
        guard var balcony = bridge.state(for: balconyID) else {
            preconditionFailure("Big Boo balcony state missing")
        }
        balcony.action = .death
        balcony.health = 0
        balcony.timer = 31
        require(bridge.setState(balcony, for: balconyID, in: engine.objects),
                "Big Boo balcony state reset")

        let balconyTick = bridge.tick(
            state: engine,
            inputs: [balconyID: SM64BigBooTickInput(hitWall: true)],
            presentBossEffects: true,
            spawnRewardStar: true
        )
        guard let balconyEffect = balconyTick.effects.first,
              let balconyDelivery = bridge.deliveryLog.last,
              let starID = balconyEffect.spawnedChildren.first,
              let star = engine.objects.record(for: starID),
              let balconyRecord = engine.objects.record(for: balconyID) else {
            preconditionFailure("Big Boo balcony reward owner result missing")
        }
        require(balconyEffect.effects.contains(.star), "Big Boo balcony star effect")
        require(balconyEffect.starPosition == SM64BigBooKernel.balconyStarPosition,
                "Big Boo balcony reward coordinates")
        require(balconyEffect.presentedEffects.map(\.kind) == [.particle, .star],
                "Big Boo reward presentation ordering")
        require(balconyDelivery.rejected.isEmpty, "Big Boo reward intents accepted")
        require(star.parent == balconyRecord.id, "Big Boo star parent identity")
        require(star.objectList == .level && star.model == SM64BigBooObjectBridge.starModel,
                "Big Boo star source identity")
        require(star.position == SM64BigBooKernel.balconyStarPosition,
                "Big Boo star transform")
        fingerprint = hashEffect(fingerprint, effect: balconyEffect, delivery: balconyDelivery)

        print(String(format: "bigBooObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Big Boo owner bridge smoke passed")
    }
}
