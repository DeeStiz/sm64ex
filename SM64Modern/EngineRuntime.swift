import Foundation
import os

private let runtimeLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "EngineRuntime"
)

struct SM64ModernEngineRuntimeCallbacks {
    let initialize: () -> SM64ModernStatus
    let step: () -> SM64ModernStatus
    let requestStop: (SM64ModernExitReason) -> SM64ModernStatus
    let shutdown: () -> SM64ModernStatus
}

struct SM64ModernSwiftEngineTickReceipt: Equatable, Sendable {
    let tick: UInt64
    let frame: UInt64
    let objectCount: UInt32
    let resetEpoch: UInt64
}

enum SM64ModernSwiftEngineDomain: String, CaseIterable, Equatable, Hashable, Sendable {
    case state
    case objectScheduler
    case progression
    case savePersistence
    case input
    case marioInput
    case marioAction
    case camera
    case audio
    case rendering
    case frontend
}

struct SM64ModernSwiftEngineDomainReadiness: Equatable, Sendable {
    let swiftOwned: Set<SM64ModernSwiftEngineDomain>

    static let context = Self(swiftOwned: [
        .state, .objectScheduler, .progression, .input, .marioInput, .marioAction
    ])

    func isSwiftOwned(_ domain: SM64ModernSwiftEngineDomain) -> Bool {
        swiftOwned.contains(domain)
    }

    var cFallbackRequired: Set<SM64ModernSwiftEngineDomain> {
        Set(SM64ModernSwiftEngineDomain.allCases).subtracting(swiftOwned)
    }
}

struct SM64ModernSwiftProgressionReceipt: Equatable, Sendable {
    let engineTick: UInt64
    let simulationTick: UInt64
    let eventID: SM64ProgressionRuntimeEventID
    let accepted: Bool
    let actorEffects: SM64ProgressionActorEffect
    let progressionEffects: SM64ProgressionEffect
    let persistenceNeeded: Bool
    let values: [UInt64]
}

struct SM64ModernSwiftInputReceipt: Equatable, Sendable {
    let engineTick: UInt64
    let advanceLegacyDomain: Bool
    let controller: SM64ControllerState
}

struct SM64ModernSwiftMarioInputReceipt: Equatable, Sendable {
    let engineTick: UInt64
    let controller: SM64ControllerState
    let mario: SM64MarioInputState
}

struct SM64ModernSwiftMarioActionReceipt: Equatable, Sendable {
    let engineTick: UInt64
    let decision: SM64MarioActionDecision
    let mutation: SM64MarioActionMutation?
}

typealias SM64ModernSwiftTraceSink = (SM64OracleTraceRecord) -> SM64ModernStatus

/// Owner-thread Swift state used by the Swift runtime while product domains
/// are migrated. It is deliberately a real engine context, not a callback
/// counter: object lists, globals, transforms, arenas, and unload ordering
/// advance through the same Swift state/scheduler contracts used by the
/// migrated actor bridges.
final class SM64ModernSwiftEngineContext {
    let state: SM64SwiftEngineState
    private let scheduler: SM64ObjectScheduler
    private let initialProgression: SM64ProgressionRuntime
    private let traceSink: SM64ModernSwiftTraceSink?
    private var inputNormalizer = SM64ControllerInputNormalizer()
    private var framesSinceA: UInt8 = 0
    private var framesSinceB: UInt8 = 0
    private(set) var marioState = SM64MarioState()
    private(set) var progression: SM64ProgressionRuntime
    let domainReadiness = SM64ModernSwiftEngineDomainReadiness.context
    private(set) var phase: SM64ModernSwiftRuntimePhase = .cold
    private(set) var tickCount: UInt64 = 0
    private(set) var lastReceipt: SM64ModernSwiftEngineTickReceipt?
    private(set) var lastProgressionReceipt: SM64ModernSwiftProgressionReceipt?
    private(set) var lastInputReceipt: SM64ModernSwiftInputReceipt?
    private(set) var lastMarioInputReceipt: SM64ModernSwiftMarioInputReceipt?
    private(set) var lastMarioActionReceipt: SM64ModernSwiftMarioActionReceipt?
    private(set) var traceRecords: [SM64OracleTraceRecord] = []
    private(set) var lastTraceRecord: SM64OracleTraceRecord?
    private(set) var traceStatus: SM64ModernStatus = 0
    private var traceSequence: UInt32 = 0

    init(
        objectCapacity: Int = SM64ObjectPool.defaultCapacity,
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        progression: SM64ProgressionRuntime = SM64ProgressionRuntime(),
        traceSink: SM64ModernSwiftTraceSink? = nil
    ) {
        self.state = SM64SwiftEngineState(objectCapacity: objectCapacity)
        self.scheduler = scheduler
        self.initialProgression = progression
        self.progression = progression
        self.traceSink = traceSink
    }

    func initialize(levelNumber: Int16 = 1, areaIndex: Int16 = 0) -> Bool {
        guard phase == .cold else { return false }
        state.beginLevel(levelNumber: levelNumber, areaIndex: areaIndex)
        progression = initialProgression
        inputNormalizer = SM64ControllerInputNormalizer()
        framesSinceA = 0
        framesSinceB = 0
        marioState = SM64MarioState()
        tickCount = 0
        lastReceipt = nil
        lastProgressionReceipt = nil
        lastInputReceipt = nil
        lastMarioInputReceipt = nil
        lastMarioActionReceipt = nil
        traceRecords.removeAll(keepingCapacity: true)
        lastTraceRecord = nil
        traceStatus = 0
        traceSequence = 0
        phase = .initialized
        return true
    }

    func applyProgression(
        _ event: SM64ProgressionActorEvent,
        simulationTick: UInt64? = nil
    ) -> SM64ModernSwiftProgressionReceipt? {
        guard phase == .initialized,
              let result = progression.apply(
                event, simulationTick: simulationTick ?? tickCount
              ) else {
            return nil
        }
        let receipt = SM64ModernSwiftProgressionReceipt(
            engineTick: tickCount,
            simulationTick: result.trace.simulationTick,
            eventID: result.trace.eventID,
            accepted: result.trace.accepted,
            actorEffects: result.actorEffects,
            progressionEffects: result.progressionEffects,
            persistenceNeeded: result.persistenceNeeded,
            values: result.trace.values
        )
        lastProgressionReceipt = receipt
        guard emitTrace(
            simulationTick: receipt.simulationTick,
            domain: 10,
            recordKind: 3,
            subjectID: UInt64(progression.saveFileIndex),
            recordID: 0x1700_0000 | UInt64(receipt.eventID.rawValue),
            flags: UInt32(receipt.actorEffects.rawValue)
                | (UInt32(receipt.progressionEffects.rawValue) << 16),
            values: [
                UInt64(receipt.eventID.rawValue),
                receipt.accepted ? 1 : 0,
                receipt.persistenceNeeded ? 1 : 0
            ] + Array(receipt.values.prefix(5))
        ) == 0 else { return nil }
        return receipt
    }

    func ingestInput(
        _ sample: SM64ControllerRawSample,
        advanceLegacyDomain: Bool
    ) -> SM64ModernSwiftInputReceipt? {
        guard phase == .initialized else { return nil }
        let controller = inputNormalizer.update(
            sample, advanceLegacyDomain: advanceLegacyDomain
        )
        let receipt = SM64ModernSwiftInputReceipt(
            engineTick: tickCount,
            advanceLegacyDomain: advanceLegacyDomain,
            controller: controller
        )
        lastInputReceipt = receipt
        guard emitTrace(
            simulationTick: tickCount,
            domain: 1,
            recordKind: 2,
            recordID: 0x3100_0001,
            values: [
                UInt64(controller.buttonDown),
                UInt64(controller.buttonPressed),
                UInt64(controller.stickX.bitPattern),
                UInt64(controller.stickY.bitPattern),
                UInt64(UInt16(bitPattern: controller.rawStickX)),
                UInt64(UInt16(bitPattern: controller.rawStickY)),
                UInt64(UInt16(bitPattern: controller.extStickX)),
                UInt64(UInt16(bitPattern: controller.extStickY))
            ]
        ) == 0 else { return nil }
        return receipt
    }

    func updateMarioInput(
        squishTimer: Int32,
        faceYaw: Int16,
        cameraYaw: Int16,
        firstPerson: Bool = false,
        interactionUnknown10: Bool = false,
        geometryFlags: SM64MarioInputFlags = []
    ) -> SM64ModernSwiftMarioInputReceipt? {
        guard phase == .initialized, let controller = lastInputReceipt?.controller else {
            return nil
        }
        let mario = SM64MarioInputCore.update(
            controller: controller,
            squishTimer: squishTimer,
            previousFramesSinceA: framesSinceA,
            previousFramesSinceB: framesSinceB,
            faceYaw: faceYaw,
            cameraYaw: cameraYaw,
            firstPerson: firstPerson,
            interactionUnknown10: interactionUnknown10,
            geometryFlags: geometryFlags
        )
        framesSinceA = mario.framesSinceA
        framesSinceB = mario.framesSinceB
        let receipt = SM64ModernSwiftMarioInputReceipt(
            engineTick: tickCount,
            controller: controller,
            mario: mario
        )
        lastMarioInputReceipt = receipt
        guard emitTrace(
            simulationTick: tickCount,
            domain: 2,
            recordKind: 2,
            recordID: 0x3200_0001,
            values: [
                UInt64(mario.input.rawValue),
                UInt64(mario.intendedMagnitude.bitPattern),
                UInt64(UInt16(bitPattern: mario.intendedYaw)),
                UInt64(mario.framesSinceA),
                UInt64(mario.framesSinceB)
            ]
        ) == 0 else { return nil }
        return receipt
    }

    func resolveIdleAction(
        context: SM64MarioActionCancelContext = .init()
    ) -> SM64ModernSwiftMarioActionReceipt? {
        guard phase == .initialized, let input = lastMarioInputReceipt?.mario else {
            return nil
        }
        marioState.input = input.input
        marioState.intendedMagnitude = input.intendedMagnitude
        marioState.intendedYaw = input.intendedYaw
        marioState.framesSinceA = input.framesSinceA
        marioState.framesSinceB = input.framesSinceB
        let decision = SM64MarioActionCancels.idle(
            state: marioState, context: context
        )
        let mutation: SM64MarioActionMutation?
        if let action = decision.action {
            mutation = marioState.dropAndSetAction(
                action,
                argument: decision.argument,
                facingDownhill: false
            )
        } else {
            mutation = nil
        }
        let receipt = SM64ModernSwiftMarioActionReceipt(
            engineTick: tickCount,
            decision: decision,
            mutation: mutation
        )
        lastMarioActionReceipt = receipt
        guard emitTrace(
            simulationTick: tickCount,
            domain: 2,
            recordKind: 3,
            recordID: 0x3300_0001,
            values: [
                UInt64(decision.action ?? 0),
                UInt64(decision.argument),
                UInt64(mutation?.action ?? 0),
                UInt64(mutation?.previousAction ?? 0),
                UInt64(mutation?.actionState ?? 0),
                UInt64(mutation?.actionTimer ?? 0),
                mutation?.droppedHeldObject == true ? 1 : 0
            ]
        ) == 0 else { return nil }
        return receipt
    }

    func step() -> SM64ModernSwiftEngineTickReceipt? {
        guard phase == .initialized else { return nil }
        let result = scheduler.update(state: state) { _, _ in }
        tickCount &+= 1
        let receipt = SM64ModernSwiftEngineTickReceipt(
            tick: tickCount,
            frame: result.frame,
            objectCount: result.objectCounter,
            resetEpoch: state.globals.resetEpoch
        )
        lastReceipt = receipt
        guard emitTrace(
            simulationTick: tickCount,
            domain: 3,
            recordKind: 1,
            recordID: 0x3100_0002,
            values: [
                receipt.frame,
                UInt64(receipt.objectCount),
                receipt.resetEpoch
            ]
        ) == 0 else { return nil }
        return receipt
    }

    func requestStop() -> Bool {
        guard phase == .initialized else { return false }
        phase = .stopping
        return true
    }

    func shutdown() -> Bool {
        guard phase == .initialized || phase == .stopping || phase == .failed else {
            return false
        }
        state.reset()
        progression = initialProgression
        inputNormalizer = SM64ControllerInputNormalizer()
        framesSinceA = 0
        framesSinceB = 0
        marioState = SM64MarioState()
        lastProgressionReceipt = nil
        lastInputReceipt = nil
        lastMarioInputReceipt = nil
        lastMarioActionReceipt = nil
        traceRecords.removeAll(keepingCapacity: true)
        lastTraceRecord = nil
        traceStatus = 0
        traceSequence = 0
        phase = .stopped
        return true
    }

    func fail() {
        guard phase != .stopped else { return }
        phase = .failed
    }

    @discardableResult
    private func emitTrace(
        simulationTick: UInt64,
        domain: UInt32,
        recordKind: UInt32,
        subjectID: UInt64 = 0,
        recordID: UInt64,
        flags: UInt32 = 0,
        values: [UInt64]
    ) -> SM64ModernStatus {
        let record: SM64OracleTraceRecord
        do {
            record = try SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: domain,
                recordKind: recordKind,
                subjectID: subjectID,
                recordID: recordID,
                sequence: traceSequence,
                flags: flags,
                values: Array(values.prefix(8))
            )
        } catch {
            traceStatus = 4
            phase = .failed
            return traceStatus
        }
        traceSequence &+= 1
        traceRecords.append(record)
        lastTraceRecord = record
        let status = traceSink?(record) ?? 0
        if status != 0 {
            traceStatus = status
            phase = .failed
        }
        return status
    }
}

protocol SM64ModernEngineRuntime: AnyObject {
    var authority: SM64ModernEngineAuthority { get }
    var implementation: String { get }

    func initialize() -> SM64ModernStatus
    func step() -> SM64ModernStatus
    func requestStop(reason: SM64ModernExitReason) -> SM64ModernStatus
    func shutdown() -> SM64ModernStatus
}

enum SM64ModernSwiftRuntimePhase: String, Equatable, Sendable {
    case cold
    case initialized
    case stopping
    case failed
    case stopped
}

final class SM64ModernCEngineRuntimeAdapter: SM64ModernEngineRuntime {
    let authority: SM64ModernEngineAuthority = .cCompatibility
    let implementation = "c_compatibility"

    private let callbacks: SM64ModernEngineRuntimeCallbacks

    init(callbacks: SM64ModernEngineRuntimeCallbacks) {
        self.callbacks = callbacks
    }

    func initialize() -> SM64ModernStatus {
        callbacks.initialize()
    }

    func step() -> SM64ModernStatus {
        callbacks.step()
    }

    func requestStop(reason: SM64ModernExitReason) -> SM64ModernStatus {
        callbacks.requestStop(reason)
    }

    func shutdown() -> SM64ModernStatus {
        callbacks.shutdown()
    }
}

final class SM64ModernSwiftEngineRuntime: SM64ModernEngineRuntime {
    let authority: SM64ModernEngineAuthority = .swift
    // M31g slice: Swift owns lifecycle ordering, failure state, the context's
    // state/scheduler/progression/input/Mario-input/action domains, and emits
    // schema-4 receipt records through an owner-thread sidecar sink, while
    // remaining gameplay/content domains still run through the compatibility
    // adapter.
    // The implementation string intentionally names that boundary; it must
    // not be mistaken for whole-engine Swift authority.
    let implementation = "swift_lifecycle_owner_c_domain_bridge"

    private let cFallback: SM64ModernEngineRuntime
    let swiftContext: SM64ModernSwiftEngineContext
    private var didLogDelegation = false
    private(set) var phase: SM64ModernSwiftRuntimePhase = .cold
    private(set) var lastSwiftTick: SM64ModernSwiftEngineTickReceipt?

    private static let statusOK: SM64ModernStatus = 0
    private static let statusInvalidState: SM64ModernStatus = 4
    private static let statusStopRequested: SM64ModernStatus = 8

    init(
        cFallback: SM64ModernEngineRuntime,
        swiftContext: SM64ModernSwiftEngineContext = SM64ModernSwiftEngineContext()
    ) {
        self.cFallback = cFallback
        self.swiftContext = swiftContext
    }

    func initialize() -> SM64ModernStatus {
        guard phase == .cold else { return Self.statusInvalidState }
        logDelegationIfNeeded()
        guard swiftContext.initialize() else {
            phase = .failed
            return Self.statusInvalidState
        }
        let status = cFallback.initialize()
        if status == Self.statusOK {
            phase = .initialized
        } else {
            swiftContext.fail()
            phase = .failed
        }
        return status
    }

    func step() -> SM64ModernStatus {
        guard phase == .initialized else { return Self.statusInvalidState }
        let status = cFallback.step()
        if status != Self.statusOK {
            swiftContext.fail()
            phase = .failed
            return status
        }
        guard let receipt = swiftContext.step() else {
            phase = .failed
            return Self.statusInvalidState
        }
        lastSwiftTick = receipt
        return status
    }

    func requestStop(reason: SM64ModernExitReason) -> SM64ModernStatus {
        guard phase == .initialized else { return Self.statusInvalidState }
        let status = cFallback.requestStop(reason: reason)
        if status == Self.statusOK || status == Self.statusStopRequested {
            guard swiftContext.requestStop() else {
                phase = .failed
                return Self.statusInvalidState
            }
            phase = .stopping
        } else {
            swiftContext.fail()
            phase = .failed
        }
        return status
    }

    func shutdown() -> SM64ModernStatus {
        guard phase == .initialized || phase == .stopping || phase == .failed else {
            return Self.statusInvalidState
        }
        let status = cFallback.shutdown()
        _ = swiftContext.shutdown()
        phase = status == Self.statusOK ? .stopped : .failed
        return status
    }

    private func logDelegationIfNeeded() {
        guard !didLogDelegation else { return }
        didLogDelegation = true
        runtimeLogger.notice(
            "swift_engine_context_started authority=swift implementation=swift_lifecycle_owner_c_domain_bridge c_domain_bridge=active"
        )
    }
}
