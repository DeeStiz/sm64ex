import Foundation

struct SM64BompObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BompOutput
}

final class SM64BompObjectBridge {
    static let smallBehaviorIdentity: UInt64 = 0x6268_765F_73626D
    static let largeBehaviorIdentity: UInt64 = 0x6268_765F_6C626D
    static let smallCollisionIdentity: UInt64 = 0x77665F736D616C6C
    static let largeCollisionIdentity: UInt64 = 0x77665F6C61726765

    private var variants: [SM64ObjectID: SM64BompVariant] = [:]
    private(set) var effectLog: [SM64BompObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        variants.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        variant: SM64BompVariant = .small,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        randomTimer: Int32 = 0,
        behaviorIdentity: UInt64? = nil
    ) throws -> SM64ObjectID {
        let identity = behaviorIdentity ?? (variant == .small ? Self.smallBehaviorIdentity : Self.largeBehaviorIdentity)
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: identity)
        guard attach(id, variant: variant, position: position, moveYaw: moveYaw, randomTimer: randomTimer, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bomp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        variant: SM64BompVariant,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        randomTimer: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        variants[id] = variant
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.timer = randomTimer
            record.moveAngles.yaw = moveYaw &+ (variant == .large ? 0x4000 : 0)
            record.faceAngles.yaw = moveYaw &+ (variant == .small ? -0x4000 : 0)
            record.collisionDataIdentity = variant == .small ? Self.smallCollisionIdentity : Self.largeCollisionIdentity
            record.collisionDistance = 1000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let variant = variants[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64BompBehavior.update(
            SM64BompInput(
                variant: variant,
                action: SM64BompAction(rawValue: UInt8(clamping: record.action)) ?? .wait,
                timer: record.timer,
                position: record.position,
                forwardVelocity: record.forwardVelocity,
                moveYaw: record.moveAngles.yaw
            )
        )
        let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: output.moveYaw))
        let cosine = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: output.moveYaw))
        var nextPosition = output.position
        nextPosition.x += sine * output.forwardVelocity
        nextPosition.z += cosine * output.forwardVelocity
        _ = engineState.objects.mutate(id) { next in
            next.position = nextPosition
            next.action = Int32(output.action.rawValue)
            next.timer = output.timer
            next.forwardVelocity = output.forwardVelocity
            next.moveAngles.yaw = output.moveYaw
            next.collisionDataIdentity = variant == .small ? Self.smallCollisionIdentity : Self.largeCollisionIdentity
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: SM64BompOutput(
            variant: output.variant,
            action: output.action,
            timer: output.timer,
            position: nextPosition,
            forwardVelocity: output.forwardVelocity,
            moveYaw: output.moveYaw,
            sound: output.sound,
            clamped: output.clamped
        )))
        return true
    }

    func remove(_ id: SM64ObjectID) { variants.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
