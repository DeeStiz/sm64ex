import Foundation

struct SM64DonutPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64DonutPlatformOutput
    let spawnedPlatforms: [SM64ObjectID]
}

final class SM64DonutPlatformObjectBridge {
    static let spawnerBehaviorIdentity: UInt64 = 0x6268_765F_646E73
    static let platformBehaviorIdentity: UInt64 = 0x6268_765F_646E70
    static let platformModel: UInt32 = 0x3F // MODEL_RR_DONUT_PLATFORM

    private struct State {
        let role: SM64DonutPlatformRole
        let parent: SM64ObjectID?
        let platformIndex: Int
        var spawnedMask: UInt32
        var spawnMask: UInt32
        var marioOnPlatform: Bool
        var onGround: Bool
        var distanceToMario: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64DonutPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .spawner, behaviorIdentity: Self.spawnerBehaviorIdentity)
        guard attachSpawner(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Donut Platform spawner could not attach")
        }
        return id
    }

    @discardableResult
    private func spawnPlatform(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, index: Int, position: SM64ObjectVector3) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, model: Self.platformModel, behaviorIdentity: Self.platformBehaviorIdentity, parent: parent)
        guard attachPlatform(id, parent: parent, index: index, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Donut Platform could not attach")
        }
        return id
    }

    @discardableResult
    private func attachSpawner(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(role: .spawner, parent: nil, platformIndex: -1, spawnedMask: 0, spawnMask: 0, marioOnPlatform: false, onGround: false, distanceToMario: 10_000)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    private func attachPlatform(_ id: SM64ObjectID, parent: SM64ObjectID, index: Int, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        states[id] = State(role: .platform, parent: parent, platformIndex: index, spawnedMask: 0, spawnMask: 0, marioOnPlatform: false, onGround: false, distanceToMario: 10_000)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.collisionDataIdentity = 0x646F6E75745F636F
            record.collisionDistance = 2_000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setSpawnerSpawnMask(_ mask: UInt32, for id: SM64ObjectID) -> Bool {
        guard var state = states[id], state.role == .spawner else { return false }
        state.spawnMask = mask
        states[id] = state
        return true
    }

    @discardableResult
    func setPlatformInput(distanceToMario: Float? = nil, marioOnPlatform: Bool? = nil, onGround: Bool? = nil, for id: SM64ObjectID) -> Bool {
        guard var state = states[id], state.role == .platform else { return false }
        if let distanceToMario { state.distanceToMario = distanceToMario }
        if let marioOnPlatform { state.marioOnPlatform = marioOnPlatform }
        if let onGround { state.onGround = onGround }
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64DonutPlatformBehavior.update(.init(
            role: state.role,
            timer: record.timer,
            position: record.position,
            homePosition: record.homePosition,
            gravity: record.gravity,
            distanceToMario: state.distanceToMario,
            marioOnPlatform: state.marioOnPlatform,
            onGround: state.onGround,
            spawnMask: state.spawnMask,
            spawnedMask: state.spawnedMask,
            platformIndex: state.platformIndex
        ))
        var children: [SM64ObjectID] = []
        if state.role == .spawner {
            let newBits = output.spawnedMask & ~state.spawnedMask
            for index in 0..<SM64DonutPlatformBehavior.relativePositions.count where newBits & (UInt32(1) << UInt32(index)) != 0 {
                let relative = SM64DonutPlatformBehavior.relativePositions[index]
                if let child = try? spawnPlatform(in: engineState, parent: id, index: index, position: .init(x: record.position.x + relative.x, y: record.position.y + relative.y, z: record.position.z + relative.z)) {
                    children.append(child)
                }
            }
            state.spawnedMask = output.spawnedMask
            state.spawnMask = 0
        } else {
            state.marioOnPlatform = false
            state.onGround = false
            state.distanceToMario = 10_000
            if output.clearMask != 0, let parent = state.parent {
                _ = engineState.objects.mutate(parent) { $0.behaviorParams &= ~Int32(output.clearMask) }
            }
        }
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.position = output.position
            next.gravity = output.gravity
            next.behaviorParams = Int32(output.spawnedMask)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output, spawnedPlatforms: children))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
