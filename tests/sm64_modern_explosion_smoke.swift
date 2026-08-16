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

private func hashEffect(_ initial: UInt64, _ effect: SM64ExplosionObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.bubbleCount)))
    hash = hashU64(hash, effect.spawnedSmoke ? 1 : 0)
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
enum SM64ModernExplosionSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var value = SM64ExplosionState()
        let initTick = SM64ExplosionKernel.tick(SM64ExplosionTickInput(), state: &value)
        require(initTick.effects.contains(.sound), "explosion init sound")
        require(initTick.effects.contains(.cameraShake), "explosion init shake")
        require(value.timer == 1 && value.scale == 1 && value.opacity == 241, "explosion initial state")
        require(value.animationState == 0, "explosion animation increment")
        fingerprint = hashU64(fingerprint, UInt64(initTick.effects.rawValue))
        fingerprint = hashFloat(fingerprint, value.scale)
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(value.opacity)))

        value.timer = 9
        value.opacity = 129 // frames 1...8 of bhv_explosion_loop
        let waterTick = SM64ExplosionKernel.tick(
            SM64ExplosionTickInput(waterAbove: true),
            state: &value
        )
        require(waterTick.bubbleCount == 40 && !waterTick.spawnedSmoke, "water explosion child route")
        require(value.markedForDeletion && waterTick.effects.contains(.markForDeletion), "explosion deletion")
        require(value.scale == 2 && value.opacity == 115, "explosion frame nine scale/opacity")
        fingerprint = hashU64(fingerprint, UInt64(waterTick.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(waterTick.bubbleCount)))
        fingerprint = hashFloat(fingerprint, value.scale)

        var ground = SM64ExplosionState()
        ground.timer = 9
        let groundTick = SM64ExplosionKernel.tick(
            SM64ExplosionTickInput(waterAbove: false),
            state: &ground
        )
        require(groundTick.spawnedSmoke && groundTick.bubbleCount == 0, "ground explosion child route")
        fingerprint = hashU64(fingerprint, UInt64(groundTick.effects.rawValue))
        fingerprint = hashU64(fingerprint, groundTick.spawnedSmoke ? 1 : 0)

        let engine = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64ExplosionObjectBridge()
        let id = try bridge.spawnExplosion(
            in: engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30)
        )
        let initOwner = bridge.tick(state: engine)
        guard let ownerEffect = initOwner.effects.first,
              let ownerRecord = engine.objects.record(for: id) else {
            preconditionFailure("explosion owner record missing")
        }
        require(ownerEffect.presentedEffects.map(\.kind) == [.sound, .cameraShake], "explosion owner presentation")
        require(ownerRecord.interactionType == SM64ExplosionKernel.interactionType, "explosion owner hitbox")
        require(ownerRecord.damageOrCoinValue == 2 && ownerRecord.opacity == 241, "explosion owner fields")
        fingerprint = hashEffect(fingerprint, ownerEffect)
        fingerprint = hashU64(fingerprint, UInt64(ownerRecord.interactionType))

        var dying = bridge.state(for: id)!
        dying.timer = 9
        require(bridge.setState(dying, for: id, in: engine.objects), "explosion owner dying state")
        let deleteOwner = bridge.tick(
            state: engine,
            inputs: [id: SM64ExplosionTickInput(waterAbove: true)]
        )
        guard let deleteEffect = deleteOwner.effects.first else {
            preconditionFailure("explosion delete effect missing")
        }
        require(deleteEffect.bubbleCount == 40, "explosion owner bubble request")
        require(deleteOwner.scheduler.unloaded == [id], "explosion owner unload")
        require(deleteOwner.deliveries.contains { $0.deleted == [id] }, "explosion owner delete delivery")
        fingerprint = hashEffect(fingerprint, deleteEffect)
        for delivery in deleteOwner.deliveries {
            fingerprint = hashU64(fingerprint, UInt64(delivery.presented.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.deleted.count))
        }

        print(String(format: "explosionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern explosion smoke passed")
    }
}
