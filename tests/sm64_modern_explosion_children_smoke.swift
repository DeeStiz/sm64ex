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
    _ effect: SM64ExplosionObjectEffectRecord
) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.bubbleCount))
    hash = hashU64(hash, effect.spawnedSmoke ? 1 : 0)
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    hash = hashU64(hash, UInt64(effect.timer))
    hash = hashFloat(hash, effect.scale)
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.animationState)))
    hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    return hash
}

@main
enum SM64ModernExplosionChildrenSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var bubble = SM64ExplosionChildrenKernel.makeBubble(
            parentPosition: SM64ObjectVector3(x: 10, y: 20, z: 30),
            input: SM64ExplosionBubbleSpawnInput(
                positionOffset: SM64ObjectVector3(x: 1, y: 2, z: 3),
                microOffset: SM64ObjectVector3(x: 4, y: 0, z: -2),
                expansionRateX: 0x900,
                expansionRateY: 0xA00,
                initialTimer: 4,
                velocityY: 6
            )
        )
        require(bubble.position == SM64ObjectVector3(x: 15, y: 22, z: 31), "bubble spawn position")
        require(bubble.scale == SM64ObjectVector3(x: 2, y: 2, z: 1), "bubble initial scale")
        let bubbleDelay = SM64ExplosionChildrenKernel.tickBubble(
            SM64ExplosionBubbleTickInput(waterLevel: 1_000),
            state: &bubble
        )
        require(bubbleDelay.effects == [.delay] && !bubbleDelay.spawnedSplash,
                "bubble delay")
        bubble.position.y = 20
        let bubbleTick = SM64ExplosionChildrenKernel.tickBubble(
            SM64ExplosionBubbleTickInput(waterLevel: 10),
            state: &bubble
        )
        require(bubbleTick.spawnedSplash && bubble.markedForDeletion, "bubble splash/deletion")
        require(bubble.position.y == 31, "bubble splash then velocity")
        fingerprint = hashU64(fingerprint, UInt64(bubbleTick.effects.rawValue))
        fingerprint = hashFloat(fingerprint, bubble.scale.x)
        fingerprint = hashFloat(fingerprint, bubble.position.y)

        var smoke = SM64ExplosionChildrenKernel.makeGroundSmoke(
            parentPosition: SM64ObjectVector3(x: 5, y: 300, z: 7)
        )
        require(smoke.position == SM64ObjectVector3(x: 5, y: 0, z: 7), "ground smoke offset")
        require(smoke.scale == 10, "ground smoke scale")
        let smokeDelay = SM64ExplosionChildrenKernel.tickGroundSmoke(state: &smoke)
        require(smokeDelay.effects == [.delay], "ground smoke delay")
        smoke.smokeTimer = 10
        let smokeTick = SM64ExplosionChildrenKernel.tickGroundSmoke(state: &smoke)
        require(smokeTick.effects.contains(.markForDeletion) && smoke.markedForDeletion,
                "ground smoke deletion")
        fingerprint = hashU64(fingerprint, UInt64(smokeTick.effects.rawValue))
        fingerprint = hashFloat(fingerprint, smoke.scale)
        fingerprint = hashU64(fingerprint, UInt64(smoke.animationState))

        let engine = SM64SwiftEngineState(objectCapacity: 96)
        let bridge = SM64ExplosionObjectBridge()
        let waterExplosion = try bridge.spawnExplosion(
            in: engine,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300)
        )
        var waterState = bridge.state(for: waterExplosion)!
        waterState.timer = 9
        require(bridge.setState(waterState, for: waterExplosion, in: engine.objects),
                "water explosion state")
        let waterTick = bridge.tick(
            state: engine,
            inputs: [waterExplosion: SM64ExplosionTickInput(
                waterAbove: true,
                bubbleWaterLevel: -1_000
            )]
        )
        guard let waterEffect = waterTick.effects.first(where: { $0.objectID == waterExplosion }) else {
            preconditionFailure("water explosion effect missing")
        }
        require(waterEffect.spawnedChildren.count == 40, "forty bubble children")
        require(waterTick.scheduler.unloaded == [waterExplosion], "water explosion unload")
        require(waterEffect.spawnedChildren.allSatisfy { bridge.bubbleState(for: $0) != nil },
                "bubble child state ownership")
        fingerprint = hashEffect(fingerprint, waterEffect)

        let bubbleRetireTick = bridge.tick(state: engine)
        require(bubbleRetireTick.scheduler.unloaded.count == 40, "bubble child retirement")
        require(bubbleRetireTick.deliveries.filter { !$0.deleted.isEmpty }.count == 40,
                "bubble deletion delivery count")

        let groundExplosion = try bridge.spawnExplosion(
            in: engine,
            position: SM64ObjectVector3(x: 400, y: 500, z: 600)
        )
        var groundState = bridge.state(for: groundExplosion)!
        groundState.timer = 9
        require(bridge.setState(groundState, for: groundExplosion, in: engine.objects),
                "ground explosion state")
        let groundTick = bridge.tick(state: engine)
        guard let groundEffect = groundTick.effects.first(where: { $0.objectID == groundExplosion }) else {
            preconditionFailure("ground explosion effect missing")
        }
        require(groundEffect.spawnedChildren.count == 1 && groundEffect.spawnedSmoke,
                "ground smoke child")
        let smokeID = groundEffect.spawnedChildren[0]
        require(bridge.groundSmokeState(for: smokeID) != nil, "ground smoke state ownership")
        fingerprint = hashEffect(fingerprint, groundEffect)

        var smokeRetireTick = SM64ExplosionSchedulerTickResult(
            scheduler: SM64ObjectSchedulerTickResult(
                frame: 0,
                listCounts: [],
                objectCounter: 0,
                updated: [],
                skippedByTimeStop: [],
                unloaded: [],
                timeStopWasActive: false,
                timeStopIsActive: false
            ),
            effects: [],
            deliveries: []
        )
        for _ in 0..<11 {
            smokeRetireTick = bridge.tick(state: engine)
        }
        require(smokeRetireTick.scheduler.unloaded == [smokeID], "ground smoke retirement")

        print(String(format: "explosionChildrenFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern explosion children smoke passed")
    }
}
