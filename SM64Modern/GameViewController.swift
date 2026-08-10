import AppKit
import os

@MainActor
final class GameViewController: NSViewController {
    private let engineHost: EngineHost
    private let logger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Window")
    private var initialized = false

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
        gameView.updateDrawableSize()
        let size = gameView.metalLayer.drawableSize
        precondition(size.width > 0 && size.height > 0, "Engine startup requires a drawable-sized surface")
        logger.notice("window_ready layer=CAMetalLayer drawable=\(Int(size.width))x\(Int(size.height))")

        // STUB(M3): configure the Metal device and presentation loop here.
        // STUB(M5): install native keyboard, mouse, and controller routing
        // before the engine begins consuming input.
        // The C lifecycle starts last so AppKit owns a complete, measurable
        // surface before the dedicated thread begins stepping the game.
        engineHost.start()
    }
}
