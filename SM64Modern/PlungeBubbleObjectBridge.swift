import Foundation

struct SM64PlungeBubbleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64PlungeBubbleOutput
    let spawnedParticles: [SM64ObjectID]
}

final class SM64PlungeBubbleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_706C_6231
    static let particleFlag: UInt32 = 1 << 9
    static let childBehaviorIdentity = SM64WaterParticleObjectBridge.smallBehaviorIdentity

    private let waterParticleBridge: SM64WaterParticleObjectBridge?
    private var states: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64PlungeBubbleObjectEffectRecord] = []

    init(waterParticleBridge: SM64WaterParticleObjectBridge? = nil) {
        self.waterParticleBridge = waterParticleBridge
    }

    var registeredIDs: [SM64ObjectID] { states.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPlunge(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = SM64PlungeBubbleObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, activeParticleFlags: activeParticleFlags, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned plunge bubble could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        activeParticleFlags: UInt32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.activeParticleFlags = activeParticleFlags
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64PlungeBubbleObjectEffectRecord? {
        guard states.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64PlungeBubbleBehavior.update(
            SM64PlungeBubbleInput(
                position: record.position,
                activeParticleFlags: record.activeParticleFlags,
                particleFlag: Self.particleFlag
            )
        )
        var spawned: [SM64ObjectID] = []
        for _ in 0..<output.spawnParticleCount {
            if let child = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: Self.childBehaviorIdentity,
                parent: id
            ) {
                spawned.append(child)
                _ = waterParticleBridge?.attach(
                    child,
                    kind: .small,
                    position: output.position,
                    initialOffset: .zero,
                    angleX: 0,
                    angleZ: 0,
                    angleVelocityX: 0x800,
                    angleVelocityZ: 0x800,
                    waterLevel: 100,
                    randomStepX: 0,
                    randomStepZ: 0,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            if output.clearParticleFlag { next.activeParticleFlags &= ~Self.particleFlag }
            if output.shouldDeactivate { next.activeFlags = 0 }
        }
        let effect = SM64PlungeBubbleObjectEffectRecord(objectID: id, output: output, spawnedParticles: spawned)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
