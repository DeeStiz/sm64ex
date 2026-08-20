import Foundation

struct SM64WaterSplashObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterSplashOutput
}

final class SM64WaterSplashObjectBridge {
    static let bubbleBehaviorIdentity: UInt64 = 0x6268_765F_6273_7031
    static let waterDropletBehaviorIdentity: UInt64 = 0x6268_765F_7764_7331
    static let objectBehaviorIdentity: UInt64 = 0x6268_765F_6F77_7331

    private struct State {
        let kind: SM64WaterSplashKind
        let waterLevel: Float
        let randomScale: Float
        var timer: Int32
        var animationState: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaterSplashObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBubbleSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.bubbleBehaviorIdentity
        )
        guard attachBubbleSplash(id, position: position, waterLevel: waterLevel, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned bubble splash could not attach")
        }
        return id
    }

    @discardableResult
    func spawnWaterDropletSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomScale: Float = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.waterDropletBehaviorIdentity
        )
        guard attachWaterDropletSplash(id, position: position, randomScale: randomScale, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water-droplet splash could not attach")
        }
        return id
    }

    @discardableResult
    func spawnObjectSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.objectBehaviorIdentity
        )
        guard attachObjectSplash(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned object water splash could not attach")
        }
        return id
    }

    @discardableResult
    func attachBubbleSplash(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        waterLevel: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        attach(
            id,
            kind: .bubble,
            position: position,
            waterLevel: waterLevel,
            randomScale: 0,
            in: pool
        )
    }

    @discardableResult
    func attachWaterDropletSplash(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        randomScale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        attach(
            id,
            kind: .waterDroplet,
            position: position,
            waterLevel: -.greatestFiniteMagnitude,
            randomScale: randomScale,
            in: pool
        )
    }

    @discardableResult
    func attachObjectSplash(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        attach(
            id,
            kind: .object,
            position: position,
            waterLevel: -.greatestFiniteMagnitude,
            randomScale: 0,
            in: pool
        )
    }

    @discardableResult
    private func attach(
        _ id: SM64ObjectID,
        kind: SM64WaterSplashKind,
        position: SM64ObjectVector3,
        waterLevel: Float,
        randomScale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            kind: kind,
            waterLevel: waterLevel,
            randomScale: randomScale,
            timer: 0,
            animationState: -1
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WaterSplashObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WaterSplashBehavior.update(
            SM64WaterSplashInput(
                kind: state.kind,
                position: record.position,
                waterLevel: state.waterLevel,
                randomScale: state.randomScale,
                timer: state.timer,
                animationState: state.animationState
            )
        )
        state.timer &+= 1
        state.animationState = output.animationState
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale = output.scale
            next.animationState = output.animationState
            next.timer = state.timer
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64WaterSplashObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
