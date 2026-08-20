import Foundation

struct SM64WaterParticleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterParticleOutput
    let spawnedSplash: SM64ObjectID?
}

final class SM64WaterParticleObjectBridge {
    static let smallBehaviorIdentity: UInt64 = 0x6268_765F_7370_3131
    static let snowBehaviorIdentity: UInt64 = 0x6268_765F_7370_6E31
    static let bubblesBehaviorIdentity: UInt64 = 0x6268_765F_7362_6C31

    private struct State {
        let kind: SM64WaterParticleKind
        let waterLevel: Float
        let randomStepX: Float
        let randomStepZ: Float
        var angleX: Int32
        var angleZ: Int32
        let angleVelocityX: Int32
        let angleVelocityZ: Int32
    }

    private let waterSplashBridge: SM64WaterSplashObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaterParticleObjectEffectRecord] = []

    init(waterSplashBridge: SM64WaterSplashObjectBridge? = nil) {
        self.waterSplashBridge = waterSplashBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnParticle(
        in engineState: SM64SwiftEngineState,
        kind: SM64WaterParticleKind = .small,
        position: SM64ObjectVector3 = .zero,
        initialOffset: SM64ObjectVector3 = .zero,
        angleX: Int32 = 0,
        angleZ: Int32 = 0,
        angleVelocityX: Int32 = 0x800,
        angleVelocityZ: Int32 = 0x800,
        waterLevel: Float = 100,
        randomStepX: Float = 0,
        randomStepZ: Float = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let identity: UInt64
        switch kind {
        case .small: identity = Self.smallBehaviorIdentity
        case .snow: identity = Self.snowBehaviorIdentity
        case .bubbles: identity = Self.bubblesBehaviorIdentity
        }
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: identity, parent: parent)
        guard attach(
            id,
            kind: kind,
            position: position,
            initialOffset: initialOffset,
            angleX: angleX,
            angleZ: angleZ,
            angleVelocityX: angleVelocityX,
            angleVelocityZ: angleVelocityZ,
            waterLevel: waterLevel,
            randomStepX: randomStepX,
            randomStepZ: randomStepZ,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water particle could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64WaterParticleKind,
        position: SM64ObjectVector3,
        initialOffset: SM64ObjectVector3,
        angleX: Int32,
        angleZ: Int32,
        angleVelocityX: Int32,
        angleVelocityZ: Int32,
        waterLevel: Float,
        randomStepX: Float,
        randomStepZ: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            kind: kind,
            waterLevel: waterLevel,
            randomStepX: randomStepX,
            randomStepZ: randomStepZ,
            angleX: angleX,
            angleZ: angleZ,
            angleVelocityX: angleVelocityX,
            angleVelocityZ: angleVelocityZ
        )
        return pool.mutate(id) { record in
            record.position = SM64ObjectVector3(
                x: position.x + initialOffset.x,
                y: position.y + initialOffset.y,
                z: position.z + initialOffset.z
            )
            record.homePosition = record.position
            record.scale = .init(x: 2, y: 2, z: 1)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WaterParticleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WaterParticleBehavior.update(
            SM64WaterParticleInput(
                kind: state.kind,
                position: record.position,
                angleX: state.angleX,
                angleZ: state.angleZ,
                angleVelocityX: state.angleVelocityX,
                angleVelocityZ: state.angleVelocityZ,
                timer: record.timer,
                waterLevel: state.waterLevel,
                randomStepX: state.randomStepX,
                randomStepZ: state.randomStepZ
            )
        )
        state.angleX = output.angleX
        state.angleZ = output.angleZ
        states[id] = state
        var splash: SM64ObjectID?
        if output.spawnObjectSplash {
            splash = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: SM64WaterSplashObjectBridge.objectBehaviorIdentity,
                parent: id
            )
            if let splash {
                _ = waterSplashBridge?.attachObjectSplash(
                    splash,
                    position: output.position,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale.x = output.scaleX
            next.scale.y = output.scaleY
            next.timer = output.timer
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete || output.shouldDeactivate { next.activeFlags = 0 }
        }
        let effect = SM64WaterParticleObjectEffectRecord(objectID: id, output: output, spawnedSplash: splash)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
