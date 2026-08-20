import Foundation

struct SM64ThwompObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ThwompOutput
}

final class SM64ThwompObjectBridge {
    static let grindelBehaviorIdentity: UInt64 = 0x6268_765F_67726E
    static let thwomp2BehaviorIdentity: UInt64 = 0x6268_765F_747732
    static let thwompBehaviorIdentity: UInt64 = 0x6268_765F_746877
    static let grindelCollisionIdentity: UInt64 = 0x73736C5F67726E64
    static let thwomp2CollisionIdentity: UInt64 = 0x7477685F636F6C32
    static let thwompCollisionIdentity: UInt64 = 0x7477685F636F6C31

    private struct State: Equatable {
        let variant: SM64ThwompVariant
        let randomWaitTimer: Float
        let randomPauseTimer: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ThwompObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        variant: SM64ThwompVariant = .thwomp,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: Int32 = 0,
        distanceToMario: Float = 10_000,
        randomWaitTimer: Float = 20,
        randomPauseTimer: Float = 20
    ) throws -> SM64ObjectID {
        let identity: UInt64
        switch variant {
        case .grindel: identity = Self.grindelBehaviorIdentity
        case .thwomp2: identity = Self.thwomp2BehaviorIdentity
        case .thwomp: identity = Self.thwompBehaviorIdentity
        }
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: identity)
        guard attach(id, variant: variant, position: position, behaviorByte: behaviorByte, distanceToMario: distanceToMario, randomWaitTimer: randomWaitTimer, randomPauseTimer: randomPauseTimer, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Thwomp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        variant: SM64ThwompVariant,
        position: SM64ObjectVector3,
        behaviorByte: Int32,
        distanceToMario: Float,
        randomWaitTimer: Float,
        randomPauseTimer: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(variant: variant, randomWaitTimer: randomWaitTimer, randomPauseTimer: randomPauseTimer)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = behaviorByte
            record.distanceToMario = distanceToMario
            record.action = Int32(SM64ThwompAction.wait.rawValue)
            record.timer = 0
            record.collisionDistance = 1000
            if variant != .grindel {
                record.scale = .init(x: 1.4, y: 1.4, z: 1.4)
                record.drawingDistance = 4000
            }
            record.collisionDataIdentity = Self.collisionIdentity(for: variant)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let action = SM64ThwompAction(rawValue: UInt8(clamping: record.action)) ?? .wait
        let output = SM64ThwompBehavior.update(
            .init(
                variant: state.variant,
                action: action,
                timer: record.timer,
                behaviorByte: record.behaviorParams2ndByte,
                positionY: record.position.y,
                homeY: record.homePosition.y,
                velocityY: record.velocity.y,
                distanceToMario: record.distanceToMario,
                randomWaitTimer: state.randomWaitTimer,
                randomPauseTimer: state.randomPauseTimer
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.action = Int32(output.action.rawValue)
            next.timer = output.timer
            next.collisionDataIdentity = Self.collisionIdentity(for: state.variant)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        _ = engineState.bindPlatformCollisionOwner(id, surfaceIDs: [UInt32(state.variant.rawValue) + 0x300])
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }

    private static func collisionIdentity(for variant: SM64ThwompVariant) -> UInt64 {
        switch variant {
        case .grindel: return grindelCollisionIdentity
        case .thwomp2: return thwomp2CollisionIdentity
        case .thwomp: return thwompCollisionIdentity
        }
    }
}
