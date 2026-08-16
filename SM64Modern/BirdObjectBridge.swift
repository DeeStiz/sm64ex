import Foundation

struct SM64BirdObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64BirdKind
    let effects: SM64BirdEffect
    let action: SM64BirdAction
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64BirdSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BirdObjectEffectRecord]
}

/// Owner-thread bridge for castle bird spawners and their six-child flight
/// groups. Parent links are stable object IDs; the copied kernel never sees a
/// C object pointer or a mutable object-list node.
final class SM64BirdObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626972
    static let defaultModel: UInt32 = 0x72 // MODEL_BIRDS

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64BirdState] = [:]
    private var inputs: [SM64ObjectID: SM64BirdTickInput] = [:]
    private(set) var effectLog: [SM64BirdObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BirdState? {
        states[id]
    }

    func contains(_ id: SM64ObjectID) -> Bool {
        states[id] != nil
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        input: SM64BirdTickInput? = nil,
        pool: SM64ObjectPool
    ) -> SM64BirdObjectEffectRecord? {
        guard states[id] != nil else { return nil }
        if let input { inputs[id] = input }
        let count = effectLog.count
        update(id: id, pool: pool)
        return effectLog.count > count ? effectLog.last : nil
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
    }

    @discardableResult
    func spawnBird(
        in engineState: SM64SwiftEngineState,
        kind: SM64BirdKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        positionX: Float? = nil,
        positionY: Float? = nil,
        positionZ: Float? = nil,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64BirdObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BirdObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attach(
            id,
            kind: kind,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bird could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64BirdKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        positionX: Float? = nil,
        positionY: Float? = nil,
        positionZ: Float? = nil,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BirdState(
            kind: kind,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ
        )
        states[id] = state
        inputs[id] = SM64BirdTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BirdTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BirdTickInput] = [:]
    ) -> SM64BirdSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64BirdSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var bird = states[id], let record = pool.record(for: id) else { return }
        let previousAction = bird.action
        let input = inputs[id] ?? defaultInput(for: id, bird: bird, record: record, pool: pool)
        let result = SM64BirdKernel.tick(input, state: &bird)
        var spawnedChildren: [SM64ObjectID] = []

        if result.effects.contains(.spawnChildren) {
            for index in 0..<6 {
                guard let child = try? pool.spawn(
                    in: .generalActor,
                    model: Self.defaultModel,
                    behaviorIdentity: Self.defaultBehaviorIdentity,
                    parent: id
                ) else { continue }
                let childState = SM64BirdState(
                    kind: .spawned,
                    homeX: bird.positionX,
                    homeY: bird.positionY,
                    homeZ: bird.positionZ,
                    positionX: bird.positionX,
                    positionY: bird.positionY,
                    positionZ: bird.positionZ,
                    moveYaw: Int16(truncatingIfNeeded: 0x1000 &+ index * 0x1800),
                    movePitch: Int16(1000 + index * 500),
                    invisible: true
                )
                states[child] = childState
                inputs[child] = SM64BirdTickInput()
                synchronizeRecord(
                    id: child,
                    state: childState,
                    pool: pool,
                    previousAction: childState.action
                )
                spawnedChildren.append(child)
            }
        }

        states[id] = bird
        synchronizeRecord(id: id, state: bird, pool: pool, previousAction: previousAction)
        if bird.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64BirdObjectEffectRecord(
                objectID: id,
                kind: bird.kind,
                effects: result.effects,
                action: bird.action,
                spawnedChildren: spawnedChildren,
                markedForDeletion: bird.markedForDeletion
            )
        )
    }

    private func defaultInput(
        for id: SM64ObjectID,
        bird: SM64BirdState,
        record: SM64ObjectRecord,
        pool: SM64ObjectPool
    ) -> SM64BirdTickInput {
        if bird.kind == .spawner {
            let dx = bird.homeX - bird.positionX
            let dz = bird.homeZ - bird.positionZ
            return SM64BirdTickInput(
                distanceToMario: record.distanceToMario,
                homeDistance: (dx * dx + dz * dz).squareRoot(),
                homeYaw: SM64CanonicalTrig.atan2s(y: dz, x: dx)
            )
        }

        guard let parent = pool.record(for: record.parent) else {
            return SM64BirdTickInput(distanceToMario: record.distanceToMario, parentAbove8000: true)
        }
        let dx = parent.position.x - record.position.x
        let dz = parent.position.z - record.position.z
        let distance = (dx * dx + dz * dz).squareRoot()
        return SM64BirdTickInput(
            distanceToMario: record.distanceToMario,
            parentDistance: distance,
            parentY: parent.position.y,
            parentYaw: SM64CanonicalTrig.atan2s(y: dz, x: dx),
            parentAbove8000: parent.position.y > 8_000
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BirdState,
        pool: SM64ObjectPool,
        previousAction: SM64BirdAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.x = state.positionX
            record.position.y = state.positionY
            record.position.z = state.positionZ
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.moveAngles.pitch = Int32(state.movePitch)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.pitch = Int32(state.movePitch)
            record.faceAngles.roll = Int32(state.faceRoll)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.graphFlags = state.invisible ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.interactionType = 0
        }
    }
}
