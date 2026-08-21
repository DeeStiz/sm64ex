import Foundation

/// The schema-4 sink is deliberately value-only. The enclosing engine owner
/// adapts this callback to its existing status-returning trace sink; keeping
/// the bridge independent of the C module also keeps focused owner tests
/// strict-buildable.
typealias SM64DecorativePendulumSchema4TraceSink = (SM64OracleTraceRecord) -> Void

/// Source-backed behavior input for a decorative pendulum object. A behavior
/// identity alone is not a script source and is therefore never enough to
/// create script records; callers must provide the decoded native program.
struct SM64DecorativePendulumBehaviorSource: Sendable {
    let behaviorIdentity: UInt64
    let program: SM64BehaviorScriptProgram
    let startOffset: Int
    let targetResolver: SM64BehaviorTargetResolver
    let strictNativeCallbacks: Bool
    let nativeHandler: (@Sendable (UInt64, inout SM64BehaviorObjectState) -> Void)?

    init(
        behaviorIdentity: UInt64 = SM64DecorativePendulumObjectBridge.defaultBehaviorIdentity,
        program: SM64BehaviorScriptProgram,
        startOffset: Int = 0,
        targetResolver: SM64BehaviorTargetResolver = SM64BehaviorTargetResolver(),
        strictNativeCallbacks: Bool = false,
        nativeHandler: (@Sendable (UInt64, inout SM64BehaviorObjectState) -> Void)? = nil
    ) {
        self.behaviorIdentity = behaviorIdentity
        self.program = program
        self.startOffset = startOffset
        self.targetResolver = targetResolver
        self.strictNativeCallbacks = strictNativeCallbacks
        self.nativeHandler = nativeHandler
    }

    func makeVM() throws -> SM64BehaviorVM {
        try SM64BehaviorVM(
            program: program,
            startOffset: startOffset,
            targetResolver: targetResolver,
            strictNativeCallbacks: strictNativeCallbacks,
            nativeHandler: nativeHandler
        )
    }
}

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

    private enum Trace {
        static let objectDomain: UInt32 = 3
        static let scriptDomain: UInt32 = 6
        static let collisionDomain: UInt32 = 7
        static let effectDomain: UInt32 = 12
        static let stateKind: UInt32 = 1
        static let eventKind: UInt32 = 3
        static let effectKind: UInt32 = 4
        static let lifecycleEvent: UInt64 = 5
        static let behaviorCommandEvent: UInt64 = 2
        static let floorEvent: UInt64 = 1
        static let soundEffect: UInt64 = 1

        // These IDs mirror SM64_MODERN_FIELD_ACTOR_* in sm64_modern.h. They
        // are kept local to this seam so no C/ABI header is changed.
        static let actorBehavior: UInt64 = 400
        static let actorActiveFlags: UInt64 = 401
        static let actorAction: UInt64 = 402
        static let actorSubAction: UInt64 = 403
        static let actorTimer: UInt64 = 404
        static let actorPosition: UInt64 = 405
        static let actorVelocity: UInt64 = 406
        static let actorMoveAngle: UInt64 = 407
        static let actorMoveFlags: UInt64 = 408
        static let actorInteractionStatus: UInt64 = 409
        static let actorHeldState: UInt64 = 410
        static let actorFlags: UInt64 = 411
        static let actorForwardVelocity: UInt64 = 412
        static let actorGraphFlags: UInt64 = 413
    }

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var registered: Set<SM64ObjectID> = []
    private var behaviorVMs: [SM64ObjectID: SM64BehaviorVM] = [:]
    private var initializedObjects: Set<SM64ObjectID> = []
    private var collisionWorld: SM64SurfaceCollisionWorld?
    private var schema4TraceSink: SM64DecorativePendulumSchema4TraceSink?
    private var nextTraceSequence: UInt32 = 0
    private(set) var effectLog: [SM64DecorativePendulumObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []
    private(set) var schema4TraceRecords: [SM64OracleTraceRecord] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter(),
        schema4TraceSink: SM64DecorativePendulumSchema4TraceSink? = nil
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
        self.schema4TraceSink = schema4TraceSink
    }

    /// Binds the immutable collision world that was produced by the current
    /// owner-thread level/area load. No floor record is emitted until this is
    /// bound; object storage defaults are never treated as query results.
    func bindCollisionWorld(_ world: SM64SurfaceCollisionWorld?) {
        collisionWorld = world
    }

    /// Installs the enclosing engine's schema-4 adapter. The bridge appends
    /// every fixed-width record before invoking the callback, preserving a
    /// deterministic owner-thread handoff even when the sink is absent.
    func bindSchema4TraceSink(_ sink: SM64DecorativePendulumSchema4TraceSink?) {
        schema4TraceSink = sink
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

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        schema4TraceRecords.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        pool: SM64ObjectPool,
        simulationTick: UInt64 = 0,
        collisionWorld: SM64SurfaceCollisionWorld? = nil
    ) -> SM64DecorativePendulumObjectEffectRecord? {
        guard registered.contains(id) else { return nil }
        return update(
            id: id,
            pool: pool,
            simulationTick: simulationTick,
            collisionWorld: collisionWorld ?? self.collisionWorld
        )
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        behaviorVMs.removeValue(forKey: id)
        initializedObjects.remove(id)
    }

    @discardableResult
    func spawnPendulum(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0,
        model: UInt32 = SM64DecorativePendulumObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64DecorativePendulumObjectBridge.defaultBehaviorIdentity,
        behaviorSource: SM64DecorativePendulumBehaviorSource? = nil
    ) throws -> SM64ObjectID {
        let spawnIdentity = behaviorSource?.behaviorIdentity ?? behaviorIdentity
        let id = try engineState.spawnObject(
            in: .default,
            model: model,
            behaviorIdentity: spawnIdentity
        )
        guard attach(
            id,
            position: position,
            faceRoll: faceRoll,
            behaviorSource: behaviorSource,
            in: engineState.objects
        ) else {
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
        behaviorSource: SM64DecorativePendulumBehaviorSource? = nil,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard let record = pool.record(for: id) else { return false }
        let behaviorVM: SM64BehaviorVM?
        if let behaviorSource {
            guard record.behaviorIdentity == behaviorSource.behaviorIdentity,
                  let vm = try? behaviorSource.makeVM() else { return false }
            behaviorVM = vm
        } else {
            behaviorVM = nil
        }
        registered.insert(id)
        initializedObjects.remove(id)
        if let behaviorVM {
            behaviorVMs[id] = behaviorVM
        } else {
            behaviorVMs.removeValue(forKey: id)
        }
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
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(
                id,
                pool: pool,
                simulationTick: engineState.globals.frame,
                collisionWorld: self?.collisionWorld
            )
        }
        for id in schedulerResult.unloaded { remove(id) }
        for id in Array(registered) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64DecorativePendulumSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    @discardableResult
    private func update(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        simulationTick: UInt64,
        collisionWorld: SM64SurfaceCollisionWorld?
    ) -> SM64DecorativePendulumObjectEffectRecord? {
        guard let record = pool.record(for: id), record.id == id else { return nil }

        let scriptTimer = record.timer
        let hadInitialization = initializedObjects.contains(id)
        emitLifecycleTrace(
            simulationTick: simulationTick,
            id: id,
            action: record.action,
            timer: scriptTimer,
            activeFlags: UInt32(record.activeFlags)
        )
        if behaviorVMs[id] != nil,
           !hadInitialization,
           let collisionWorld {
            initializeRoom(
                id: id,
                record: record,
                simulationTick: simulationTick,
                world: collisionWorld,
                pool: pool
            )
            initializedObjects.insert(id)
        }

        let output = SM64DecorativePendulumBehavior.update(
            SM64DecorativePendulumInput(
                faceRoll: record.faceAngles.roll,
                angleVelocityRoll: record.angleVelocity.roll
            )
        )
        _ = pool.mutate(id) { record in
            record.faceAngles.roll = output.faceRoll
            record.angleVelocity.roll = output.angleVelocityRoll
            if scriptTimer < 0x3FFF_FFFF {
                record.timer &+= 1
            }
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }

        let commandTraces = executeBehaviorSource(
            id: id,
            action: record.action,
            timer: scriptTimer
        )
        var nativeOrdinal = 0
        for trace in commandTraces {
            // cur_obj_play_sound_2 records its effect inside the native
            // callback, before behavior_script.c records the command event.
            // Emit the typed effect at that same fixed ordering point.
            if trace.executedOpcode == SM64BehaviorOpcode.callNative.rawValue {
                let isLoopNative = hadInitialization || nativeOrdinal > 0
                nativeOrdinal += 1
                if isLoopNative, output.playsClockSound {
                    emitSoundTrace(
                        simulationTick: simulationTick,
                        id: id,
                        value: Self.clockSoundValue,
                        pool: pool
                    )
                }
            }
            emitBehaviorCommandTrace(
                simulationTick: simulationTick,
                id: id,
                trace: trace,
                action: record.action,
                timer: scriptTimer,
                advanceLegacyDomain: true
            )
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
        emitObjectStateTrace(simulationTick: simulationTick, id: id, pool: pool)
        return effect
    }

    private func executeBehaviorSource(
        id: SM64ObjectID,
        action: Int32,
        timer: Int32
    ) -> [SM64BehaviorCommandTrace] {
        guard var vm = behaviorVMs[id] else { return [] }
        let previousCount = vm.traces.count
        do {
            try vm.executeTick()
        } catch {
            // A source program that cannot execute does not produce a
            // behavior event. The owner keeps the deterministic pendulum
            // kernel alive while the enclosing route records the failure.
            behaviorVMs[id] = vm
            return []
        }
        behaviorVMs[id] = vm
        guard vm.traces.count > previousCount else { return [] }
        return Array(vm.traces[previousCount...]).map { trace in
            // The VM trace carries control-flow values from its copied object;
            // action/timer/active flags are taken from the live pool record by
            // the caller, matching the C lifecycle owner.
            SM64BehaviorCommandTrace(
                tick: trace.tick,
                executedOffset: trace.executedOffset,
                executedOpcode: trace.executedOpcode,
                procResult: trace.procResult,
                action: action,
                timer: UInt32(bitPattern: timer),
                nextOffset: trace.nextOffset
            )
        }
    }

    private func initializeRoom(
        id: SM64ObjectID,
        record: SM64ObjectRecord,
        simulationTick: UInt64,
        world: SM64SurfaceCollisionWorld,
        pool: SM64ObjectPool
    ) {
        let first = world.findFloor(
            x: record.position.x,
            y: record.position.y,
            z: record.position.z
        )
        emitFloorTrace(
            simulationTick: simulationTick,
            x: record.position.x,
            y: record.position.y,
            z: record.position.z,
            result: first,
            world: world
        )

        guard let firstSurfaceID = first.surfaceID,
              let firstSurface = world.surface(withID: firstSurfaceID) else {
            return
        }
        if firstSurface.room != 0 {
            _ = pool.mutate(id) { $0.room = Int32(firstSurface.room) }
            return
        }

        let secondY = first.height - 100
        let second = world.findFloor(
            x: record.position.x,
            y: secondY,
            z: record.position.z
        )
        emitFloorTrace(
            simulationTick: simulationTick,
            x: record.position.x,
            y: secondY,
            z: record.position.z,
            result: second,
            world: world
        )
        if let secondSurfaceID = second.surfaceID,
           let secondSurface = world.surface(withID: secondSurfaceID) {
            _ = pool.mutate(id) { $0.room = Int32(secondSurface.room) }
        }
    }

    private func emitLifecycleTrace(
        simulationTick: UInt64,
        id: SM64ObjectID,
        action: Int32,
        timer: Int32,
        activeFlags: UInt32
    ) {
        guard behaviorVMs[id] != nil else { return }
        emitTrace(
            simulationTick: simulationTick,
            domain: Trace.scriptDomain,
            recordKind: Trace.eventKind,
            subjectID: UInt64(id.traceSubject),
            recordID: Trace.lifecycleEvent,
            values: [
                UInt64(UInt32(bitPattern: action)),
                UInt64(UInt32(bitPattern: timer)),
                UInt64(activeFlags),
            ]
        )
    }

    private func emitBehaviorCommandTrace(
        simulationTick: UInt64,
        id: SM64ObjectID,
        trace: SM64BehaviorCommandTrace,
        action: Int32,
        timer: Int32,
        advanceLegacyDomain: Bool
    ) {
        let nextOpcode: UInt64 = {
            guard let nextOffset = trace.nextOffset,
                  let vm = behaviorVMs[id],
                  let command = try? vm.program.command(at: nextOffset) else {
                return UInt64.max
            }
            // The command program is the authoritative cursor source. The
            // native schema carries the next command opcode, not its offset.
            return UInt64(command.opcode.rawValue)
        }()
        emitTrace(
            simulationTick: simulationTick,
            domain: Trace.scriptDomain,
            recordKind: Trace.eventKind,
            subjectID: UInt64(id.traceSubject),
            recordID: Trace.behaviorCommandEvent,
            values: [
                UInt64(trace.executedOpcode),
                UInt64(UInt32(bitPattern: Int32(trace.procResult.rawValue))),
                UInt64(UInt32(bitPattern: action)),
                UInt64(UInt32(bitPattern: timer)),
                nextOpcode,
                advanceLegacyDomain ? 1 : 0,
            ]
        )
    }

    private func emitFloorTrace(
        simulationTick: UInt64,
        x: Float,
        y: Float,
        z: Float,
        result: SM64SurfaceQueryResult,
        world: SM64SurfaceCollisionWorld
    ) {
        let surface = result.surfaceID.flatMap(world.surface(withID:))
        emitTrace(
            simulationTick: simulationTick,
            domain: Trace.collisionDomain,
            recordKind: Trace.eventKind,
            recordID: Trace.floorEvent,
            values: [
                UInt64(x.bitPattern),
                UInt64(y.bitPattern),
                UInt64(z.bitPattern),
                UInt64(result.height.bitPattern),
                surface.map { UInt64(bitPattern: Int64($0.type)) } ?? UInt64.max,
                surface.map { UInt64(bitPattern: Int64($0.flags)) } ?? UInt64.max,
                surface.map { UInt64($0.normal.y.bitPattern) } ?? UInt64.max,
            ]
        )
    }

    private func emitSoundTrace(
        simulationTick: UInt64,
        id: SM64ObjectID,
        value: Int32,
        pool: SM64ObjectPool
    ) {
        guard let record = pool.record(for: id), record.id == id else { return }
        emitTrace(
            simulationTick: simulationTick,
            domain: Trace.effectDomain,
            recordKind: Trace.effectKind,
            subjectID: UInt64(id.traceSubject),
            recordID: Trace.soundEffect,
            values: [
                UInt64(UInt32(bitPattern: value)),
                UInt64(record.position.x.bitPattern),
                UInt64(record.position.y.bitPattern),
                UInt64(record.position.z.bitPattern),
            ]
        )
    }

    private func emitObjectStateTrace(
        simulationTick: UInt64,
        id: SM64ObjectID,
        pool: SM64ObjectPool
    ) {
        guard let record = pool.record(for: id), record.id == id else { return }
        let subjectID = UInt64(id.traceSubject)
        let records: [(UInt64, [UInt64])] = [
            (Trace.actorBehavior, [record.behaviorIdentity]),
            (Trace.actorActiveFlags, [UInt64(record.activeFlags)]),
            (Trace.actorAction, [UInt64(UInt32(bitPattern: record.action))]),
            (Trace.actorSubAction, [UInt64(UInt32(bitPattern: record.subAction))]),
            (Trace.actorTimer, [UInt64(UInt32(bitPattern: record.timer))]),
            (Trace.actorPosition, [
                UInt64(record.position.x.bitPattern),
                UInt64(record.position.y.bitPattern),
                UInt64(record.position.z.bitPattern),
            ]),
            (Trace.actorVelocity, [
                UInt64(record.velocity.x.bitPattern),
                UInt64(record.velocity.y.bitPattern),
                UInt64(record.velocity.z.bitPattern),
            ]),
            (Trace.actorMoveAngle, [
                UInt64(UInt32(bitPattern: record.moveAngles.pitch)),
                UInt64(UInt32(bitPattern: record.moveAngles.yaw)),
                UInt64(UInt32(bitPattern: record.moveAngles.roll)),
            ]),
            (Trace.actorMoveFlags, [UInt64(record.moveFlags)]),
            (Trace.actorInteractionStatus, [UInt64(UInt32(bitPattern: record.interactionStatus))]),
            (Trace.actorHeldState, [UInt64(record.heldState)]),
            (Trace.actorFlags, [UInt64(record.objectFlags)]),
            (Trace.actorForwardVelocity, [UInt64(record.forwardVelocity.bitPattern)]),
            (Trace.actorGraphFlags, [UInt64(record.graphFlags)]),
        ]
        for (recordID, values) in records {
            emitTrace(
                simulationTick: simulationTick,
                domain: Trace.objectDomain,
                recordKind: Trace.stateKind,
                subjectID: subjectID,
                recordID: recordID,
                values: values
            )
        }
    }

    private func emitTrace(
        simulationTick: UInt64,
        domain: UInt32,
        recordKind: UInt32,
        subjectID: UInt64 = 0,
        recordID: UInt64,
        values: [UInt64]
    ) {
        guard schema4TraceSink != nil else { return }
        guard let record = try? SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: domain,
            recordKind: recordKind,
            subjectID: subjectID,
            recordID: recordID,
            sequence: nextTraceSequence,
            values: values
        ) else { return }
        nextTraceSequence &+= 1
        schema4TraceRecords.append(record)
        schema4TraceSink?(record)
    }
}
