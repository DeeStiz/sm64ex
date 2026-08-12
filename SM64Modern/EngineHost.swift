import AppKit
import Darwin
import Foundation
import Metal
import QuartzCore
import os

private let engineLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "EngineHost")
private let audioLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Audio")

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
    guard let inputService = host.inputServiceOnEngineThread else {
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return SM64_MODERN_STATUS_INVALID_STATE
    }
    var input = makeAppleInputAPI(service: inputService)
    let inputStatus = sm64_modern_install_input_api(&input)
    guard inputStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("input_bridge_install_failed status=\(inputStatus)")
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return inputStatus
    }
    engineLogger.notice("input_bridge_installed abi=1")
    let gameplayService = host.gameplayServiceOnEngineThread
    var gameplay = makeSwiftGameplayMigrationAPI(service: gameplayService)
    let gameplayStatus = sm64_modern_install_gameplay_migration_api(&gameplay)
    guard gameplayStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("gameplay_bridge_install_failed status=\(gameplayStatus)")
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return gameplayStatus
    }
    engineLogger.notice("gameplay_bridge_installed abi=1 slices=mario_buttons,bobomb_release")
    do {
        try host.initializeAudioOnEngineThread()
    } catch {
        audioLogger.error("audio_initialize_failed error=\(error.localizedDescription, privacy: .public)")
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return SM64_MODERN_STATUS_PLATFORM_ERROR
    }
    engineLogger.notice("platform_initialized title=\(title, privacy: .public)")
    return SM64_MODERN_STATUS_OK
}

private func platformShutdown(_ context: UnsafeMutableRawPointer?) {
    guard let host = engineHost(from: context) else { return }
    assert(host.isCurrentEngineThread)
    host.shutdownAudioOnEngineThread()
    sm64_modern_uninstall_gameplay_migration_api()
    sm64_modern_uninstall_input_api()
    sm64_modern_uninstall_rendering_api()
    engineLogger.notice("platform_shutdown")
}

private func platformAudioBuffered(_ context: UnsafeMutableRawPointer?) -> Int32 {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else { return 0 }
    return host.audioBufferedFrames()
}

private func platformAudioDesiredBuffered(_ context: UnsafeMutableRawPointer?) -> UInt32 {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else { return 0 }
    return host.audioDesiredBufferedFrames()
}

private func platformAudioPlay(
    _ context: UnsafeMutableRawPointer?,
    _ samples: UnsafePointer<Int16>?,
    _ frameCount: UInt32
) {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else { return }
    guard let samples else {
        precondition(frameCount == 0, "Non-empty audio packets require sample storage")
        return
    }
    host.audioPlay(samples: samples, frameCount: frameCount)
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

    private let condition = NSCondition()
    private var state: State = .idle
    private var stopRequested = false
    private var requestedExitReason = SM64_MODERN_EXIT_USER_REQUESTED
    private var engineThreadIdentifier: UInt64 = 0
    private var stepCount: UInt64 = 0
    private var engineRunStatus = SM64_MODERN_STATUS_OK
    private var lifecycle = SM64ModernLifecycleApiV1()
    private var timebaseSnapshot = SM64ModernTimebaseSnapshotV1()
    private var parityCoordinator: GameplayParityCoordinator?
    private let gameplayService = SwiftGameplayService()
    private var automaticTerminationRequested = false
    private var inputService: AppleInputService?
    private var audioService: SM64ModernAppleAudioService?
    private var loggedAudioEnqueue = false
    private var loggedAudioRender = false
    private var metalConfiguration: MetalConfiguration?
    private var metalRenderer: MetalRenderer?
    private var pendingDrawableSize: CGSize?
    private var engineRunLoop: CFRunLoop?
    private var schedulerWakeCount: UInt64 = 0
    private var schedulerLateWakeCount: UInt64 = 0
    private var schedulerCatchUpSteps: UInt64 = 0
    private var schedulerDroppedSteps: UInt64 = 0
    private var schedulerMaximumLatenessNanoseconds: UInt64 = 0

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

    func configureInput(_ service: AppleInputService) {
        precondition(Thread.isMainThread, "AppKit must configure input")
        condition.withLock {
            precondition(state == .idle, "Input must be configured before EngineHost.start")
            inputService = service
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
            CFRunLoopWakeUp(runLoop)
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
        engineLogger.notice(
            "lifecycle_running cadence_hz=\(self.timebaseSnapshot.simulation_rate_numerator)/\(self.timebaseSnapshot.simulation_rate_denominator) capabilities=rendering,input,audio legacy_hz=\(self.timebaseSnapshot.legacy_rate_numerator)/\(self.timebaseSnapshot.legacy_rate_denominator) paired_ticks=\(self.timebaseSnapshot.simulation_ticks_per_legacy_tick)"
        )

        engineRunStatus = SM64_MODERN_STATUS_OK
        runFixedStepLoop()

        if engineRunStatus == SM64_MODERN_STATUS_OK && condition.withLock({ stopRequested }) {
            let reason = condition.withLock { requestedExitReason }
            engineRunStatus = lifecycle.request_stop(reason)
        }

        if engineRunStatus != SM64_MODERN_STATUS_OK && engineRunStatus != SM64_MODERN_STATUS_STOP_REQUESTED {
            engineLogger.error("lifecycle_step_failed status=\(self.engineRunStatus)")
        }

        let parityStatus = parityCoordinator?.endAndReport() ?? SM64_MODERN_STATUS_OK
        parityCoordinator = nil
        let shutdownStatus = lifecycle.shutdown()
        let executionStatus = engineRunStatus != SM64_MODERN_STATUS_OK
            && engineRunStatus != SM64_MODERN_STATUS_STOP_REQUESTED
            ? engineRunStatus : SM64_MODERN_STATUS_OK
        let finalStatus = shutdownStatus != SM64_MODERN_STATUS_OK
            ? shutdownStatus
            : (executionStatus != SM64_MODERN_STATUS_OK ? executionStatus : parityStatus)
        let finalState: State = finalStatus == SM64_MODERN_STATUS_OK ? .stopped : .failed
        finish(state: finalState, status: finalStatus)

        if automaticTerminationRequested || !condition.withLock({ stopRequested }) {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func runFixedStepLoop() {
        precondition(isCurrentEngineThread)
        var scheduler = RationalFixedStepScheduler(
            rateNumerator: timebaseSnapshot.simulation_rate_numerator,
            rateDenominator: timebaseSnapshot.simulation_rate_denominator,
            maxCatchUpSteps: timebaseSnapshot.max_catch_up_steps
        )
        scheduler.start(atNanoseconds: MonotonicClock.nowNanoseconds())
        engineLogger.notice(
            "fixed_step_scheduler_started clock=monotonic_raw max_catch_up=\(self.timebaseSnapshot.max_catch_up_steps)"
        )

        while engineRunStatus == SM64_MODERN_STATUS_OK,
              !condition.withLock({ stopRequested }) {
            let plan = scheduler.plan(atNanoseconds: MonotonicClock.nowNanoseconds())
            schedulerWakeCount += 1
            if plan.latenessNanoseconds >= 1_000_000 {
                schedulerLateWakeCount += 1
            }
            if plan.dueSteps > 1 {
                schedulerCatchUpSteps += UInt64(plan.dueSteps - 1)
            }
            schedulerDroppedSteps += plan.droppedSteps
            schedulerMaximumLatenessNanoseconds = max(
                schedulerMaximumLatenessNanoseconds,
                plan.latenessNanoseconds
            )

            if plan.dueSteps == 0 {
                let waitSeconds = min(Double(plan.waitNanoseconds) / 1_000_000_000, 1.0)
                _ = CFRunLoopRunInMode(.defaultMode, waitSeconds, true)
                continue
            }

            for _ in 0..<plan.dueSteps {
                stepCoreOnEngineThread()
                if engineRunStatus != SM64_MODERN_STATUS_OK
                    || condition.withLock({ stopRequested }) {
                    break
                }
            }
            if stepCount == 1 || stepCount.isMultiple(of: 300) {
                logSchedulerStatus()
            }
        }
        logSchedulerStatus(event: "fixed_step_scheduler_finished")
    }

    private func logSchedulerStatus(event: String = "fixed_step_scheduler_status") {
        engineLogger.notice(
            "\(event, privacy: .public) step=\(self.stepCount) wakes=\(self.schedulerWakeCount) late_wakes=\(self.schedulerLateWakeCount) catch_up_steps=\(self.schedulerCatchUpSteps) dropped_steps=\(self.schedulerDroppedSteps) max_late_ns=\(self.schedulerMaximumLatenessNanoseconds)"
        )
    }

    private func stepCoreOnEngineThread() {
        precondition(isCurrentEngineThread)
        if condition.withLock({ stopRequested }) {
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        do {
            let recoveryWasPending = audioService?.recoveryPending() ?? false
            try audioService?.recoverIfNeeded()
            if recoveryWasPending, let status = audioService?.audioStatus() {
                audioLogger.notice(
                    "audio_route_recovered output_hz=\(status.output_sample_rate, privacy: .public) output_channels=\(status.output_channel_count, privacy: .public)"
                )
            }
        } catch {
            audioLogger.error("audio_recovery_failed error=\(error.localizedDescription, privacy: .public)")
            engineRunStatus = SM64_MODERN_STATUS_PLATFORM_ERROR
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        // Recover and discard stale route data before the core asks how much
        // PCM is buffered, so this tick immediately refills the restarted graph.
        engineRunStatus = lifecycle.step()
        guard engineRunStatus == SM64_MODERN_STATUS_OK else {
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        stepCount += 1
        logAudioRenderIfNeeded()
        if stepCount == 1 || stepCount.isMultiple(of: 300) {
            engineLogger.notice("lifecycle_step count=\(self.stepCount)")
            metalRenderer?.logSceneStatus(step: stepCount)
            logAudioStatus()
        }
        if let parityCoordinator {
            let boundary = parityCoordinator.handleTickBoundary(step: stepCount)
            if boundary.status != SM64_MODERN_STATUS_OK {
                engineRunStatus = boundary.status
                CFRunLoopStop(CFRunLoopGetCurrent())
                return
            }
            if boundary.shouldStop {
                condition.withLock {
                    stopRequested = true
                    requestedExitReason = SM64_MODERN_EXIT_PLATFORM_REQUESTED
                    automaticTerminationRequested = true
                }
                engineLogger.notice("bounded_parity_run_complete steps=\(self.stepCount)")
                CFRunLoopStop(CFRunLoopGetCurrent())
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

        var timebase = SM64ModernTimebaseApiV1()
        status = sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernTimebaseApiV1>.size),
            &timebase
        )
        guard status == SM64_MODERN_STATUS_OK else { return status }
        var timebaseConfig = SM64ModernTimebaseConfigV1()
        timebaseConfig.header.abi_version = SM64_MODERN_ABI_VERSION_1
        timebaseConfig.header.struct_size = UInt32(MemoryLayout<SM64ModernTimebaseConfigV1>.size)
        // M8d activates the native product clock after M8b/M8c moved legacy
        // state and world dynamics behind the paired-boundary contract.
        // Legacy builds still configure 30/1 in their own host path.
        timebaseConfig.simulation_rate_numerator = 60
        timebaseConfig.simulation_rate_denominator = 1
        timebaseConfig.legacy_rate_numerator = 30
        timebaseConfig.legacy_rate_denominator = 1
        timebaseConfig.max_catch_up_steps = 2
        status = timebase.configure(&timebaseConfig)
        guard status == SM64_MODERN_STATUS_OK else { return status }
        var timebaseSnapshot = SM64ModernTimebaseSnapshotV1()
        status = timebase.get_snapshot(&timebaseSnapshot)
        guard status == SM64_MODERN_STATUS_OK else { return status }
        self.timebaseSnapshot = timebaseSnapshot
        engineLogger.notice(
            "timebase_configured simulation_hz=\(timebaseSnapshot.simulation_rate_numerator)/\(timebaseSnapshot.simulation_rate_denominator) legacy_hz=\(timebaseSnapshot.legacy_rate_numerator)/\(timebaseSnapshot.legacy_rate_denominator) paired_ticks=\(timebaseSnapshot.simulation_ticks_per_legacy_tick) fingerprint=\(timebaseSnapshot.fingerprint)"
        )

        var config = SM64ModernLifecycleConfigV1()
        config.header.abi_version = SM64_MODERN_ABI_VERSION_1
        config.header.struct_size = UInt32(MemoryLayout<SM64ModernLifecycleConfigV1>.size)
        config.main_pool_size = 0
        config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF
        config.skip_intro = 0

        let paths: HostPaths
        do {
            paths = try HostPaths.resolve()
            try withUnsafeMutableBytes(of: &config.game_directory) { try Self.copyCString(paths.gameDirectory, into: $0) }
            try withUnsafeMutableBytes(of: &config.save_directory) { try Self.copyCString(paths.saveDirectory, into: $0) }
            try withUnsafeMutableBytes(of: &config.config_file) { try Self.copyCString("sm64-modern-config.txt", into: $0) }
            try withUnsafeMutableBytes(of: &config.window_title) { try Self.copyCString("SM64 Modern", into: $0) }
            engineLogger.notice("host_paths_resolved")
        } catch {
            engineLogger.error("host_path_error \(error.localizedDescription, privacy: .private)")
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }

        var platform = SM64ModernPlatformApiV1()
        platform.header.abi_version = SM64_MODERN_ABI_VERSION_1
        platform.header.struct_size = UInt32(MemoryLayout<SM64ModernPlatformApiV1>.size)
        platform.capabilities = SM64_MODERN_PLATFORM_CAP_RENDERING
            | SM64_MODERN_PLATFORM_CAP_INPUT
            | SM64_MODERN_PLATFORM_CAP_AUDIO
        platform.reserved = 0
        platform.context = Unmanaged.passUnretained(self).toOpaque()
        platform.initialize = platformInitialize
        platform.shutdown = platformShutdown
        platform.audio_buffered = platformAudioBuffered
        platform.audio_desired_buffered = platformAudioDesiredBuffered
        platform.audio_play = platformAudioPlay
        platform.current_thread = platformCurrentThread
        platform.exit_requested = platformExitRequested
        platform.error_reported = platformError

        status = sm64_modern_validate_platform_api(&platform)
        guard status == SM64_MODERN_STATUS_OK else { return status }
        status = self.lifecycle.initialize(&config, &platform)
        guard status == SM64_MODERN_STATUS_OK else { return status }

        let parityStart = GameplayParityCoordinator.beginFromEnvironment(
            saveDirectory: paths.saveDirectory,
            gameplayService: gameplayService
        )
        guard parityStart.status == SM64_MODERN_STATUS_OK else {
            _ = self.lifecycle.shutdown()
            return parityStart.status
        }
        parityCoordinator = parityStart.coordinator
        return SM64_MODERN_STATUS_OK
    }

    fileprivate var gameplayServiceOnEngineThread: SwiftGameplayService {
        precondition(isCurrentEngineThread)
        return gameplayService
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
            isOwnerThread: { [weak self] in self?.isCurrentEngineThread == true },
            consumeDrawableSize: { [weak self] in self?.consumePendingDrawableSize() }
        )
        metalRenderer = renderer
        renderer.start(on: .current)
    }

    fileprivate var inputServiceOnEngineThread: AppleInputService? {
        precondition(isCurrentEngineThread)
        return condition.withLock { inputService }
    }

    fileprivate func initializeAudioOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        guard audioService == nil else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.Audio",
                code: Int(SM64_MODERN_STATUS_INVALID_STATE),
                userInfo: [NSLocalizedDescriptionKey: "Native audio is already initialized"]
            )
        }
        guard let service = SM64ModernAppleAudioService.makeAudioService() else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.Audio",
                code: Int(SM64_MODERN_STATUS_OUT_OF_MEMORY),
                userInfo: [NSLocalizedDescriptionKey: "Could not allocate the native audio service"]
            )
        }
        do {
            try service.start()
        } catch {
            service.stop()
            throw error
        }
        audioService = service
        let status = service.audioStatus()
        audioLogger.notice(
            "audio_service_started input_hz=32000 format=s16_interleaved_stereo output_hz=\(status.output_sample_rate) output_channels=\(status.output_channel_count) capacity=\(status.capacity_frames) desired=\(status.desired_buffered_frames) backlog=\(status.backlog_ceiling_frames)"
        )
        engineLogger.notice(
            "presentation_cadence native_hz=\(self.timebaseSnapshot.simulation_rate_numerator)/\(self.timebaseSnapshot.simulation_rate_denominator) legacy_hz=\(self.timebaseSnapshot.legacy_rate_numerator)/\(self.timebaseSnapshot.legacy_rate_denominator) drawable_per_native_tick=true"
        )
    }

    fileprivate func shutdownAudioOnEngineThread() {
        precondition(isCurrentEngineThread)
        guard let audioService else { return }
        audioService.stop()
        let status = audioService.audioStatus()
        self.audioService = nil
        audioLogger.notice(
            "audio_service_stopped enqueued=\(status.ring.enqueued_frames) rendered=\(status.ring.rendered_frames) underrun=\(status.ring.underrun_frames) dropped=\(status.ring.dropped_frames) render_calls=\(status.ring.render_calls)"
        )
    }

    fileprivate func audioBufferedFrames() -> Int32 {
        precondition(isCurrentEngineThread)
        guard let audioService else {
            assertionFailure("The advertised audio capability requires a live service")
            return 0
        }
        return audioService.bufferedFrames()
    }

    fileprivate func audioDesiredBufferedFrames() -> UInt32 {
        precondition(isCurrentEngineThread)
        guard let audioService else {
            assertionFailure("The advertised audio capability requires a live service")
            return 0
        }
        return audioService.desiredBufferedFrames()
    }

    fileprivate func audioPlay(samples: UnsafePointer<Int16>, frameCount: UInt32) {
        precondition(isCurrentEngineThread)
        guard let audioService else {
            assertionFailure("The advertised audio capability requires a live service")
            return
        }
        audioService.enqueueInterleavedStereoSamples(samples, frameCount: frameCount)
        if !loggedAudioEnqueue {
            loggedAudioEnqueue = true
            let blocksPerNativeStep = self.timebaseSnapshot.simulation_ticks_per_legacy_tick > 1 ? 1 : 2
            audioLogger.notice(
                "audio_enqueue_started blocks_per_native_step=\(blocksPerNativeStep) frames=\(frameCount)"
            )
        }
    }

    private func logAudioRenderIfNeeded() {
        precondition(isCurrentEngineThread)
        guard !loggedAudioRender, let status = audioService?.audioStatus(), status.ring.render_calls > 0 else {
            return
        }
        loggedAudioRender = true
        audioLogger.notice(
            "audio_render_started calls=\(status.ring.render_calls) rendered=\(status.ring.rendered_frames) underrun=\(status.ring.underrun_frames)"
        )
    }

    private func logAudioStatus() {
        precondition(isCurrentEngineThread)
        guard let status = audioService?.audioStatus() else { return }
        audioLogger.notice(
            "audio_status step=\(self.stepCount) running=\(status.running) buffered=\(status.buffered_frames) rendered=\(status.ring.rendered_frames) underrun=\(status.ring.underrun_frames) dropped=\(status.ring.dropped_frames) recovery_pending=\(status.recovery_pending)"
        )
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
    func renderingSetSampler(tile: UInt32, id: UInt32, linear: Bool, wrapS: UInt32, wrapT: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setSampler(tile: tile, id: id, linear: linear, wrapS: wrapS, wrapT: wrapT)
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

        let gameDirectory = environment["SM64_MODERN_GAME_DIR"]
        guard let gameDirectory else { throw HostPathError.missingGameDirectory }

        let defaultSave = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "SM64 Modern", directoryHint: .isDirectory).path
        let saveDirectory = environment["SM64_MODERN_SAVE_DIR"] ?? defaultSave
        try FileManager.default.createDirectory(atPath: saveDirectory, withIntermediateDirectories: true)
        return HostPaths(gameDirectory: gameDirectory, saveDirectory: saveDirectory)
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
