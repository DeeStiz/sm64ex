import AppKit
import Darwin
import Foundation
import os

private let engineLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "EngineHost")

private func engineHost(from context: UnsafeMutableRawPointer?) -> EngineHost? {
    guard let context else { return nil }
    return Unmanaged<EngineHost>.fromOpaque(context).takeUnretainedValue()
}

private func platformInitialize(
    _ context: UnsafeMutableRawPointer?,
    _ windowTitle: UnsafePointer<CChar>?
) -> SM64ModernStatus {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else {
        return SM64_MODERN_STATUS_INVALID_STATE
    }
    let title = windowTitle.map(String.init(cString:)) ?? ""
    engineLogger.notice("platform_initialized title=\(title, privacy: .public)")
    return SM64_MODERN_STATUS_OK
}

private func platformShutdown(_ context: UnsafeMutableRawPointer?) {
    guard let host = engineHost(from: context) else { return }
    assert(host.isCurrentEngineThread)
    engineLogger.notice("platform_shutdown")
}

private func platformCurrentThread(_ context: UnsafeMutableRawPointer?) -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func platformExitRequested(
    _ context: UnsafeMutableRawPointer?,
    _ reason: SM64ModernExitReason
) {
    guard let host = engineHost(from: context) else { return }
    host.recordCoreExit(reason: reason)
}

private func platformError(
    _ context: UnsafeMutableRawPointer?,
    _ status: SM64ModernStatus,
    _ message: UnsafePointer<CChar>?
) {
    let text = message.map(String.init(cString:)) ?? "Unknown core error"
    engineLogger.error("core_error status=\(status) message=\(text, privacy: .public)")
}

final class EngineHost: @unchecked Sendable {
    private enum State {
        case idle
        case starting
        case running
        case stopping
        case stopped
        case failed
    }

    private let condition = NSCondition()
    private var state: State = .idle
    private var stopRequested = false
    private var requestedExitReason = SM64_MODERN_EXIT_USER_REQUESTED
    private var engineThreadIdentifier: UInt64 = 0
    private var stepCount: UInt64 = 0
    private var lifecycle = SM64ModernLifecycleApiV1()

    var isCurrentEngineThread: Bool {
        condition.withLock {
            engineThreadIdentifier != 0 && engineThreadIdentifier == Self.currentThreadIdentifier()
        }
    }

    func start() {
        condition.lock()
        precondition(state == .idle, "EngineHost.start must be called exactly once")
        state = .starting
        condition.unlock()

        let thread = Thread { [self] in
            runEngineThread()
        }
        thread.name = "SM64 Modern Engine"
        thread.qualityOfService = .userInteractive
        thread.start()
    }

    func requestStopAndWait(reason: SM64ModernExitReason) {
        precondition(Thread.isMainThread, "AppKit owns the synchronous shutdown request")

        condition.lock()
        if state == .idle || state == .stopped || state == .failed {
            condition.unlock()
            return
        }
        stopRequested = true
        requestedExitReason = reason
        condition.broadcast()
        while state != .stopped && state != .failed {
            condition.wait()
        }
        condition.unlock()
    }

    func recordCoreExit(reason: SM64ModernExitReason) {
        assert(isCurrentEngineThread)
        condition.withLock {
            requestedExitReason = reason
        }
    }

    private func runEngineThread() {
        let identifier = Self.currentThreadIdentifier()
        condition.withLock {
            engineThreadIdentifier = identifier
        }
        engineLogger.notice("engine_thread_started token=\(identifier) main=\(Thread.isMainThread)")

        let initializeStatus = initializeCore()
        guard initializeStatus == SM64_MODERN_STATUS_OK else {
            finish(state: .failed, status: initializeStatus)
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
            return
        }

        condition.withLock {
            state = .running
            condition.broadcast()
        }
        engineLogger.notice("lifecycle_running cadence_hz=30 capabilities=0")

        var nextStep = Date()
        var runStatus = SM64_MODERN_STATUS_OK
        while runStatus == SM64_MODERN_STATUS_OK {
            let shouldStop = condition.withLock { stopRequested }
            if shouldStop {
                let reason = condition.withLock { requestedExitReason }
                runStatus = lifecycle.request_stop(reason)
                break
            }

            runStatus = lifecycle.step()
            if runStatus == SM64_MODERN_STATUS_OK {
                stepCount += 1
                if stepCount == 1 || stepCount.isMultiple(of: 300) {
                    engineLogger.notice("lifecycle_step count=\(self.stepCount)")
                }
            }

            nextStep.addTimeInterval(1.0 / 30.0)
            condition.lock()
            if !stopRequested {
                _ = condition.wait(until: nextStep)
            }
            condition.unlock()
            if nextStep.timeIntervalSinceNow < -0.25 {
                nextStep = Date()
            }
        }

        if runStatus != SM64_MODERN_STATUS_OK && runStatus != SM64_MODERN_STATUS_STOP_REQUESTED {
            engineLogger.error("lifecycle_step_failed status=\(runStatus)")
        }

        let shutdownStatus = lifecycle.shutdown()
        let finalState: State = shutdownStatus == SM64_MODERN_STATUS_OK ? .stopped : .failed
        finish(state: finalState, status: shutdownStatus)

        if !condition.withLock({ stopRequested }) {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func initializeCore() -> SM64ModernStatus {
        var lifecycle = SM64ModernLifecycleApiV1()
        var status = sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernLifecycleApiV1>.size),
            &lifecycle
        )
        guard status == SM64_MODERN_STATUS_OK else { return status }
        self.lifecycle = lifecycle

        var config = SM64ModernLifecycleConfigV1()
        config.header.abi_version = SM64_MODERN_ABI_VERSION_1
        config.header.struct_size = UInt32(MemoryLayout<SM64ModernLifecycleConfigV1>.size)
        config.main_pool_size = 0
        config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF
        config.skip_intro = 0

        do {
            let paths = try HostPaths.resolve()
            try withUnsafeMutableBytes(of: &config.game_directory) { try Self.copyCString(paths.gameDirectory, into: $0) }
            try withUnsafeMutableBytes(of: &config.save_directory) { try Self.copyCString(paths.saveDirectory, into: $0) }
            try withUnsafeMutableBytes(of: &config.config_file) { try Self.copyCString("sm64-modern-config.txt", into: $0) }
            try withUnsafeMutableBytes(of: &config.window_title) { try Self.copyCString("SM64 Modern", into: $0) }
            engineLogger.notice("host_paths game=\(paths.gameDirectory, privacy: .public) save=\(paths.saveDirectory, privacy: .public)")
        } catch {
            engineLogger.error("host_path_error \(error.localizedDescription, privacy: .public)")
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }

        var platform = SM64ModernPlatformApiV1()
        platform.header.abi_version = SM64_MODERN_ABI_VERSION_1
        platform.header.struct_size = UInt32(MemoryLayout<SM64ModernPlatformApiV1>.size)
        platform.capabilities = 0
        platform.reserved = 0
        platform.context = Unmanaged.passUnretained(self).toOpaque()
        platform.initialize = platformInitialize
        platform.shutdown = platformShutdown
        platform.current_thread = platformCurrentThread
        platform.exit_requested = platformExitRequested
        platform.error_reported = platformError

        status = sm64_modern_validate_platform_api(&platform)
        guard status == SM64_MODERN_STATUS_OK else { return status }
        return self.lifecycle.initialize(&config, &platform)
    }

    private func finish(state: State, status: SM64ModernStatus) {
        condition.withLock {
            self.state = state
            condition.broadcast()
        }
        engineLogger.notice("engine_thread_finished status=\(status) steps=\(self.stepCount)")
    }

    private static func currentThreadIdentifier() -> UInt64 {
        var identifier: UInt64 = 0
        let result = pthread_threadid_np(nil, &identifier)
        precondition(result == 0, "pthread_threadid_np must produce an owner token")
        return identifier
    }

    private static func copyCString(_ value: String, into destination: UnsafeMutableRawBufferPointer) throws {
        let bytes = Array(value.utf8)
        guard bytes.count < destination.count else {
            throw HostPathError.valueTooLong
        }
        destination.initializeMemory(as: UInt8.self, repeating: 0)
        destination.copyBytes(from: bytes)
    }
}

private struct HostPaths {
    let gameDirectory: String
    let saveDirectory: String

    static func resolve() throws -> HostPaths {
        let environment = ProcessInfo.processInfo.environment
        let info = Bundle.main.infoDictionary ?? [:]

        let gameDirectory = environment["SM64_MODERN_GAME_DIR"]
            ?? nonempty(info["SM64ModernDevelopmentRoot"] as? String)
        guard let gameDirectory else { throw HostPathError.missingGameDirectory }

        let defaultSave = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "SM64 Modern", directoryHint: .isDirectory).path
        let saveDirectory = environment["SM64_MODERN_SAVE_DIR"]
            ?? nonempty(info["SM64ModernDevelopmentSaveRoot"] as? String)
            ?? defaultSave
        try FileManager.default.createDirectory(atPath: saveDirectory, withIntermediateDirectories: true)
        return HostPaths(gameDirectory: gameDirectory, saveDirectory: saveDirectory)
    }

    private static func nonempty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}

private enum HostPathError: LocalizedError {
    case missingGameDirectory
    case valueTooLong

    var errorDescription: String? {
        switch self {
        case .missingGameDirectory:
            "No development game directory was configured"
        case .valueTooLong:
            "A host path exceeds the public C ABI capacity"
        }
    }
}

private extension NSCondition {
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
