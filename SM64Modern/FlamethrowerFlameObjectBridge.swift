import Foundation

struct SM64FlamethrowerFlameObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64FlamethrowerFlameOutput
}

final class SM64FlamethrowerFlameObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_746666
    private struct State {
        let velocityY: Float
        let moveYaw: Int32
        let forwardVelocity: Float
        let gravity: Float
        let behaviorParam: Int32
        let parentLifetime: Int32
        let floorHeight: Float
        let initialOffset: SM64ObjectVector3
        let initialAnimationState: Int32
        var velocityYState: Float
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FlamethrowerFlameObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 20,
        velocityY: Float = 0,
        gravity: Float = 0,
        behaviorParam: Int32 = 2,
        parentLifetime: Int32 = 30,
        floorHeight: Float = 0,
        initialOffset: SM64ObjectVector3 = .zero,
        initialAnimationState: Int32 = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, behaviorParam: behaviorParam, parentLifetime: parentLifetime, floorHeight: floorHeight, initialOffset: initialOffset, initialAnimationState: initialAnimationState, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned flamethrower flame could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        forwardVelocity: Float,
        velocityY: Float,
        gravity: Float,
        behaviorParam: Int32,
        parentLifetime: Int32,
        floorHeight: Float,
        initialOffset: SM64ObjectVector3,
        initialAnimationState: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(velocityY: velocityY, moveYaw: moveYaw, forwardVelocity: forwardVelocity, gravity: gravity, behaviorParam: behaviorParam, parentLifetime: parentLifetime, floorHeight: floorHeight, initialOffset: initialOffset, initialAnimationState: initialAnimationState, velocityYState: velocityY)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.forwardVelocity = forwardVelocity
            record.velocity.y = velocityY
            record.gravity = gravity
            record.behaviorParams2ndByte = behaviorParam
            record.animationState = initialAnimationState
            record.interactionType = 1
            record.hitboxRadius = 50
            record.hitboxHeight = 25
            record.hitboxDownOffset = 25
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FlamethrowerFlameObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FlamethrowerFlameBehavior.update(.init(position: record.position, velocityY: state.velocityYState, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, gravity: state.gravity, timer: record.timer, animationState: record.animationState, behaviorParam: state.behaviorParam, parentLifetime: state.parentLifetime, floorHeight: state.floorHeight, initialOffset: state.initialOffset, initialAnimationState: state.initialAnimationState))
        state.velocityYState = output.velocityY
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.velocity.y = output.velocityY
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.animationState = output.animationState
            next.interactionStatus = output.interactionStatus
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64FlamethrowerFlameObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
