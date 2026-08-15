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
    case camera
    case audio
    case rendering
    case frontend
}

struct SM64ModernSwiftEngineDomainReadiness: Equatable, Sendable {
    let swiftOwned: Set<SM64ModernSwiftEngineDomain>

    static let context = Self(swiftOwned: [
        .state, .objectScheduler, .progression
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

/// Owner-thread Swift state used by the Swift runtime while product domains
/// are migrated. It is deliberately a real engine context, not a callback
/// counter: object lists, globals, transforms, arenas, and unload ordering
/// advance through the same Swift state/scheduler contracts used by the
/// migrated actor bridges.
final class SM64ModernSwiftEngineContext {
    let state: SM64SwiftEngineState
    private let scheduler: SM64ObjectScheduler
    private let initialProgression: SM64ProgressionRuntime
    private(set) var progression: SM64ProgressionRuntime
    let domainReadiness = SM64ModernSwiftEngineDomainReadiness.context
    private(set) var phase: SM64ModernSwiftRuntimePhase = .cold
    private(set) var tickCount: UInt64 = 0
    private(set) var lastReceipt: SM64ModernSwiftEngineTickReceipt?
    private(set) var lastProgressionReceipt: SM64ModernSwiftProgressionReceipt?

    init(
        objectCapacity: Int = SM64ObjectPool.defaultCapacity,
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        progression: SM64ProgressionRuntime = SM64ProgressionRuntime()
    ) {
        self.state = SM64SwiftEngineState(objectCapacity: objectCapacity)
        self.scheduler = scheduler
        self.initialProgression = progression
        self.progression = progression
    }

    func initialize(levelNumber: Int16 = 1, areaIndex: Int16 = 0) -> Bool {
        guard phase == .cold else { return false }
        state.beginLevel(levelNumber: levelNumber, areaIndex: areaIndex)
        progression = initialProgression
        tickCount = 0
        lastReceipt = nil
        lastProgressionReceipt = nil
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
        lastProgressionReceipt = nil
        phase = .stopped
        return true
    }

    func fail() {
        guard phase != .stopped else { return }
        phase = .failed
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
    // M31c slice: Swift owns lifecycle ordering, failure state, the context's
    // state/scheduler/progression domains, while remaining gameplay/content
    // domains still run through the compatibility adapter. The implementation
    // string intentionally names that boundary; it must not be mistaken for
    // whole-engine Swift authority.
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
