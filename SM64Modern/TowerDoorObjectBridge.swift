import Foundation

struct SM64TowerDoorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TowerDoorOutput
}

final class SM64TowerDoorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747764

    private struct State { var marioAttacking: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TowerDoorObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnDoor(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, faceYaw: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, faceYaw: faceYaw, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned tower door could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, faceYaw: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(marioAttacking: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = faceYaw
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setMarioAttacking(_ attacking: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.marioAttacking = attacking
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var objectState = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64TowerDoorBehavior.update(.init(timer: record.timer, faceYaw: record.faceAngles.yaw, marioAttacking: objectState.marioAttacking))
        objectState.marioAttacking = false
        states[id] = objectState
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.faceAngles.yaw = output.faceYaw
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
