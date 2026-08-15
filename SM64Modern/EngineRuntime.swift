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
    // M31 slice: Swift owns lifecycle ordering and failure state while the
    // remaining gameplay/content domains still run through the compatibility
    // adapter. The implementation string intentionally names that boundary;
    // it must not be mistaken for whole-engine Swift authority.
    let implementation = "swift_lifecycle_owner_c_domain_bridge"

    private let cFallback: SM64ModernEngineRuntime
    private var didLogDelegation = false
    private(set) var phase: SM64ModernSwiftRuntimePhase = .cold

    private static let statusOK: SM64ModernStatus = 0
    private static let statusInvalidState: SM64ModernStatus = 4
    private static let statusStopRequested: SM64ModernStatus = 8

    init(cFallback: SM64ModernEngineRuntime) {
        self.cFallback = cFallback
    }

    func initialize() -> SM64ModernStatus {
        guard phase == .cold else { return Self.statusInvalidState }
        logDelegationIfNeeded()
        let status = cFallback.initialize()
        phase = status == Self.statusOK ? .initialized : .failed
        return status
    }

    func step() -> SM64ModernStatus {
        guard phase == .initialized else { return Self.statusInvalidState }
        let status = cFallback.step()
        if status != Self.statusOK { phase = .failed }
        return status
    }

    func requestStop(reason: SM64ModernExitReason) -> SM64ModernStatus {
        guard phase == .initialized else { return Self.statusInvalidState }
        let status = cFallback.requestStop(reason: reason)
        if status == Self.statusOK || status == Self.statusStopRequested {
            phase = .stopping
        } else {
            phase = .failed
        }
        return status
    }

    func shutdown() -> SM64ModernStatus {
        guard phase == .initialized || phase == .stopping || phase == .failed else {
            return Self.statusInvalidState
        }
        let status = cFallback.shutdown()
        phase = status == Self.statusOK ? .stopped : .failed
        return status
    }

    private func logDelegationIfNeeded() {
        guard !didLogDelegation else { return }
        didLogDelegation = true
        runtimeLogger.notice(
            "swift_engine_bootstrap authority=swift implementation=swift_shell_bootstrap_c_fallback"
        )
    }
}
