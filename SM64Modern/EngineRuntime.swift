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
    // STUB(M31): The Swift runtime shell delegates lifecycle work to the C
    // adapter until the complete Swift engine has replaced each domain.
    let implementation = "swift_shell_bootstrap_c_fallback"

    private let cFallback: SM64ModernEngineRuntime
    private var didLogDelegation = false

    init(cFallback: SM64ModernEngineRuntime) {
        self.cFallback = cFallback
    }

    func initialize() -> SM64ModernStatus {
        logDelegationIfNeeded()
        return cFallback.initialize()
    }

    func step() -> SM64ModernStatus {
        cFallback.step()
    }

    func requestStop(reason: SM64ModernExitReason) -> SM64ModernStatus {
        cFallback.requestStop(reason: reason)
    }

    func shutdown() -> SM64ModernStatus {
        cFallback.shutdown()
    }

    private func logDelegationIfNeeded() {
        guard !didLogDelegation else { return }
        didLogDelegation = true
        runtimeLogger.notice(
            "swift_engine_bootstrap authority=swift implementation=swift_shell_bootstrap_c_fallback"
        )
    }
}
