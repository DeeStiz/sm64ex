import Foundation

enum SM64MrIObjectKind: UInt8, Equatable, Sendable {
    case eye = 0
    case body = 1
    case particle = 2
}

struct SM64MrIObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64MrIObjectKind
    let action: SM64MrIAction?
    let particleAction: SM64MrIParticleAction?
    let effects: SM64MrIEffect
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64MrISchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64MrIObjectEffectRecord]
}

/// Owner-thread bridge for Mr. I, its persistent iris child, and its emitted
/// level-list particles. All parent relationships are stable IDs and all
/// temporary particles are scheduler-owned children.
final class SM64MrIObjectBridge {
    static let differentRoomFlag: UInt16 = 1 << 3
    static let eyeModel: UInt32 = 0x67 // MODEL_MR_I
    static let bodyModel: UInt32 = 0x66 // MODEL_MR_I_IRIS
    static let particleModel: UInt32 = 0xAA // MODEL_PURPLE_MARBLE
    static let blueCoinModel: UInt32 = 0x76 // MODEL_BLUE_COIN
    static let defaultEyeBehaviorIdentity: UInt64 = 0x6268_765F_6D72_69
    static let bodyBehaviorIdentity: UInt64 = 0x6268_765F_6D72_62
    static let particleBehaviorIdentity: UInt64 = 0x6268_765F_6D72_70

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var eyes: [SM64ObjectID: SM64MrIState] = [:]
    private var bodies: [SM64ObjectID: SM64MrIBodyState] = [:]
    private var particles: [SM64ObjectID: SM64MrIParticleState] = [:]
    private var eyeForBody: [SM64ObjectID: SM64ObjectID] = [:]
    private var eyeInputs: [SM64ObjectID: SM64MrITickInput] = [:]
    private var particleInputs: [SM64ObjectID: SM64MrIParticleTickInput] = [:]
    private var particleFlashEyes: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64MrIObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(eyes.keys) + Array(bodies.keys) + Array(particles.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func eyeState(for id: SM64ObjectID) -> SM64MrIState? { eyes[id] }
    func bodyState(for id: SM64ObjectID) -> SM64MrIBodyState? { bodies[id] }
    func particleState(for id: SM64ObjectID) -> SM64MrIParticleState? { particles[id] }

    @discardableResult
    func spawnMrI(
        in engineState: SM64SwiftEngineState,
        isKing: Bool = false,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64MrIObjectBridge.eyeModel,
        behaviorIdentity: UInt64 = SM64MrIObjectBridge.defaultEyeBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachMrI(
            id,
            isKing: isKing,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Mr. I could not attach")
        }
        guard let body = try? engineState.objects.spawn(
            in: .default,
            model: Self.bodyModel,
            behaviorIdentity: Self.bodyBehaviorIdentity,
            parent: id
        ) else { return id }
        bodies[body] = SM64MrIBodyState()
        eyeForBody[body] = id
        synchronizeBody(id: body, state: bodies[body]!, pool: engineState.objects)
        return id
    }

    @discardableResult
    func attachMrI(
        _ id: SM64ObjectID,
        isKing: Bool = false,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64MrIState(
            isKing: isKing,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
        eyes[id] = state
        eyeInputs[id] = SM64MrITickInput()
        synchronizeEye(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setEyeInput(_ input: SM64MrITickInput, for id: SM64ObjectID) -> Bool {
        guard eyes[id] != nil else { return false }
        eyeInputs[id] = input
        return true
    }

    @discardableResult
    func setParticleInput(_ input: SM64MrIParticleTickInput, for id: SM64ObjectID) -> Bool {
        guard particles[id] != nil else { return false }
        particleInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        eyeInputs frameEyeInputs: [SM64ObjectID: SM64MrITickInput] = [:],
        particleInputs frameParticleInputs: [SM64ObjectID: SM64MrIParticleTickInput] = [:]
    ) -> SM64MrISchedulerTickResult {
        eyeInputs = frameEyeInputs
        particleInputs = frameParticleInputs
        particleFlashEyes.removeAll(keepingCapacity: true)
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            eyes.removeValue(forKey: id)
            bodies.removeValue(forKey: id)
            particles.removeValue(forKey: id)
            eyeForBody.removeValue(forKey: id)
            eyeInputs.removeValue(forKey: id)
            particleInputs.removeValue(forKey: id)
        }
        for id in registeredIDs where engineState.objects.record(for: id) == nil {
            eyes.removeValue(forKey: id)
            bodies.removeValue(forKey: id)
            particles.removeValue(forKey: id)
            eyeForBody.removeValue(forKey: id)
            eyeInputs.removeValue(forKey: id)
            particleInputs.removeValue(forKey: id)
        }
        return SM64MrISchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var eye = eyes[id], pool.record(for: id) != nil {
            let input = eyeInputs[id] ?? defaultEyeInput(for: id, pool: pool)
            let result = SM64MrIKernel.tick(input, state: &eye)
            eyes[id] = eye
            synchronizeEye(id: id, state: eye, pool: pool)
            var children: [SM64ObjectID] = []
            if result.effects.contains(.spawnParticle),
               let particle = try? pool.spawn(
                   in: .level,
                   model: Self.particleModel,
                   behaviorIdentity: Self.particleBehaviorIdentity,
                   parent: id
               ) {
                let child = SM64MrIParticleState(
                    positionX: eye.positionX + SM64CanonicalTrig.sins(eye.moveYaw) * 90 * eye.scale,
                    positionY: eye.positionY + 50 * eye.scale,
                    positionZ: eye.positionZ + SM64CanonicalTrig.coss(eye.moveYaw) * 90 * eye.scale,
                    moveYaw: eye.moveYaw
                )
                particles[particle] = child
                particleInputs[particle] = SM64MrIParticleTickInput()
                synchronizeParticle(id: particle, state: child, pool: pool)
                children.append(particle)
            }
            if result.effects.contains(.particleFlash) { particleFlashEyes.insert(id) }
            if result.effects.contains(.blueCoin),
               let coin = try? pool.spawn(
                   in: .level,
                   model: Self.blueCoinModel,
                   behaviorIdentity: 0x6268_765F_6D72_63,
                   parent: id
               ) {
                effectRouter.enqueue(objectID: coin, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
                children.append(coin)
            }
            if result.effects.contains(.star),
               let star = try? pool.spawn(
                   in: .level,
                   model: 0x74,
                   behaviorIdentity: 0x6268_765F_7374_72,
                   parent: id
               ) {
                effectRouter.enqueue(objectID: star, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
                children.append(star)
            }
            if eye.markedForDeletion {
                effectRouter.enqueue(objectID: id, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
            }
            effectLog.append(
                SM64MrIObjectEffectRecord(
                    objectID: id,
                    kind: .eye,
                    action: eye.action,
                    particleAction: nil,
                    effects: result.effects,
                    spawnedChildren: children,
                    markedForDeletion: eye.markedForDeletion
                )
            )
            return
        }

        if var body = bodies[id], pool.record(for: id) != nil {
            guard let eyeID = eyeForBody[id], let eye = eyes[eyeID] else {
                body.markedForDeletion = true
                bodies[id] = body
                effectRouter.enqueue(objectID: id, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
                return
            }
            let result = SM64MrIKernel.tickBody(
                SM64MrIBodyTickInput(
                    parentPositionX: eye.positionX,
                    parentPositionY: eye.positionY,
                    parentPositionZ: eye.positionZ,
                    parentScale: eye.scale,
                    parentParticleFlash: particleFlashEyes.contains(eyeID),
                    parentDeleted: eye.markedForDeletion
                ),
                state: &body
            )
            bodies[id] = body
            synchronizeBody(id: id, state: body, pool: pool)
            if body.markedForDeletion {
                effectRouter.enqueue(objectID: id, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
            }
            effectLog.append(
                SM64MrIObjectEffectRecord(
                    objectID: id,
                    kind: .body,
                    action: nil,
                    particleAction: nil,
                    effects: result.effects,
                    spawnedChildren: [],
                    markedForDeletion: body.markedForDeletion
                )
            )
            return
        }

        guard var particle = particles[id], let record = pool.record(for: id) else { return }
        let input = particleInputs[id] ?? defaultParticleInput(for: record)
        let result = SM64MrIKernel.tickParticle(input, state: &particle)
        var children: [SM64ObjectID] = []
        if result.effects.contains(.particleBurst) {
            for _ in 0..<10 {
                if let child = try? pool.spawn(
                    in: .unimportant,
                    model: Self.particleModel,
                    behaviorIdentity: 0x6268_765F_707572,
                    parent: id
                ) {
                    effectRouter.enqueue(objectID: child, kind: .markForDeletion)
                    deliveryLog.append(effectRouter.deliver(to: pool))
                    children.append(child)
                }
            }
        }
        particles[id] = particle
        synchronizeParticle(id: id, state: particle, pool: pool)
        if particle.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64MrIObjectEffectRecord(
                objectID: id,
                kind: .particle,
                action: nil,
                particleAction: particle.action,
                effects: result.effects,
                spawnedChildren: children,
                markedForDeletion: particle.markedForDeletion
            )
        )
    }

    private func defaultEyeInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64MrITickInput {
        guard let record = pool.record(for: id) else { return SM64MrITickInput() }
        return SM64MrITickInput(
            activeInRoom: record.activeFlags & Self.differentRoomFlag == 0,
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            randomValue: UInt32(truncatingIfNeeded: record.timer),
            attacked: record.interactionStatus != 0,
            moveFlags: record.moveFlags
        )
    }

    private func defaultParticleInput(for record: SM64ObjectRecord) -> SM64MrIParticleTickInput {
        SM64MrIParticleTickInput(
            activeInRoom: record.activeFlags & Self.differentRoomFlag == 0,
            moveFlags: record.moveFlags,
            interacted: record.interactionStatus & Int32(1 << 15) != 0
        )
    }

    private func synchronizeEye(id: SM64ObjectID, state: SM64MrIState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.moveAngles.pitch = Int32(state.movePitch)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.pitch = Int32(state.movePitch)
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
        }
    }

    private func synchronizeBody(id: SM64ObjectID, state: SM64MrIBodyState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagTransformRelativeToParent |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.parentRelativePosition = SM64ObjectVector3(x: 0, y: 0, z: state.relativeZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.animationState = state.animationState
            record.graphYOffset = state.relativeZ
            record.interactionType = 0
        }
    }

    private func synchronizeParticle(id: SM64ObjectID, state: SM64MrIParticleState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 1 << 3
            record.hitboxRadius = 50
            record.hitboxHeight = 50
            record.gravity = -4
        }
    }
}
