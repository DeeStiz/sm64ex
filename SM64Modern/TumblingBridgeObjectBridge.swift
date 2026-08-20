import Foundation

struct SM64TumblingBridgeParentEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TumblingBridgeParentOutput
    let spawnedChildren: [SM64ObjectID]
}

struct SM64TumblingBridgePlatformEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let output: SM64TumblingBridgePlatformOutput
}

final class SM64TumblingBridgeObjectBridge {
    static let wfBehaviorIdentity: UInt64 = 0x6268_765F_776674
    static let bbhBehaviorIdentity: UInt64 = 0x6268_765F_626274_70
    static let lllBehaviorIdentity: UInt64 = 0x6268_765F_6C6C74
    static let platformBehaviorIdentity: UInt64 = 0x6268_765F_747062
    static let defaultModel: UInt32 = 0

    private struct ParentState {
        let variant: SM64TumblingBridgeVariant
    }

    private struct PlatformState {
        let parentID: SM64ObjectID
        let rollStep: Int32
    }

    private var parents: [SM64ObjectID: ParentState] = [:]
    private var platforms: [SM64ObjectID: PlatformState] = [:]
    private(set) var parentEffectLog: [SM64TumblingBridgeParentEffectRecord] = []
    private(set) var platformEffectLog: [SM64TumblingBridgePlatformEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        (Set(parents.keys).union(platforms.keys)).sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        parentEffectLog.removeAll(keepingCapacity: true)
        platformEffectLog.removeAll(keepingCapacity: true)
    }

    static func behaviorIdentity(for variant: SM64TumblingBridgeVariant) -> UInt64 {
        switch variant {
        case .wf: return wfBehaviorIdentity
        case .bbh: return bbhBehaviorIdentity
        case .lll: return lllBehaviorIdentity
        }
    }

    static func variant(for behaviorIdentity: UInt64) -> SM64TumblingBridgeVariant? {
        switch behaviorIdentity {
        case wfBehaviorIdentity: return .wf
        case bbhBehaviorIdentity: return .bbh
        case lllBehaviorIdentity: return .lll
        default: return nil
        }
    }

    @discardableResult
    func spawnBridge(
        in engineState: SM64SwiftEngineState,
        variant: SM64TumblingBridgeVariant,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 2000
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .spawner,
            model: Self.defaultModel,
            behaviorIdentity: Self.behaviorIdentity(for: variant)
        )
        guard attachParent(
            id,
            variant: variant,
            position: position,
            distanceToMario: distanceToMario,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned tumbling bridge parent could not attach")
        }
        return id
    }

    @discardableResult
    func attachParent(
        _ id: SM64ObjectID,
        variant: SM64TumblingBridgeVariant,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 2000,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        parents[id] = ParentState(variant: variant)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = Int32(variant.rawValue)
            record.distanceToMario = distanceToMario
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3,
        rollStep: Int32 = 0x80
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: Self.defaultModel,
            behaviorIdentity: Self.platformBehaviorIdentity,
            parent: parent
        )
        guard attachPlatform(
            id,
            parent: parent,
            position: position,
            rollStep: rollStep,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned tumbling bridge platform could not attach")
        }
        return id
    }

    @discardableResult
    func attachPlatform(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        position: SM64ObjectVector3,
        rollStep: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else {
            return false
        }
        platforms[id] = PlatformState(parentID: parent, rollStep: rollStep)
        return pool.mutate(id) { record in
            record.parent = parent
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateParentInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TumblingBridgeParentEffectRecord? {
        guard let parentState = parents[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64TumblingBridgeBehavior.updateParent(
            SM64TumblingBridgeParentInput(
                action: record.action,
                distanceToMario: record.distanceToMario,
                variant: parentState.variant
            )
        )
        var children: [SM64ObjectID] = []
        if output.spawnChildren {
            let bridgeID = Int(parentState.variant.rawValue)
            for index in 0..<9 {
                var relative = SM64ObjectVector3(x: 0, y: 0, z: -512 + Float(index * 100))
                if bridgeID == 3 {
                    relative = SM64ObjectVector3(x: -512 + Float(index * 100), y: 0, z: 0)
                } else if bridgeID == 2 {
                    relative.y = index.isMultiple(of: 3) ? 300 : 450
                }
                let position = SM64ObjectVector3(
                    x: record.position.x + relative.x,
                    y: record.position.y + relative.y,
                    z: record.position.z + relative.z
                )
                let rollStep: Int32 = index.isMultiple(of: 2) ? 0x80 : -0x80
                if let child = try? spawnPlatform(
                    in: engineState,
                    parent: id,
                    position: position,
                    rollStep: rollStep
                ) {
                    children.append(child)
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.action == record.action ? record.timer &+ 1 : 0
            next.graphFlags = output.visible
                ? next.graphFlags & ~UInt16(0x10)
                : next.graphFlags | 0x10
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TumblingBridgeParentEffectRecord(
            objectID: id,
            output: output,
            spawnedChildren: children
        )
        parentEffectLog.append(effect)
        return effect
    }

    @discardableResult
    func updatePlatformInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TumblingBridgePlatformEffectRecord? {
        guard let platformState = platforms[id],
              let record = engineState.objects.record(for: id),
              let parent = engineState.objects.record(for: platformState.parentID) else {
            return nil
        }
        let output = SM64TumblingBridgeBehavior.updatePlatform(
            SM64TumblingBridgePlatformInput(
                action: record.action,
                timer: record.timer,
                marioOnPlatform: record.platform == id,
                angleVelocityPitch: record.angleVelocity.pitch,
                angleVelocityRoll: record.angleVelocity.roll,
                facePitch: record.faceAngles.pitch,
                faceRoll: record.faceAngles.roll,
                position: record.position,
                velocityY: record.velocity.y,
                floorHeight: record.floorHeight,
                parentAction: parent.action,
                rollStep: platformState.rollStep
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = record.timer &+ 1
            next.angleVelocity.pitch = output.angleVelocityPitch
            next.angleVelocity.roll = output.angleVelocityRoll
            next.faceAngles.pitch = output.facePitch
            next.faceAngles.roll = output.faceRoll
            next.position = output.position
            next.velocity.y = output.velocityY
            next.gravity = -3
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete {
                next.activeFlags = 0
            }
        }
        let effect = SM64TumblingBridgePlatformEffectRecord(
            objectID: id,
            parentID: platformState.parentID,
            output: output
        )
        platformEffectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        parents.removeValue(forKey: id)
        platforms.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
