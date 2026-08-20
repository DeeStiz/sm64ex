import Foundation

struct SM64BlackSmokeUpwardObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BlackSmokeUpwardOutput
    let spawnedChild: SM64ObjectID?
}

final class SM64BlackSmokeUpwardObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_627531

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64BlackSmokeUpwardObjectEffectRecord] = []
    private let bowserSmokeBridge: SM64BlackSmokeBowserObjectBridge

    init(bowserSmokeBridge: SM64BlackSmokeBowserObjectBridge) {
        self.bowserSmokeBridge = bowserSmokeBridge
    }

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnUpward(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        scale: Float = 1,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(id, position: position, scale: scale, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned upward black smoke could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        scale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: scale, y: scale, z: scale)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64BlackSmokeUpwardObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64BlackSmokeUpwardBehavior.update(.init(
            position: record.position,
            scale: record.scale.x,
            timer: record.timer
        ))

        var child: SM64ObjectID?
        if output.spawnChild {
            child = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: SM64BlackSmokeBowserObjectBridge.defaultBehaviorIdentity,
                parent: id
            )
            if let child {
                _ = bowserSmokeBridge.attach(
                    child,
                    position: output.position,
                    initialMoveYaw: 0,
                    initialForwardVelocity: 1.25,
                    initialVelocityY: 8,
                    angleVelocityYaw: 0,
                    scale: output.scale,
                    in: engineState.objects
                )
            }
        }

        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.timer = output.shouldDeactivate ? 4 : record.timer + 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }

        let effect = SM64BlackSmokeUpwardObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedChild: child
        )
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
