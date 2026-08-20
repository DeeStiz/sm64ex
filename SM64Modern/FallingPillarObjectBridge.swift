import Foundation

enum SM64FallingPillarRole: UInt8, Equatable, Sendable { case pillar = 0; case hitbox = 1 }

struct SM64FallingPillarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let role: SM64FallingPillarRole
    let output: SM64FallingPillarOutput?
    let spawnedHitboxes: [SM64ObjectID]
}

final class SM64FallingPillarObjectBridge {
    static let pillarBehaviorIdentity: UInt64 = 0x6268_765F_667063
    static let hitboxBehaviorIdentity: UInt64 = 0x6268_765F_667068
    static let collisionDataIdentity: UInt64 = 0x6A72625F6670
    static let hitboxSurfaceIdentity: UInt32 = 0x304

    private var roles: [SM64ObjectID: SM64FallingPillarRole] = [:]
    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64FallingPillarObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        roles.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPillar(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 10_000,
        angleToMario: Int32 = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.pillarBehaviorIdentity)
        guard attachPillar(id, position: position, distanceToMario: distanceToMario, angleToMario: angleToMario, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned falling pillar could not attach")
        }
        return id
    }

    @discardableResult
    func attachPillar(_ id: SM64ObjectID, position: SM64ObjectVector3, distanceToMario: Float, angleToMario: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        roles[id] = .pillar
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.distanceToMario = distanceToMario
            record.angleToMario = angleToMario
            record.collisionDataIdentity = Self.collisionDataIdentity
            record.action = Int32(SM64FallingPillarAction.idle.rawValue)
            record.gravity = 0.5
            record.friction = 0.91
            record.buoyancy = 1.3
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let role = roles[id], let record = engineState.objects.record(for: id) else { return false }
        if role == .hitbox {
            updateHitbox(id, record: record, state: engineState)
            return true
        }

        let mario = engineState.globals.marioObject.flatMap { engineState.objects.record(for: $0) }
        let output = SM64FallingPillarBehavior.update(
            action: SM64FallingPillarAction(rawValue: UInt8(clamping: record.action)) ?? .idle,
            position: record.position,
            distanceToMario: record.distanceToMario,
            angleToMario: record.angleToMario,
            marioPosition: mario?.position ?? .zero,
            marioYaw: mario?.faceAngles.yaw ?? 0,
            moveYaw: record.moveAngles.yaw,
            faceAngles: record.faceAngles,
            angleVelocity: record.angleVelocity,
            pitchAcceleration: record.velocity.y,
            timer: record.timer
        )
        var children: [SM64ObjectID] = []
        if output.spawnHitboxes {
            for index in 0..<4 {
                if let child = try? engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.hitboxBehaviorIdentity, parent: id) {
                    parents[child] = id
                    roles[child] = .hitbox
                    _ = engineState.objects.mutate(child) { next in
                        next.behaviorParams2ndByte = Int32(index)
                        next.interactionType = 1 << 1
                        next.damageOrCoinValue = 3
                        next.hitboxRadius = 150
                        next.hitboxHeight = 300
                        next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
                    }
                    children.append(child)
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = Int32(output.action.rawValue)
            next.position = output.position
            next.velocity = output.velocity
            next.faceAngles = output.faceAngles
            next.angleVelocity.pitch = output.faceAngles.pitch &- record.faceAngles.pitch
            next.velocity.y = output.pitchAcceleration
            next.timer = output.action == .turning ? record.timer &+ 1 : 0
            next.moveAngles.yaw = record.moveAngles.yaw
            if output.deactivated { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, role: .pillar, output: output, spawnedHitboxes: children))
        return true
    }

    private func updateHitbox(_ id: SM64ObjectID, record: SM64ObjectRecord, state engineState: SM64SwiftEngineState) {
        guard let parentID = parents[id], let parent = engineState.objects.record(for: parentID) else { return }
        let offset = Float(record.behaviorParams2ndByte) * 400 + 300
        let pitch = Int16(truncatingIfNeeded: parent.faceAngles.pitch)
        let yaw = Int16(truncatingIfNeeded: parent.faceAngles.yaw)
        let nextPosition = SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(pitch) * SM64CanonicalTrig.sins(yaw) * offset + parent.position.x,
            y: SM64CanonicalTrig.coss(pitch) * offset + parent.position.y,
            z: SM64CanonicalTrig.sins(pitch) * SM64CanonicalTrig.coss(yaw) * offset + parent.position.z
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = nextPosition
            next.collisionDataIdentity = Self.collisionDataIdentity
            next.interactionType = 1 << 1
            next.damageOrCoinValue = 3
            next.hitboxRadius = 150
            next.hitboxHeight = 300
            if parent.activeFlags == 0 { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, role: .hitbox, output: nil, spawnedHitboxes: []))
        _ = engineState.bindPlatformCollisionOwner(id, surfaceIDs: [Self.hitboxSurfaceIdentity])
    }

    func remove(_ id: SM64ObjectID) { roles.removeValue(forKey: id); parents.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
