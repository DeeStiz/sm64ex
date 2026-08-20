import Foundation

struct SM64MrBlizzardSnowballObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64MrBlizzardSnowballOutput }

final class SM64MrBlizzardSnowballObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D6273
    private struct State: Sendable { var parentHolding: Bool; var parentThrowing: Bool; var parentYaw: Int32; var distanceToMario: Float; var onGround: Bool; var enteredWater: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64MrBlizzardSnowballObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = -0x5B58) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = 5; record.velocity.y = -1; record.gravity = -4; record.scale = .init(x: 2, y: 2, z: 2); record.hitboxRadius = 30; record.hitboxHeight = 30; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Mr Blizzard snowball could not attach") }
        states[id] = State(parentHolding: false, parentThrowing: false, parentYaw: moveYaw, distanceToMario: 10_000, onGround: false, enteredWater: false); return id
    }

    @discardableResult
    func setInput(parentHolding: Bool = false, parentThrowing: Bool = false, parentYaw: Int32 = 0, distanceToMario: Float = 10_000, onGround: Bool = false, enteredWater: Bool = false, for id: SM64ObjectID) -> Bool { guard states[id] != nil else { return false }; states[id] = State(parentHolding: parentHolding, parentThrowing: parentThrowing, parentYaw: parentYaw, distanceToMario: distanceToMario, onGround: onGround, enteredWater: enteredWater); return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64MrBlizzardSnowballBehavior.update(.init(action: record.action, timer: record.timer, position: record.position, velocityY: record.velocity.y, gravity: record.gravity, moveYaw: record.moveAngles.yaw, forwardVelocity: record.forwardVelocity, parentHolding: state.parentHolding, parentThrowing: state.parentThrowing, parentYaw: state.parentYaw, distanceToMario: state.distanceToMario, onGround: state.onGround, enteredWater: state.enteredWater))
        states[id] = State(parentHolding: false, parentThrowing: false, parentYaw: state.parentYaw, distanceToMario: 10_000, onGround: false, enteredWater: false)
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.velocity.y = output.velocityY; next.moveAngles.yaw = output.moveYaw; next.forwardVelocity = output.forwardVelocity; next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
