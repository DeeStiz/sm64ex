import Foundation

struct SM64BreakableBoxObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BreakableBoxOutput
}

final class SM64BreakableBoxObjectBridge {
    static let largeBehaviorIdentity: UInt64 = 0x6268_765F_62626F
    static let smallBehaviorIdentity: UInt64 = 0x6268_765F_626273

    private struct State {
        let kind: SM64BreakableBoxKind
        var heldState: Int32
        var attacked: Bool
        var moveFlags: UInt32
        var lavaDeath: Bool
        var released: Bool
        var framesSinceReleased: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BreakableBoxObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, kind: SM64BreakableBoxKind, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let identity = kind == .large ? Self.largeBehaviorIdentity : Self.smallBehaviorIdentity
        let list: SM64ObjectList = kind == .large ? .surface : .destructive
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity)
        guard attach(id, kind: kind, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned breakable box could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64BreakableBoxKind, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, heldState: 0, attacked: false, moveFlags: 0, lavaDeath: false, released: false, framesSinceReleased: 0)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.model = 0x82
            record.scale = kind == .small ? .init(x: 0.4, y: 0.4, z: 0.4) : .one
            record.hitboxRadius = 150; record.hitboxHeight = kind == .small ? 250 : 200
            record.collisionDistance = 500; record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInputs(for id: SM64ObjectID, heldState: Int32? = nil, attacked: Bool? = nil, moveFlags: UInt32? = nil, lavaDeath: Bool? = nil, released: Bool? = nil, framesSinceReleased: Int32? = nil) -> Bool {
        guard var state = states[id] else { return false }
        if let heldState { state.heldState = heldState }; if let attacked { state.attacked = attacked }
        if let moveFlags { state.moveFlags = moveFlags }; if let lavaDeath { state.lavaDeath = lavaDeath }
        if let released { state.released = released }; if let framesSinceReleased { state.framesSinceReleased = framesSinceReleased }
        states[id] = state; return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64BreakableBoxBehavior.update(.init(kind: state.kind, heldState: state.heldState, action: record.action, timer: record.timer, attacked: state.attacked, moveFlags: state.moveFlags, lavaDeath: state.lavaDeath, released: state.released, framesSinceReleased: state.framesSinceReleased, forwardVelocity: record.forwardVelocity))
        state.attacked = false; state.moveFlags = 0; state.lavaDeath = false; state.released = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action; next.timer = output.timer; next.model = output.model
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight
            next.forwardVelocity = output.forwardVelocity; next.velocity.y = output.velocityY
            next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10
            next.intangibleTimer = output.tangible ? 0 : -1; next.interactionStatus = 0
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
