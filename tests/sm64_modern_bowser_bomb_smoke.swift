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
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    hash = hashU64(hash, effect.spawnedExplosionRequest ? 1 : 0)
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
enum SM64ModernBowserBombSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var bomb = SM64BowserBombState()
        let both = SM64BowserBombKernel.tickBomb(
            SM64BowserBombTickInput(collidedWithMario: true, hitMine: true),
            state: &bomb
        )
        require(bomb.markedForDeletion, "bomb deletion")
        require(both.effects.contains(.clearInteraction), "bomb interaction clear")
        require(both.effects.contains(.spawnExplosion), "bomb Mario explosion")
        require(both.effects.contains(.spawnFlames), "bomb mine flames")
        require(bomb.visibilityDistance == 7_000, "bomb visibility")
        fingerprint = hashU64(fingerprint, UInt64(both.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(bomb.timer))
        fingerprint = hashFloat(fingerprint, bomb.visibilityDistance)

        var explosion = SM64BowserBombExplosionState()
        let explosionTick = SM64BowserBombKernel.tickExplosion(
            SM64BowserBombExplosionTickInput(
                smokeSpawn: SM64BowserBombSmokeSpawn(
                    offset: SM64ObjectVector3(x: 11, y: 12, z: 13),
                    velocityY: 4
                )
            ),
            state: &explosion
        )
        require(explosion.scale == 1 && explosion.timer == 1, "explosion initial scale/timer")
        require(explosionTick.effects.contains(.spawnSmoke), "explosion smoke spawn")
        require(explosionTick.effects.contains(.animate), "explosion animation")
        require(explosionTick.smokeSpawn?.offset == SM64ObjectVector3(x: 11, y: 12, z: 13), "explosion smoke offset")
        fingerprint = hashU64(fingerprint, UInt64(explosionTick.effects.rawValue))
        fingerprint = hashFloat(fingerprint, explosion.scale)
        fingerprint = hashU64(fingerprint, UInt64(explosion.animationState))

        var smoke = SM64BowserBombSmokeState(
            position: SM64ObjectVector3(x: 1, y: 2, z: 3),
            velocityY: 4
        )
        let smokeTick = SM64BowserBombKernel.tickSmoke(state: &smoke)
        require(smoke.scale == 1 && smoke.opacity == 245, "smoke scale/opacity")
        require(smoke.position == SM64ObjectVector3(x: 1, y: 6, z: 3), "smoke velocity")
        require(smokeTick.effects.contains(.fade), "smoke fade")
        fingerprint = hashU64(fingerprint, UInt64(smokeTick.effects.rawValue))
        fingerprint = hashFloat(fingerprint, smoke.scale)
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(smoke.opacity)))
        fingerprint = hashFloat(fingerprint, smoke.position.y)

        let engine = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64BowserBombObjectBridge()
        let mineID = try bridge.spawnBomb(
            in: engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30)
        )
        let mineTick = bridge.tick(
            state: engine,
            bombInputs: [mineID: SM64BowserBombTickInput(hitMine: true)],
            explosionInputs: [:]
        )
        guard let mineEffect = mineTick.effects.first(where: { $0.objectID == mineID }) else {
            preconditionFailure("bomb owner effect missing")
        }
        require(mineEffect.kind == .bomb && mineEffect.spawnedChildren.count == 1, "bomb flame child")
        require(mineEffect.presentedEffects.map(\.kind) == [.sound, .cameraShake], "bomb presentation order")
        require(mineTick.scheduler.unloaded.contains(mineID), "bomb owner unload")
        require(mineTick.deliveries.contains { delivery in
            delivery.deleted == [mineID] && delivery.presented.count == 2
        }, "bomb owner delivery")
        fingerprint = hashEffect(fingerprint, mineEffect)
        for effect in mineTick.effects where effect.objectID != mineID {
            fingerprint = hashEffect(fingerprint, effect)
        }
        for delivery in mineTick.deliveries {
            fingerprint = hashU64(fingerprint, UInt64(delivery.presented.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.deleted.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.rejected.count))
        }

        let marioBombID = try bridge.spawnBomb(in: engine, position: .zero)
        let marioTick = bridge.tick(
            state: engine,
            bombInputs: [marioBombID: SM64BowserBombTickInput(collidedWithMario: true)]
        )
        guard let marioEffect = marioTick.effects.first(where: { $0.objectID == marioBombID }) else {
            preconditionFailure("Mario bomb effect missing")
        }
        require(marioEffect.spawnedExplosionRequest, "Mario explosion request")
        require(marioEffect.spawnedChildren.isEmpty, "Mario generic explosion remains explicit request")
        require(marioTick.scheduler.unloaded.contains(marioBombID), "Mario bomb unload")
        fingerprint = hashEffect(fingerprint, marioEffect)

        let explosionID = try bridge.spawnExplosion(
            in: engine,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300)
        )
        let explosionOwnerTick = bridge.tick(
            state: engine,
            explosionInputs: [explosionID: SM64BowserBombExplosionTickInput(
                smokeSpawn: SM64BowserBombSmokeSpawn(
                    offset: SM64ObjectVector3(x: 1, y: 2, z: 3),
                    velocityY: 5
                )
            )]
        )
        guard let explosionEffect = explosionOwnerTick.effects.first(where: { $0.objectID == explosionID }) else {
            preconditionFailure("explosion owner effect missing")
        }
        require(explosionEffect.spawnedChildren.count == 1, "explosion smoke child")
        require(explosionOwnerTick.effects.contains { $0.kind == .smoke }, "same-frame smoke update")
        fingerprint = hashEffect(fingerprint, explosionEffect)
        for effect in explosionOwnerTick.effects where effect.objectID != explosionID {
            fingerprint = hashEffect(fingerprint, effect)
        }

        print(String(format: "bowserBombFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bowser bomb smoke passed")
    }
}
