import Foundation

struct SM64WaterDropletObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterDropletOutput
    let spawnedSplash: SM64ObjectID?
}

final class SM64WaterDropletObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_776472
    static let splashBehaviorIdentity: UInt64 = SM64WaterSplashObjectBridge.waterDropletBehaviorIdentity

    private let waterSplashBridge: SM64WaterSplashObjectBridge?

    private var waterLevels: [SM64ObjectID: Float] = [:]
    private(set) var effectLog: [SM64WaterDropletObjectEffectRecord] = []

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
    func spawnDroplet(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocityY: Float = 20,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, velocityY: velocityY, waterLevel: waterLevel, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water droplet could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        velocityY: Float,
        waterLevel: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        waterLevels[id] = waterLevel
        return pool.mutate(id) { record in
            record.position = position
            record.velocity.y = velocityY
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WaterDropletObjectEffectRecord? {
        guard let waterLevel = waterLevels[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WaterDropletBehavior.update(
            SM64WaterDropletInput(
                position: record.position,
                velocityY: record.velocity.y,
                timer: record.timer,
                waterLevel: waterLevel,
                interacted: record.interactionStatus != 0
            )
        )
        var splash: SM64ObjectID?
        if output.spawnSplash {
            splash = try? engineState.spawnObject(
                in: .default,
                behaviorIdentity: Self.splashBehaviorIdentity,
                parent: id
            )
            if let splash {
                _ = waterSplashBridge?.attachWaterDropletSplash(
                    splash,
                    position: output.position,
                    randomScale: 0,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.velocity.y = output.velocityY
            next.timer = output.timer
            next.interactionStatus = 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64WaterDropletObjectEffectRecord(objectID: id, output: output, spawnedSplash: splash)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { waterLevels.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
