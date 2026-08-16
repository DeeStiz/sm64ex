import Foundation

struct SM64DecorativePendulumObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64DecorativePendulumOutput
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64DecorativePendulumSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64DecorativePendulumObjectEffectRecord]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhvDecorativePendulum`. The value kernel owns the
/// fixed-point swing; the bridge owns object-list membership, record mutation,
/// and the clock sound intent.
final class SM64DecorativePendulumObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_647065
    static let defaultModel: UInt32 = 0
    static let clockSoundValue: Int32 = Int32(bitPattern: 0x3017_0008)

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64DecorativePendulumObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        registered.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func contains(_ id: SM64ObjectID) -> Bool {
        registered.contains(id)
    }

    @discardableResult
    func spawnPendulum(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0,
        model: UInt32 = SM64DecorativePendulumObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64DecorativePendulumObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, faceRoll: faceRoll, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned decorative pendulum could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.roll = faceRoll
            record.angleVelocity.roll = SM64DecorativePendulumBehavior.initialize().angleVelocityRoll
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        return true
    }

    @discardableResult
    func tick(state engineState: SM64SwiftEngineState) -> SM64DecorativePendulumSchedulerTickResult {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            guard let self, self.registered.contains(id) else { return }
            self.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded where registered.remove(id) != nil {
            // The scheduler owns deactivation and unload ordering.
        }
        for id in Array(registered) where engineState.objects.record(for: id) == nil {
            registered.remove(id)
        }
        return SM64DecorativePendulumSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    @discardableResult
    private func update(id: SM64ObjectID, pool: SM64ObjectPool) -> SM64DecorativePendulumObjectEffectRecord? {
        guard let record = pool.record(for: id) else { return nil }
        let output = SM64DecorativePendulumBehavior.update(
            SM64DecorativePendulumInput(
                faceRoll: record.faceAngles.roll,
                angleVelocityRoll: record.angleVelocity.roll
            )
        )
        _ = pool.mutate(id) { record in
            record.faceAngles.roll = output.faceRoll
            record.angleVelocity.roll = output.angleVelocityRoll
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        if output.playsClockSound {
            effectRouter.enqueue(
                objectID: id,
                kind: .sound,
                value: Self.clockSoundValue
            )
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        let effect = SM64DecorativePendulumObjectEffectRecord(
            objectID: id,
            output: output,
            presentedEffects: delivery.presented
        )
        effectLog.append(effect)
        return effect
    }
}
