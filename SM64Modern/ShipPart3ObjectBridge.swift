import Foundation

struct SM64ShipPart3ObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ShipPart3Output
}

final class SM64ShipPart3ObjectBridge {
    static let decorativeBehaviorIdentity: UInt64 = 0x6268_765F_737033
    static let collisionBehaviorIdentity: UInt64 = 0x6268_765F_697333
    static let collisionDataIdentity: UInt64 = 0x6A72625F737033
    static let collisionSurfaceIdentity: UInt32 = 0x303

    private var roles: [SM64ObjectID: SM64ShipPart3Role] = [:]
    private(set) var effectLog: [SM64ShipPart3ObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        roles.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        role: SM64ShipPart3Role = .decorative,
        position: SM64ObjectVector3 = .zero,
        yaw: Int32 = 0,
        rollPhase: Int32 = 0
    ) throws -> SM64ObjectID {
        let identity = role == .collision ? Self.collisionBehaviorIdentity : Self.decorativeBehaviorIdentity
        let list: SM64ObjectList = role == .collision ? .surface : .default
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity)
        guard attach(id, role: role, position: position, yaw: yaw, rollPhase: rollPhase, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned ship part 3 could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        role: SM64ShipPart3Role,
        position: SM64ObjectVector3,
        yaw: Int32 = 0,
        rollPhase: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        roles[id] = role
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = yaw
            record.behaviorParams = 0
            record.behaviorParams2ndByte = rollPhase
            if role == .collision {
                record.collisionDataIdentity = Self.collisionDataIdentity
                record.collisionDistance = 4_000
                record.drawingDistance = 4_000
            }
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let role = roles[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64ShipPart3Behavior.update(
            role: role,
            homePosition: record.homePosition,
            phase: record.behaviorParams,
            rollPhase: record.behaviorParams2ndByte,
            previousAngles: record.faceAngles
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.faceAngles = output.faceAngles
            next.angleVelocity = output.angleVelocity
            next.behaviorParams = record.behaviorParams &+ 0x100
            if role == .collision {
                next.collisionDataIdentity = Self.collisionDataIdentity
                next.collisionDistance = 4_000
                _ = engineState.bindPlatformCollisionOwner(id, surfaceIDs: [Self.collisionSurfaceIdentity])
            }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { roles.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
