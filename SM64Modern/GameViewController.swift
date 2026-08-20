import AppKit
import Metal
import os

@MainActor
final class GameViewController: NSViewController {
    private let engineHost: EngineHost
    private let logger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Window")
    private var initialized = false
    private var inputService: AppleInputService?
    private var focusObservers: [NSObjectProtocol] = []
    private var m34StressTimer: Timer?
    private var m34StressStep = 0
    private var m34StressMinimizeEnabled = false

    override var acceptsFirstResponder: Bool { true }

    init(engineHost: EngineHost) {
        self.engineHost = engineHost
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = GameView(frame: NSRect(x: 0, y: 0, width: 960, height: 720))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard !initialized else { return }
        initialized = true

        guard let gameView = view as? GameView else {
            preconditionFailure("GameViewController requires GameView")
        }
        guard let device = MTLCreateSystemDefaultDevice() else {
            logger.fault("metal_device_unavailable")
            NSApplication.shared.terminate(nil)
            return
        }
        let size = gameView.configureMetal(device: device)
        precondition(size.width > 0 && size.height > 0, "Engine startup requires a drawable-sized surface")
        engineHost.configureMetal(device: device, layer: gameView.metalLayer, drawableSize: size)
        let inputService = AppleInputService()
        self.inputService = inputService
        engineHost.configureInput(inputService)
        installFocusObservers()
        view.window?.makeFirstResponder(self)
        gameView.installDrawableSizeHandler { [engineHost] size in
            engineHost.requestDrawableSize(size)
        }
        logger.notice(
            "window_ready layer=CAMetalLayer drawable=\(Int(size.width))x\(Int(size.height)) device=\(device.name, privacy: .public)"
        )

        // The C lifecycle starts last so AppKit owns a complete, measurable
        // surface before the dedicated thread begins stepping the game.
        engineHost.start()
        if ProcessInfo.processInfo.environment["SM64_MODERN_M34_STRESS"] == "1" {
            armM34Stress()
        }
    }

    override func viewWillDisappear() {
        inputService?.setFocused(false)
        super.viewWillDisappear()
    }

    override func keyDown(with event: NSEvent) {
        inputService?.keyChanged(appKitKeyCode: event.keyCode, pressed: true, isRepeat: event.isARepeat)
    }

    override func keyUp(with event: NSEvent) {
        inputService?.keyChanged(appKitKeyCode: event.keyCode, pressed: false)
    }

    override func flagsChanged(with event: NSEvent) {
        inputService?.modifierChanged(appKitKeyCode: event.keyCode, flags: event.modifierFlags)
    }

    override func mouseDown(with event: NSEvent) { inputService?.mouseButtonChanged(appKitButton: 0, pressed: true) }
    override func mouseUp(with event: NSEvent) { inputService?.mouseButtonChanged(appKitButton: 0, pressed: false) }
    override func rightMouseDown(with event: NSEvent) { inputService?.mouseButtonChanged(appKitButton: 1, pressed: true) }
    override func rightMouseUp(with event: NSEvent) { inputService?.mouseButtonChanged(appKitButton: 1, pressed: false) }
    override func otherMouseDown(with event: NSEvent) {
        inputService?.mouseButtonChanged(appKitButton: event.buttonNumber, pressed: true)
    }
    override func otherMouseUp(with event: NSEvent) {
        inputService?.mouseButtonChanged(appKitButton: event.buttonNumber, pressed: false)
    }

    isolated deinit {
        m34StressTimer?.invalidate()
        for observer in focusObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func armM34Stress() {
        m34StressMinimizeEnabled = ProcessInfo.processInfo.environment["SM64_MODERN_M34_STRESS_MINIMIZE"] == "1"
        if m34StressMinimizeEnabled, let window = view.window {
            installM34StressWindowObservers(for: window)
        }
        let timer = Timer(
            timeInterval: 0.25,
            target: self,
            selector: #selector(runM34StressStep(_:)),
            userInfo: nil,
            repeats: true
        )
        m34StressTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        logger.notice("m34_stress_armed minimize=\(self.m34StressMinimizeEnabled)")
    }

    @objc private func runM34StressStep(_ timer: Timer) {
        guard let window = view.window else {
            timer.invalidate()
            return
        }
        let step = m34StressStep
        let sizes: [NSSize] = [
            NSSize(width: 800, height: 600),
            NSSize(width: 1024, height: 768),
            NSSize(width: 1280, height: 960),
            NSSize(width: 960, height: 720),
        ]
        let size = sizes[step % sizes.count]
        window.setContentSize(size)
        // AppKit may coalesce the layout pass while the test app is running
        // under a headless/open launch. Publish the intended backing-pixel
        // size immediately as well so every request exercises the owner-
        // thread CAMetalLayer handoff instead of only the eventual layout.
        let backingScale = max(window.backingScaleFactor, 1)
        engineHost.requestDrawableSize(
            CGSize(width: size.width * backingScale, height: size.height * backingScale)
        )
        logger.notice(
            "m34_stress_resize_requested index=\(step) size=\(Int(size.width))x\(Int(size.height))"
        )
        switch step {
        case 2:
            engineHost.requestPresentationPaused(true)
            logger.notice("m34_stress_pause_requested paused=true cycle=1")
        case 3:
            // Exercise an idempotent repeated pause request while the
            // display-link callback is quiescent.
            engineHost.requestPresentationPaused(true)
            logger.notice("m34_stress_pause_requested paused=true cycle=1_repeat")
        case 4:
            engineHost.requestPresentationPaused(false)
            logger.notice("m34_stress_pause_requested paused=false cycle=1")
        case 5:
            logger.notice("m34_stress_post_resume_resize_requested index=\(step)")
        case 6:
            engineHost.requestPresentationPaused(true)
            logger.notice("m34_stress_pause_requested paused=true cycle=2")
        case 7:
            engineHost.requestPresentationPaused(false)
            logger.notice("m34_stress_pause_requested paused=false cycle=2")
        case 8:
            if m34StressMinimizeEnabled {
                window.miniaturize(nil)
                logger.notice("m34_stress_minimize_requested")
            } else {
                engineHost.requestPresentationPaused(true)
                logger.notice("m34_stress_pause_requested paused=true cycle=3")
            }
        case 9:
            if m34StressMinimizeEnabled {
                window.deminiaturize(nil)
                logger.notice("m34_stress_restore_requested")
            } else {
                engineHost.requestPresentationPaused(false)
                logger.notice("m34_stress_pause_requested paused=false cycle=3")
            }
        case 10:
            logger.notice("m34_stress_post_resume_resize_requested index=\(step)")
        case 11:
            engineHost.requestPresentationPaused(true)
            logger.notice("m34_stress_pause_requested paused=true cycle=4")
        case 12:
            engineHost.requestPresentationPaused(false)
            logger.notice("m34_stress_pause_requested paused=false cycle=4")
        case 13:
            logger.notice("m34_stress_post_resume_resize_requested index=\(step)")
        default:
            break
        }
        m34StressStep = step + 1
        if m34StressStep >= 14 {
            timer.invalidate()
            m34StressTimer = nil
            if m34StressMinimizeEnabled, window.isMiniaturized {
                window.deminiaturize(nil)
                logger.notice("m34_stress_restore_requested final=true")
            }
            engineHost.requestPresentationPaused(false)
            logger.notice("m34_stress_finished")
        }
    }

    private func installM34StressWindowObservers(for window: NSWindow) {
        let center = NotificationCenter.default
        focusObservers.append(
            center.addObserver(
                forName: NSWindow.didMiniaturizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.m34StressTimer != nil else { return }
                    self.logger.notice("m34_stress_minimize_observed")
                    self.engineHost.requestPresentationPaused(true)
                }
            }
        )
        focusObservers.append(
            center.addObserver(
                forName: NSWindow.didDeminiaturizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.m34StressTimer != nil else { return }
                    self.logger.notice("m34_stress_restore_observed")
                    (self.view as? GameView)?.publishDrawableSize()
                    self.engineHost.requestPresentationPaused(false)
                }
            }
        )
    }

    private func installFocusObservers() {
        guard let window = view.window else { return }
        let center = NotificationCenter.default
        focusObservers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.setInputFocus(true)
            }
        })
        focusObservers.append(center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.setInputFocus(false)
            }
        })
        focusObservers.append(center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.setInputFocus(false)
            }
        })
        focusObservers.append(center.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                self.setInputFocus(window.isKeyWindow)
            }
        })
        setInputFocus(NSApplication.shared.isActive && window.isKeyWindow)
    }

    private func setInputFocus(_ focused: Bool) {
        inputService?.setFocused(focused)
    }
}
