import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashIntent(_ initial: UInt64, _ intent: SM64OwnerThreadEffectIntent) -> UInt64 {
    var hash = hashU32(initial, UInt32(intent.kind.rawValue))
    hash = hashU32(hash, UInt32(bitPattern: intent.value))
    return hashU32(hash, UInt32(bitPattern: intent.auxiliary))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernKingBobombRewardStarSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64KingBobombObjectBridge()
        let id = try bridge.spawnKingBobomb(
            in: engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30),
            action: SM64KingBobombBehavior.deathAction
        )
        let tick = bridge.tick(
            state: engine,
            environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
                positionY: 20,
                dialogComplete: true
            ))],
            spawnRewardStar: true
        )
        guard let effect = tick.effects.first,
              let starID = effect.spawnedChildren.first,
              let star = engine.objects.record(for: starID),
              let parent = engine.objects.record(for: id),
              let delivery = tick.deliveries.first else {
            preconditionFailure("King Bob-omb reward star owner result is missing")
        }
        require(effect.output.state.action == SM64KingBobombBehavior.bossWaitAction,
                "defeat enters boss wait after reward spawn")
        require(effect.output.starPosition?.x == 2_000
                    && effect.output.starPosition?.y == 4_500
                    && effect.output.starPosition?.z == -4_500,
                "source defeat star position is preserved")
        require(effect.spawnedChildren.count == 1, "one reward star is spawned")
        require(star.parent == parent.id, "reward star is parented to King Bob-omb")
        require(star.objectList == .level, "reward star uses the level object list")
        require(star.model == SM64KingBobombObjectBridge.starModel,
                "reward star model identity")
        require(star.behaviorIdentity == SM64KingBobombObjectBridge.starBehaviorIdentity,
                "reward star behavior identity")
        require(star.position == SM64ObjectVector3(x: 2_000, y: 4_500, z: -4_500),
                "reward star transform")
        require(delivery.rejected.isEmpty, "defeat presentation intents are accepted")
        require(delivery.presented.contains(where: { $0.kind == .star && $0.value == 1 }),
                "reward star presentation intent")

        var fingerprint = fnvOffset
        fingerprint = hashU32(fingerprint, effect.output.effects.rawValue)
        fingerprint = hashU32(fingerprint, UInt32(bitPattern: effect.output.state.action))
        if let position = effect.output.starPosition {
            fingerprint = hashU32(fingerprint, position.x.bitPattern)
            fingerprint = hashU32(fingerprint, position.y.bitPattern)
            fingerprint = hashU32(fingerprint, position.z.bitPattern)
        }
        fingerprint = hashU32(fingerprint, starID.traceSubject)
        fingerprint = hashU32(fingerprint, star.model)
        fingerprint = hashU64(fingerprint, star.behaviorIdentity)
        fingerprint = hashU32(fingerprint, parent.id.traceSubject)
        fingerprint = hashU32(fingerprint, UInt32(delivery.presented.count))
        for intent in delivery.presented {
            fingerprint = hashIntent(fingerprint, intent)
        }
        print(String(format: "kingBobombRewardStarFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb reward star smoke passed")
    }
}
