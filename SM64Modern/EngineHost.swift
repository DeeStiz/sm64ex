import AppKit
import Darwin
import Foundation
import Metal
import QuartzCore
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
    do {
        try host.initializeMetalOnEngineThread()
    } catch {
        engineLogger.error("metal_initialize_failed error=\(error.localizedDescription, privacy: .public)")
        return SM64_MODERN_STATUS_PLATFORM_ERROR
    }
    var rendering = makeMetalRenderingAPI(host: host)
    let renderingStatus = sm64_modern_install_rendering_api(&rendering)
    guard renderingStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("rendering_bridge_install_failed status=\(renderingStatus)")
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return renderingStatus
    }
    engineLogger.notice("platform_initialized title=\(title, privacy: .public)")
    return SM64_MODERN_STATUS_OK
}

private func platformShutdown(_ context: UnsafeMutableRawPointer?) {
    guard let host = engineHost(from: context) else { return }
    assert(host.isCurrentEngineThread)
    sm64_modern_uninstall_rendering_api()
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
    private struct MetalConfiguration {
        let device: any MTLDevice
        let layer: CAMetalLayer
        let drawableSize: CGSize
    }

    private enum State {
        case idle
        case starting
        case running
        case stopped
        case failed
    }

    // STUB(M8): replace legacy 30 Hz pacing with the audited deterministic
    // 1/60-second full-world clock.
    private static let legacyStepInterval = 1.0 / 30.0

    private let condition = NSCondition()
    private var state: State = .idle
    private var stopRequested = false
    private var requestedExitReason = SM64_MODERN_EXIT_USER_REQUESTED
    private var engineThreadIdentifier: UInt64 = 0
    private var stepCount: UInt64 = 0
    private var engineRunStatus = SM64_MODERN_STATUS_OK
    private var lifecycle = SM64ModernLifecycleApiV1()
    private var metalConfiguration: MetalConfiguration?
    private var metalRenderer: MetalRenderer?
    private var pendingDrawableSize: CGSize?
    private var engineRunLoop: CFRunLoop?

    var isCurrentEngineThread: Bool {
        condition.withLock {
            engineThreadIdentifier != 0 && engineThreadIdentifier == Self.currentThreadIdentifier()
        }
    }

    func configureMetal(device: any MTLDevice, layer: CAMetalLayer, drawableSize: CGSize) {
        precondition(Thread.isMainThread, "AppKit must configure the Metal surface")
        condition.withLock {
            precondition(state == .idle, "Metal must be configured before EngineHost.start")
            metalConfiguration = MetalConfiguration(device: device, layer: layer, drawableSize: drawableSize)
        }
    }

    func requestDrawableSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let runLoop = condition.withLock { () -> CFRunLoop? in
            pendingDrawableSize = size
            return engineRunLoop
        }
        if let runLoop {
            CFRunLoopWakeUp(runLoop)
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
        let runLoop = engineRunLoop
        condition.broadcast()
        if let runLoop {
            CFRunLoopStop(runLoop)
        }
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
            engineRunLoop = CFRunLoopGetCurrent()
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
        engineLogger.notice("lifecycle_running cadence_hz=30 capabilities=rendering")

        engineRunStatus = SM64_MODERN_STATUS_OK
        let stepTimer = Timer(timeInterval: Self.legacyStepInterval, repeats: true) { [self] _ in
            stepCoreOnEngineThread()
        }
        RunLoop.current.add(stepTimer, forMode: .common)
        stepTimer.fire()
        CFRunLoopRun()
        stepTimer.invalidate()

        if engineRunStatus == SM64_MODERN_STATUS_OK && condition.withLock({ stopRequested }) {
            let reason = condition.withLock { requestedExitReason }
            engineRunStatus = lifecycle.request_stop(reason)
        }

        if engineRunStatus != SM64_MODERN_STATUS_OK && engineRunStatus != SM64_MODERN_STATUS_STOP_REQUESTED {
            engineLogger.error("lifecycle_step_failed status=\(self.engineRunStatus)")
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

    private func stepCoreOnEngineThread() {
        precondition(isCurrentEngineThread)
        if condition.withLock({ stopRequested }) {
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        engineRunStatus = lifecycle.step()
        if engineRunStatus == SM64_MODERN_STATUS_OK {
            stepCount += 1
            if stepCount == 1 || stepCount.isMultiple(of: 300) {
                engineLogger.notice("lifecycle_step count=\(self.stepCount)")
                metalRenderer?.logSceneStatus(step: stepCount)
            }
        } else {
            CFRunLoopStop(CFRunLoopGetCurrent())
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
        // STUB(M5): publish audio capability after AVAudioEngine implements
        // the platform callbacks.
        platform.capabilities = SM64_MODERN_PLATFORM_CAP_RENDERING
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
            engineRunLoop = nil
            condition.broadcast()
        }
        engineLogger.notice("engine_thread_finished status=\(status) steps=\(self.stepCount)")
    }

    fileprivate func initializeMetalOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        let configuration = condition.withLock { metalConfiguration }
        guard let configuration else {
            throw MetalRendererError.configurationUnavailable
        }
        precondition(configuration.layer.drawableSize == configuration.drawableSize)
        let renderer = try MetalRenderer(
            device: configuration.device,
            layer: configuration.layer,
            consumeDrawableSize: { [weak self] in self?.consumePendingDrawableSize() }
        )
        metalRenderer = renderer
        renderer.start(on: .current)
    }

    fileprivate func shutdownMetalOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        defer { metalRenderer = nil }
        try metalRenderer?.shutdownAndDrain()
    }

    func renderingInitialize(filteringMode: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.initializeScene(filteringMode: filteringMode) ?? SM64_MODERN_STATUS_INVALID_STATE
    }

    func renderingShutdown() {
        precondition(isCurrentEngineThread)
        do { try shutdownMetalOnEngineThread() }
        catch { engineLogger.fault("metal_shutdown_failed error=\(error.localizedDescription, privacy: .public)") }
    }

    func renderingCreateShader(id: UInt32, filteringMode: UInt32, inputCount: UInt32, textureMask: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.registerShader(id: id, filteringMode: filteringMode, inputCount: inputCount, textureMask: textureMask)
            ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingSelectShader(_ id: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.selectShader(id)
    }
    func renderingCreateTexture(_ id: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.createTexture(id) ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingSelectTexture(tile: UInt32, id: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.selectTexture(tile: tile, id: id)
    }
    func renderingUploadTexture(id: UInt32, pixels: UnsafePointer<UInt8>, width: UInt32, height: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.uploadTexture(id: id, pixels: pixels, width: width, height: height) ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingSetSampler(tile: UInt32, linear: Bool, wrapS: UInt32, wrapT: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setSampler(tile: tile, linear: linear, wrapS: wrapS, wrapT: wrapT)
    }
    func renderingSetDepthTest(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setDepthTest(enabled)
    }
    func renderingSetDepthWrite(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setDepthWrite(enabled)
    }
    func renderingSetDecal(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setDecal(enabled)
    }
    func renderingSetViewport(_ rect: MetalRect) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setViewport(rect)
    }
    func renderingSetScissor(_ rect: MetalRect) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setScissor(rect)
    }
    func renderingSetAlphaBlend(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setAlphaBlend(enabled)
    }
    func renderingDraw(vertices: UnsafePointer<Float>?, floatCount: UInt32, triangleCount: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.draw(vertices: vertices, floatCount: floatCount, triangleCount: triangleCount) ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingStartFrame() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.startSceneFrame() ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingEndFrame() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.endSceneFrame() ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingFinish() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.finishScene() ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingDimensions() -> (UInt32, UInt32) {
        precondition(isCurrentEngineThread)
        return metalRenderer?.dimensions() ?? (1, 1)
    }

    private func consumePendingDrawableSize() -> CGSize? {
        precondition(isCurrentEngineThread)
        return condition.withLock {
            defer { pendingDrawableSize = nil }
            return pendingDrawableSize
        }
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
