import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let engineHost = EngineHost()
    private let logger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Application")
    private var window: NSWindow?
    private var backingObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = GameViewController(engineHost: engineHost)
        let style: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView,
        ]
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 720),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.title = "SM64 Modern"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .black
        window.minSize = NSSize(width: 640, height: 480)
        window.contentAspectRatio = NSSize(width: 4, height: 3)
        window.contentViewController = controller
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        backingObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeBackingPropertiesNotification,
            object: window,
            queue: .main
        ) { [weak controller] _ in
            MainActor.assumeIsolated {
                (controller?.view as? GameView)?.publishDrawableSize()
            }
        }

        setupMenus()
        NSApplication.shared.activate(ignoringOtherApps: true)
        logger.notice("application_ready bundle=io.github.deestiz.sm64modern")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        engineHost.requestStopAndWait(reason: SM64_MODERN_EXIT_USER_REQUESTED)
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        engineHost.requestStopAndWait(reason: SM64_MODERN_EXIT_PLATFORM_REQUESTED)
        if let backingObserver {
            NotificationCenter.default.removeObserver(backingObserver)
        }
        logger.notice("application_stopped")
    }

    private func setupMenus() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About SM64 Modern", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit SM64 Modern", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        let fullscreen = windowMenu.addItem(
            withTitle: "Toggle Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        )
        fullscreen.keyEquivalentModifierMask = [.command, .control]
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)

        NSApplication.shared.mainMenu = mainMenu
        NSApplication.shared.windowsMenu = windowMenu
    }
}
