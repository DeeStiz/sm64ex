import Foundation

struct SM64ObjectBubbleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ObjectBubbleOutput
    let spawnedSplash: SM64ObjectID?
}

final class SM64ObjectBubbleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6F6262
    static let bubbleSplashBehaviorIdentity: UInt64 = SM64WaterSplashObjectBridge.bubbleBehaviorIdentity

    private let waterSplashBridge: SM64WaterSplashObjectBridge?

    private var waterLevels: [SM64ObjectID: Float] = [:]
    private(set) var effectLog: [SM64ObjectBubbleObjectEffectRecord] = []

    init(waterSplashBridge: SM64WaterSplashObjectBridge? = nil) {
        self.waterSplashBridge = waterSplashBridge
    }

    var registeredIDs: [SM64ObjectID] {
        waterLevels.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBubble(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, waterLevel: waterLevel, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned object bubble could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        waterLevel: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        waterLevels[id] = waterLevel
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64ObjectBubbleObjectEffectRecord? {
        guard let waterLevel = waterLevels[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64ObjectBubbleBehavior.update(
            SM64ObjectBubbleInput(position: record.position, waterLevel: waterLevel)
        )
        var splash: SM64ObjectID?
        if output.spawnSplash {
            splash = try? engineState.spawnObject(
                in: .default,
                behaviorIdentity: Self.bubbleSplashBehaviorIdentity,
                parent: id
            )
            if let splash {
                _ = waterSplashBridge?.attachBubbleSplash(
                    splash,
                    position: record.position,
                    waterLevel: waterLevel,
                    in: engineState.objects
                )
            }
        }
        if output.shouldDeactivate { _ = engineState.objects.markForDeletion(id) }
        let effect = SM64ObjectBubbleObjectEffectRecord(objectID: id, output: output, spawnedSplash: splash)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { waterLevels.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
