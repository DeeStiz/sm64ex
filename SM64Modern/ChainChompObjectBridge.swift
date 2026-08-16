import Foundation

enum SM64ChainChompObjectKind: UInt8, Equatable, Sendable {
    case chomp = 0
    case segment = 1
}

struct SM64ChainChompObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64ChainChompObjectKind
    let index: UInt8
    let effects: SM64ChainChompEffect
    let action: SM64ChainChompAction?
    let markedForDeletion: Bool
}

struct SM64ChainChompSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64ChainChompObjectEffectRecord]
}

/// Owner-thread bridge for Chain Chomp and its pivot/four metallic-ball chain.
/// C's segment array is copied into a value state; child objects carry only
/// stable IDs and parent-relative transforms.
final class SM64ChainChompObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_63686D70
    static let segmentBehaviorIdentity: UInt64 = 0x6268_765F_63687367
    static let chompModel: UInt32 = 0x66 // MODEL_CHAIN_CHOMP
    static let segmentModel: UInt32 = 0x65 // MODEL_METALLIC_BALL

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64ChainChompState] = [:]
    private var inputs: [SM64ObjectID: SM64ChainChompTickInput] = [:]
    private var segmentIndex: [SM64ObjectID: UInt8] = [:]
    private var segmentsForParent: [SM64ObjectID: [SM64ObjectID]] = [:]
    private(set) var effectLog: [SM64ChainChompObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(states.keys) + Array(segmentIndex.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64ChainChompState? { states[id] }

    @discardableResult
    func spawnChainChomp(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64ChainChompObjectBridge.chompModel,
        behaviorIdentity: UInt64 = SM64ChainChompObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, model: model, behaviorIdentity: behaviorIdentity)
        guard attach(id, homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Chain Chomp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64ChainChompState(homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw)
        states[id] = state
        inputs[id] = SM64ChainChompTickInput()
        synchronizeChomp(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64ChainChompTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    /// Clears per-tick effects before a shared scheduler pass.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    /// Advances one Chain Chomp parent or segment without nesting a scheduler
    /// traversal. The enclosing dispatcher remains list-order authority.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil,
              states[id] != nil || segmentIndex[id] != nil else { return false }
        update(id: id, pool: pool)
        return true
    }

    /// Removes a parent/segment shadow after scheduler unload or reset.
    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
        segmentIndex.removeValue(forKey: id)
        segmentsForParent.removeValue(forKey: id)
        for parent in Array(segmentsForParent.keys) {
            segmentsForParent[parent]?.removeAll { $0 == id }
        }
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil {
            remove(id)
        }
        for parent in Array(segmentsForParent.keys) {
            segmentsForParent[parent]?.removeAll { pool.record(for: $0) == nil }
        }
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64ChainChompTickInput] = [:]
    ) -> SM64ChainChompSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64ChainChompSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var chomp = states[id], pool.record(for: id) != nil {
            let previousAction = chomp.action
            let input = inputs[id] ?? defaultInput(for: id, pool: pool)
            let result = SM64ChainChompKernel.tick(input, state: &chomp)
            states[id] = chomp
            synchronizeChomp(id: id, state: chomp, pool: pool, previousAction: previousAction)
            var created: [SM64ObjectID] = []
            if result.effects.contains(.allocateChain), segmentsForParent[id] == nil {
                created = allocateSegments(parent: id, state: chomp, pool: pool)
            }
            if chomp.action == .unloadChain {
                for child in segmentsForParent[id] ?? [] {
                    effectRouter.enqueue(objectID: child, kind: .markForDeletion)
                }
            }
            if chomp.markedForDeletion {
                effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            }
            if chomp.action == .unloadChain || chomp.markedForDeletion {
                deliveryLog.append(effectRouter.deliver(to: pool))
            }
            effectLog.append(
                SM64ChainChompObjectEffectRecord(
                    objectID: id,
                    kind: .chomp,
                    index: 255,
                    effects: result.effects,
                    action: chomp.action,
                    markedForDeletion: chomp.markedForDeletion
                )
            )
            _ = created
            return
        }

        guard let index = segmentIndex[id], let record = pool.record(for: id), let parent = record.parent as SM64ObjectID?, let state = states[parent] else { return }
        if state.action == .unloadChain {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
            effectLog.append(SM64ChainChompObjectEffectRecord(objectID: id, kind: .segment, index: index, effects: [.unload, .markForDeletion], action: nil, markedForDeletion: true))
            return
        }
        synchronizeSegment(id: id, parent: state, index: index, pool: pool)
        effectLog.append(SM64ChainChompObjectEffectRecord(objectID: id, kind: .segment, index: index, effects: [.animate], action: nil, markedForDeletion: false))
    }

    private func allocateSegments(parent: SM64ObjectID, state: SM64ChainChompState, pool: SM64ObjectPool) -> [SM64ObjectID] {
        var ids: [SM64ObjectID] = []
        for index in 0..<5 {
            guard let id = try? pool.spawn(in: .generalActor, model: Self.segmentModel, behaviorIdentity: Self.segmentBehaviorIdentity, parent: parent) else { continue }
            let part = UInt8(index)
            segmentIndex[id] = part
            ids.append(id)
            synchronizeSegment(id: id, parent: state, index: part, pool: pool)
        }
        segmentsForParent[parent] = ids
        return ids
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64ChainChompTickInput {
        guard let record = pool.record(for: id) else { return SM64ChainChompTickInput() }
        return SM64ChainChompTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            onGround: record.moveFlags & 1 != 0,
            animationAtFrame: record.animationState == 1,
            attacked: record.interactionStatus != 0,
            hitWall: record.moveFlags & (1 << 0) != 0,
            globalTimer: UInt32(truncatingIfNeeded: record.timer)
        )
    }

    private func synchronizeChomp(id: SM64ObjectID, state: SM64ChainChompState, pool: SM64ObjectPool, previousAction: SM64ChainChompAction) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.gravity = state.gravity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.pitch = Int32(state.facePitch)
            record.action = Int32(state.action.rawValue)
            record.subAction = Int32(state.subAction.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.graphYOffset = 240
            record.graphFlags = state.hidden ? record.graphFlags | 0x10 : record.graphFlags & ~UInt16(0x10)
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.friction = 1_000
            record.buoyancy = 200
        }
    }

    private func synchronizeSegment(id: SM64ObjectID, parent: SM64ChainChompState, index: UInt8, pool: SM64ObjectPool) {
        let segment = parent.segments[Int(index)]
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: parent.pivotX + segment.x, y: parent.pivotY + segment.y, z: parent.pivotZ + segment.z)
            record.scale = .init(x: 2, y: 2, z: 2)
            record.graphYOffset = 40
            record.subAction = Int32(index)
            record.gravity = -4
            record.friction = 1_000
            record.buoyancy = 200
        }
    }
}
