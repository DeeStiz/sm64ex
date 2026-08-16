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

private func hashIntent(_ initial: UInt64, _ intent: SM64OwnerThreadEffectIntent) -> UInt64 {
    var hash = hashU64(initial, UInt64(intent.kind.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    return hashU64(hash, UInt64(bitPattern: Int64(intent.auxiliary)))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernWhompBossOwnerSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64WhompObjectBridge()
        let id = try bridge.spawnWhomp(in: engine, size: .king, action: .initialize)

        let intro = bridge.tick(
            state: engine,
            inputs: [id: SM64WhompTickInput(distanceToMario: 500)],
            presentBossEffects: true
        )
        guard let introEffect = intro.effects.first,
              let introDelivery = bridge.deliveryLog.last else {
            preconditionFailure("King Whomp intro owner result is missing")
        }
        require(introEffect.action == .initialize, "King Whomp intro remains in initialize")
        require(introEffect.effects.contains([.cameraFocus, .bossMusic]),
                "King Whomp intro requests camera and boss music")
        require(introDelivery.rejected.isEmpty, "King Whomp intro intents are accepted")
        require(introEffect.presentedEffects.map(\.kind) == [.music, .cameraFocus],
                "King Whomp music precedes camera focus")
        require(introEffect.presentedEffects.last?.value == SM64WhompObjectBridge.bossCameraModeValue,
                "King Whomp camera mode payload")

        require(
            bridge.attach(id, size: .king, action: .death, in: engine.objects),
            "King Whomp death state can be reattached for owner contract"
        )
        let death = bridge.tick(
            state: engine,
            inputs: [id: SM64WhompTickInput(dialogComplete: true)],
            presentBossEffects: true,
            spawnRewardStar: true
        )
        guard let deathEffect = death.effects.first,
              let starID = deathEffect.spawnedChildren.first,
              let star = engine.objects.record(for: starID),
              let parent = engine.objects.record(for: id),
              let deathDelivery = bridge.deliveryLog.last else {
            preconditionFailure("King Whomp reward owner result is missing")
        }
        require(deathEffect.action == .bossWait, "King Whomp defeat enters boss wait")
        require(deathEffect.effects.contains(.star), "King Whomp defeat emits star effect")
        require(deathEffect.spawnedChildren.count == 1, "one King Whomp reward star spawns")
        require(star.parent == parent.id, "King Whomp reward star parent")
        require(star.objectList == .level, "King Whomp reward star list")
        require(star.model == SM64WhompObjectBridge.starModel, "King Whomp reward star model")
        require(star.behaviorIdentity == SM64WhompObjectBridge.starBehaviorIdentity,
                "King Whomp reward star behavior")
        require(star.position == SM64WhompObjectBridge.kingWhompStarPosition,
                "King Whomp source reward coordinates")
        require(deathDelivery.rejected.isEmpty, "King Whomp defeat intents are accepted")
        require(deathEffect.presentedEffects.map(\.kind) == [
            .sound, .particle, .particle, .cameraShake, .star
        ], "King Whomp defeat presentation ordering")

        var fingerprint = fnvOffset
        fingerprint = hashU64(fingerprint, UInt64(introEffect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(introEffect.action.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(introEffect.presentedEffects.count))
        for intent in introEffect.presentedEffects {
            fingerprint = hashIntent(fingerprint, intent)
        }
        fingerprint = hashU64(fingerprint, UInt64(deathEffect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(deathEffect.action.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(starID.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(star.model))
        fingerprint = hashU64(fingerprint, UInt64(star.position.x.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(star.position.y.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(star.position.z.bitPattern))
        fingerprint = hashU64(fingerprint, star.behaviorIdentity)
        fingerprint = hashU64(fingerprint, UInt64(parent.id.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(deathEffect.presentedEffects.count))
        for intent in deathEffect.presentedEffects {
            fingerprint = hashIntent(fingerprint, intent)
        }
        print(String(format: "whompBossOwnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Whomp King owner smoke passed")
    }
}
