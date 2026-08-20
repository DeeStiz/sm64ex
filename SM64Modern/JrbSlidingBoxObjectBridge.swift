import Foundation

struct SM64JrbSlidingBoxObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64JrbSlidingBoxOutput
}

final class SM64JrbSlidingBoxObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6A7362
    static let defaultModel: UInt32 = 0
    private struct State { let parent: SM64ObjectID; var relativePosition: SM64ObjectVector3; var phase: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64JrbSlidingBoxObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBox(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, relativePosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        guard let parentRecord = engineState.objects.record(for: parent) else { throw SM64ObjectPoolError.invalidReference(parent) }
        let id = try engineState.spawnObject(in: .surface, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, parent: parent, relativePosition: relativePosition, position: .init(x: parentRecord.position.x + relativePosition.x, y: parentRecord.position.y + relativePosition.y, z: parentRecord.position.z + relativePosition.z), in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned JRB sliding box could not attach") }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, parent: SM64ObjectID, relativePosition: SM64ObjectVector3, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        states[id] = State(parent: parent, relativePosition: relativePosition, phase: 0)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.interactionType = 1
            record.damageOrCoinValue = 1
            record.health = 1
            record.hitboxRadius = 130
            record.hitboxHeight = 100
            record.collisionDistance = 4_000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id), let parent = engineState.objects.record(for: state.parent) else { return false }
        let output = SM64JrbSlidingBoxBehavior.update(.init(parentPosition: parent.position, parentAngles: parent.faceAngles, relativePosition: state.relativePosition, phase: state.phase, y: record.position.y))
        state.relativePosition = output.relativePosition
        state.phase = output.phase
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.faceAngles = output.faceAngles
            next.interactionType = output.tangible ? 1 : 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
