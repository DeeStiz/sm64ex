import Foundation

struct SM64BlueFishObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BlueFishOutput
}

struct SM64TankFishGroupObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TankFishGroupOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64BlueFishObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626C66
    static let tankFishGroupBehaviorIdentity: UInt64 = 0x6268_765F_746667
    static let defaultModel: UInt32 = 0x65 // MODEL_FISH

    private struct State {
        var randomAngle: Int32
        var randomVelocity: Float
        var randomTime: Int32
        var parentDuplicate: Bool
    }
    private struct GroupState { var action: Int32; var room: Int32 }

    private var states: [SM64ObjectID: State] = [:]
    private var groups: [SM64ObjectID: GroupState] = [:]
    private(set) var effectLog: [SM64BlueFishObjectEffectRecord] = []
    private(set) var groupEffectLog: [SM64TankFishGroupObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        (Array(states.keys) + Array(groups.keys)).sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true); groupEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnTankFishGroup(in engineState: SM64SwiftEngineState, room: Int32 = 15, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.tankFishGroupBehaviorIdentity)
        guard attachTankFishGroup(id, room: room, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned tank fish group could not attach")
        }
        return id
    }

    @discardableResult
    func attachTankFishGroup(_ id: SM64ObjectID, room: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        groups[id] = GroupState(action: 0, room: room)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setTankFishRoom(_ room: Int32, for id: SM64ObjectID) -> Bool {
        guard var state = groups[id] else { return false }
        state.room = room
        groups[id] = state
        return true
    }

    @discardableResult
    func spawnFish(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomAngle: Int32 = 0x800,
        randomVelocity: Float = 1,
        randomTime: Int32 = 20,
        angleVelocityPitch: Int32 = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, position: position, randomAngle: randomAngle, randomVelocity: randomVelocity, randomTime: randomTime, angleVelocityPitch: angleVelocityPitch, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned blue fish could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        randomAngle: Int32,
        randomVelocity: Float,
        randomTime: Int32,
        angleVelocityPitch: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(randomAngle: randomAngle, randomVelocity: randomVelocity, randomTime: randomTime, parentDuplicate: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.angleVelocity.pitch = angleVelocityPitch
            record.gravity = 0
            record.friction = 1
            record.buoyancy = 1.5
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setParentDuplicate(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.parentDuplicate = value
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if var group = groups[id], let record = engineState.objects.record(for: id) {
            let output = SM64BlueFishBehavior.updateTankFishGroup(action: group.action, room: group.room)
            var children: [SM64ObjectID] = []
            if output.spawnFish {
                for index in 0..<output.childCount {
                    let offset = Float(index * 25)
                    if let child = try? spawnFish(
                        in: engineState,
                        position: .init(x: record.position.x + 300 + offset, y: record.position.y, z: record.position.z - 200),
                        randomAngle: Int32(index) << 8,
                        randomVelocity: 1,
                        randomTime: 20,
                        parent: id
                    ) {
                        children.append(child)
                    }
                }
            }
            group.action = output.action
            groups[id] = group
            _ = engineState.objects.mutate(id) { next in
                next.action = output.action
                next.timer = 0
            }
            groupEffectLog.append(.init(objectID: id, output: output, spawnedChildren: children))
            return true
        }
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64BlueFishBehavior.update(.init(
            action: SM64BlueFishAction(rawValue: record.action) ?? .dive,
            timer: record.timer,
            position: record.position,
            moveYaw: record.moveAngles.yaw,
            facePitch: record.faceAngles.pitch,
            angleVelocityPitch: record.angleVelocity.pitch,
            forwardVelocity: record.forwardVelocity,
            randomAngle: state.randomAngle,
            randomVelocity: state.randomVelocity,
            randomTime: state.randomTime,
            parentDuplicate: state.parentDuplicate
        ))
        state.parentDuplicate = false
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action.rawValue
            next.timer = output.timer
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.pitch = output.facePitch
            next.angleVelocity.pitch = output.angleVelocityPitch
            next.forwardVelocity = output.forwardVelocity
            next.velocity = output.velocity
            next.animationState = Int32(output.animationAcceleration * 100)
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id); groups.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
