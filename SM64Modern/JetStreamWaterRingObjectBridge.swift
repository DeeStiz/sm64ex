import Foundation

struct SM64JetStreamWaterRingObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64JetStreamWaterRingOutput
}

final class SM64JetStreamWaterRingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6A7772
    static let defaultModel: UInt32 = 0
    private struct State { var opacity: Int32; var averageScale: Float; var marioNear: Bool; var crossedPlane: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64JetStreamWaterRingObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnRing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, opacity: Int32 = 70, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, position: position, opacity: opacity, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Jet Stream water ring could not attach") }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, opacity: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(opacity: opacity, averageScale: 0.5, marioNear: false, crossedPlane: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.opacity = opacity
            record.hitboxRadius = 75
            record.hitboxHeight = 20
            record.hitboxDownOffset = 20
            record.interactionType = 1 << 25
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setCollectionInput(marioNear: Bool, crossedRingPlane: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.marioNear = marioNear
        state.crossedPlane = crossedRingPlane
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64JetStreamWaterRingBehavior.update(.init(action: record.action, timer: record.timer, opacity: state.opacity, averageScale: state.averageScale, position: record.position, faceYaw: record.faceAngles.yaw, marioNear: state.marioNear, crossedRingPlane: state.crossedPlane))
        state.opacity = output.opacity
        state.averageScale = output.averageScale
        state.marioNear = false
        state.crossedPlane = false
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.opacity = output.opacity
            next.position = output.position
            next.faceAngles.yaw = output.faceYaw
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.intangibleTimer = output.action == 0 ? -1 : 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
