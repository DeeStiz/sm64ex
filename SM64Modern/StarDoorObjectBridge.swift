import Foundation

struct SM64StarDoorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64StarDoorOutput
    let neighborID: SM64ObjectID?
}

final class SM64StarDoorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737464
    static let interactionType: UInt32 = 1 << 2 // INTERACT_DOOR
    static let interactionSubtype: UInt32 = 1 << 11 // INT_SUBTYPE_STAR_DOOR

    private struct State {
        let moveYaw: Int32
        var interactionActivated: Bool
        var roomVisible: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64StarDoorObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnDoor(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        roomVisible: Bool = true
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity, drawingDistance: 20_000)
        guard attach(id, position: position, moveYaw: moveYaw, roomVisible: roomVisible, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned star door could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        roomVisible: Bool,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, interactionActivated: false, roomVisible: roomVisible)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.action = SM64StarDoorAction.closed.rawValue
            record.interactionType = Self.interactionType
            record.interactionSubtype = Self.interactionSubtype
            record.hitboxRadius = 80
            record.hitboxHeight = 100
            record.intangibleTimer = -1
            record.collisionDistance = 20_000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInteraction(_ activated: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.interactionActivated = activated
        states[id] = state
        return true
    }

    @discardableResult
    func setRoomVisible(_ visible: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.roomVisible = visible
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let neighbor = nearestDoor(excluding: id, to: record.position, in: engineState.objects)
        let neighborAction = neighbor.flatMap { engineState.objects.record(for: $0)?.action }.flatMap(SM64StarDoorAction.init(rawValue:))
        let output = SM64StarDoorBehavior.update(.init(
            action: SM64StarDoorAction(rawValue: record.action) ?? .closed,
            timer: record.timer,
            position: record.position,
            moveYaw: state.moveYaw,
            interactionActivated: state.interactionActivated,
            neighborAction: neighborAction,
            roomVisible: state.roomVisible
        ))
        state.interactionActivated = false
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action.rawValue
            next.timer = output.timer
            next.position = output.position
            next.velocity.x = output.velocityX
            next.velocity.z = output.velocityZ
            next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10
            next.intangibleTimer = output.tangible ? -1 : 1
            next.interactionStatus = output.clearInteraction ? 0 : next.interactionStatus
            next.collisionDistance = 20_000
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, neighborID: neighbor))
        return true
    }

    private func nearestDoor(excluding id: SM64ObjectID, to position: SM64ObjectVector3, in pool: SM64ObjectPool) -> SM64ObjectID? {
        var candidates: [(distance: Float, id: SM64ObjectID)] = []
        for candidate in states.keys where candidate != id {
            guard let record = pool.record(for: candidate) else { continue }
            let dx = record.position.x - position.x
            let dy = record.position.y - position.y
            let dz = record.position.z - position.z
            candidates.append((dx * dx + dy * dy + dz * dz, candidate))
        }
        return candidates.min { lhs, rhs in
            lhs.0 == rhs.0
                ? (lhs.1.slot == rhs.1.slot ? lhs.1.generation < rhs.1.generation : lhs.1.slot < rhs.1.slot)
                : lhs.0 < rhs.0
        }?.1
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
