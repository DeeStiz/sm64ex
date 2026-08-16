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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashEffect(
    _ initial: UInt64,
    _ effect: SM64BowserBombObjectEffectRecord
) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.kind.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    hash = hashU64(hash, UInt64(effect.genericEffects?.rawValue ?? 0))
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.genericBubbleCount)))
    hash = hashU64(hash, effect.genericSpawnedSmoke ? 1 : 0)
    hash = hashU64(hash, UInt64(effect.timer))
    hash = hashFloat(hash, effect.scale)
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.opacity)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animationState)))
    hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    for intent in effect.presentedEffects {
        hash = hashU64(hash, UInt64(intent.kind.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    }
    return hashU64(hash, effect.markedForDeletion ? 1 : 0)
}

@main
enum SM64ModernBowserExplosionIntegrationSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        let engine = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64BowserBombObjectBridge(routesGenericExplosionRequests: true)
        let bombID = try bridge.spawnBomb(
            in: engine,
            position: SM64ObjectVector3(x: 40, y: 50, z: 60)
        )

        let firstTick = bridge.tick(
            state: engine,
            bombInputs: [bombID: SM64BowserBombTickInput(collidedWithMario: true)]
        )
        guard let bombEffect = firstTick.effects.first(where: { $0.objectID == bombID }),
              let genericID = bombEffect.spawnedChildren.first,
              let genericEffect = firstTick.effects.first(where: { $0.objectID == genericID }),
              let genericRecord = engine.objects.record(for: genericID) else {
            preconditionFailure("generic Bowser explosion route missing")
        }
        require(bombEffect.spawnedExplosionRequest, "generic request preserved")
        require(bombEffect.spawnedChildren.count == 1, "one generic child")
        require(genericEffect.kind == .genericExplosion, "generic effect kind")
        require(genericEffect.genericEffects?.contains(.sound) == true, "generic sound")
        require(genericEffect.genericEffects?.contains(.cameraShake) == true, "generic shake")
        require(genericEffect.genericBubbleCount == 0 && !genericEffect.genericSpawnedSmoke,
                "generic first-frame child route")
        require(genericEffect.presentedEffects.map(\.kind) == [.sound, .cameraShake],
                "generic presentation order")
        require(genericRecord.model == SM64ExplosionKernel.model,
                "shared explosion model")
        require(genericRecord.behaviorIdentity == SM64ExplosionKernel.behaviorIdentity,
                "shared explosion behavior identity")
        require(genericRecord.parent == bombID, "generic parent generation")
        require(firstTick.scheduler.unloaded == [bombID], "bomb retired after request")
        fingerprint = hashEffect(fingerprint, bombEffect)
        fingerprint = hashEffect(fingerprint, genericEffect)

        var dying = bridge.genericExplosionState(for: genericID)!
        dying.timer = 9
        dying.opacity = 129
        require(bridge.setGenericExplosionState(dying, for: genericID, in: engine.objects),
                "generic state update")
        let deleteTick = bridge.tick(
            state: engine,
            genericExplosionInputs: [genericID: SM64ExplosionTickInput(waterAbove: true)]
        )
        guard let deleteEffect = deleteTick.effects.first(where: { $0.objectID == genericID }) else {
            preconditionFailure("generic deletion effect missing")
        }
        require(deleteEffect.genericBubbleCount == 40, "water bubble branch")
        require(deleteEffect.genericEffects?.contains(.markForDeletion) == true,
                "generic deletion effect")
        require(deleteTick.scheduler.unloaded == [genericID], "generic child retired")
        require(deleteTick.deliveries.contains { $0.deleted == [genericID] },
                "generic owner deletion delivery")
        fingerprint = hashEffect(fingerprint, deleteEffect)
        for delivery in deleteTick.deliveries {
            fingerprint = hashU64(fingerprint, UInt64(delivery.presented.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.deleted.count))
        }

        print(String(format: "bowserExplosionIntegrationFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bowser explosion integration smoke passed")
    }
}
