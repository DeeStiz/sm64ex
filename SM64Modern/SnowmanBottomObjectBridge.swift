import Foundation

struct SM64SnowmanBottomObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SnowmanBottomOutput
    let spawnedCheckpoint: SM64ObjectID?
}

final class SM64SnowmanBottomObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_73626F

    private let checkpointBridge: SM64SnowmanCheckpointObjectBridge
    private var registered: Set<SM64ObjectID> = []
    private var parentHeads: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64SnowmanBottomObjectEffectRecord] = []

    init(checkpointBridge: SM64SnowmanCheckpointObjectBridge) {
        self.checkpointBridge = checkpointBridge
    }

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parentHead: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parentHead
        )
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.gravity = 10
            record.friction = 0.999
            record.buoyancy = 2
            record.scale = .init(x: 0.4, y: 0.4, z: 0.4)
            record.hitboxRadius = 210
            record.hitboxHeight = 350
            record.damageOrCoinValue = 3
            record.interactionType = 1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned snowman bottom could not attach")
        }
        registered.insert(id)
        if let parentHead, engineState.objects.record(for: parentHead) != nil {
            parentHeads[id] = parentHead
        }
        let checkpoint = checkpointBridge.spawn(
            in: engineState,
            parent: id,
            position: position
        )
        effectLog.append(.init(
            objectID: id,
            output: .init(
                action: 0, timer: 0, position: position, forwardVelocity: 0,
                moveYaw: 0, facePitch: 0, verticalVelocity: 0, scale: 0.4,
                gravity: 10, friction: 0.999, buoyancy: 2, tangible: true,
                deactivated: false, parentBounce: false, checkpointActive: true,
                pushMario: false
            ),
            spawnedCheckpoint: checkpoint
        ))
        effectLog.removeLast()
        return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return false
        }
        let output = SM64SnowmanBottomBehavior.update(.init(
            action: record.action,
            timer: record.timer,
            position: record.position,
            forwardVelocity: record.forwardVelocity,
            moveYaw: record.moveAngles.yaw,
            facePitch: record.faceAngles.pitch,
            scale: record.scale.x,
            pathComplete: record.behaviorParams != 0,
            nearBouncePoint: record.behaviorParams2ndByte != 0,
            movementFlags: record.moveFlags,
            dialogTriggered: record.dialogResponse == 1
        ))
        var spawnedCheckpoint: SM64ObjectID?
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.forwardVelocity = output.forwardVelocity
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.pitch = output.facePitch
            next.velocity.y = output.verticalVelocity
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.gravity = output.gravity
            next.friction = output.friction
            next.buoyancy = output.buoyancy
            next.hitboxRadius = 210
            next.hitboxHeight = 350
            next.interactionStatus = 0
            next.dialogResponse = 0
            if !output.tangible { next.intangibleTimer = 0 }
            if output.deactivated { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        if output.parentBounce, let parent = parentHeads[id] {
            _ = engineState.objects.mutate(parent) { next in
                next.action = 2
                next.velocity.y = 100
            }
        }
        effectLog.append(.init(objectID: id, output: output, spawnedCheckpoint: spawnedCheckpoint))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        parentHeads.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
