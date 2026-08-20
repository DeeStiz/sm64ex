import Foundation

struct SM64AnimatedTextureObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64AnimatedTextureOutput
}

final class SM64AnimatedTextureObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6174_7874

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64AnimatedTextureObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnAnimatedTexture(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = 0,
        animationState: Int32 = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            animationState: animationState,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned animated texture could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        animationState: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.animationState = animationState
            record.wallHitboxRadius = 30
            record.gravity = -400
            record.dragStrength = 1000
            record.friction = 1000
            record.buoyancy = 200
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64AnimatedTextureObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64AnimatedTextureBehavior.update(
            SM64AnimatedTextureInput(
                position: record.position,
                homePosition: record.homePosition,
                animationState: record.animationState,
                globalFrame: engineState.globals.frame
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.animationState = output.animationState
            next.timer &+= 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64AnimatedTextureObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
