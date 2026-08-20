import Foundation

struct SM64ActSelectorStarTypeObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ActSelectorStarTypeOutput
}

final class SM64ActSelectorStarTypeObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_617374
    static let starModel: UInt32 = 0x7A // MODEL_STAR

    private struct State {
        let type: SM64ActSelectorStarType
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ActSelectorStarTypeObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnStar(
        in engineState: SM64SwiftEngineState,
        type: SM64ActSelectorStarType = .notSelected,
        position: SM64ObjectVector3 = .zero,
        size: Float = 1
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: Self.starModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, type: type, position: position, size: size, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned act-selector star type could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        type: SM64ActSelectorStarType,
        position: SM64ObjectVector3,
        size: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(type: type)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: size, y: size, z: size)
            record.animationState = Int32(type.rawValue)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64ActSelectorStarTypeObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64ActSelectorStarTypeBehavior.update(
            .init(
                type: state.type,
                size: record.scale.x,
                faceYaw: record.faceAngles.yaw,
                timer: record.timer
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.faceAngles.yaw = output.faceYaw
            next.animationState = Int32(output.type.rawValue)
            next.timer = output.timer
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64ActSelectorStarTypeObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
