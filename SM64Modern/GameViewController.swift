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
        installFocusObservers(service: inputService)
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
        for observer in focusObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func installFocusObservers(service: AppleInputService) {
        guard let window = view.window else { return }
        let center = NotificationCenter.default
        focusObservers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { _ in
            service.setFocused(true)
        })
        focusObservers.append(center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { _ in
            service.setFocused(false)
        })
        focusObservers.append(center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
            service.setFocused(false)
        })
        focusObservers.append(center.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                service.setFocused(window.isKeyWindow)
            }
        })
        service.setFocused(NSApplication.shared.isActive && window.isKeyWindow)
    }
}
