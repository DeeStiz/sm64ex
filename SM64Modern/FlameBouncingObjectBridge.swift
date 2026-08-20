import Foundation

struct SM64FlameBouncingObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64FlameBouncingOutput
}

final class SM64FlameBouncingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_66626F
    private struct State {
        let moveYaw: Int32
        let gravity: Float
        let initialScale: Float
        let distanceToBowser: Float
        let bowserExists: Bool
        let bowserHeldState: Int32
        let floorHazard: Bool
        var velocityY: Float
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FlameBouncingObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        gravity: Float = -1,
        initialScale: Float = 1,
        distanceToBowser: Float = .greatestFiniteMagnitude,
        bowserExists: Bool = false,
        bowserHeldState: Int32 = 0,
        floorHazard: Bool = false
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, gravity: gravity, initialScale: initialScale, distanceToBowser: distanceToBowser, bowserExists: bowserExists, bowserHeldState: bowserHeldState, floorHazard: floorHazard, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned bouncing flame could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, gravity: Float, initialScale: Float, distanceToBowser: Float, bowserExists: Bool, bowserHeldState: Int32, floorHazard: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, gravity: gravity, initialScale: initialScale, distanceToBowser: distanceToBowser, bowserExists: bowserExists, bowserHeldState: bowserHeldState, floorHazard: floorHazard, velocityY: 30)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = 20; record.velocity.y = 30; record.gravity = gravity; record.scale = .init(x: initialScale, y: initialScale, z: initialScale); record.interactionType = 1; record.hitboxRadius = 50; record.hitboxHeight = 25; record.hitboxDownOffset = 25; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FlameBouncingObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FlameBouncingBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, forwardVelocity: record.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, timer: record.timer, animationState: record.animationState, initialScale: state.initialScale, distanceToBowser: state.distanceToBowser, bowserExists: state.bowserExists, bowserHeldState: state.bowserHeldState, floorHazard: state.floorHazard))
        state.velocityY = output.velocityY; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.forwardVelocity = output.forwardVelocity; next.velocity.y = output.velocityY; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.animationState = output.animationState; next.interactionStatus = output.interactionStatus; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64FlameBouncingObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
