import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let authoritySelection: SM64ModernEngineAuthoritySelection
    private let engineHost: EngineHost
    private let logger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Application")
    private var window: NSWindow?
    private var backingObserver: NSObjectProtocol?

    override init() {
        let selection = SM64ModernEngineAuthorityStore.resolve()
        authoritySelection = selection
        engineHost = EngineHost(authority: selection.authority)
        super.init()
        if selection.source == .persistedSetting, selection.invalidValue != nil {
            SM64ModernEngineAuthorityStore.persist(selection.authority)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !authoritySelection.requiresLaunchFailure else {
            let invalidValue = authoritySelection.invalidValue ?? "<missing>"
            logger.error(
                "engine_authority_invalid value=\(invalidValue, privacy: .public) source=\(self.authoritySelection.source.rawValue, privacy: .public)"
            )
            showEngineAuthorityError(invalidValue: invalidValue)
            NSApplication.shared.terminate(nil)
            return
        }
        if let invalidValue = authoritySelection.invalidValue {
            logger.warning(
                "engine_authority_persisted_value_repaired value=\(invalidValue, privacy: .public) fallback=swift"
            )
        }
        logger.notice(
            "engine_authority_selected authority=\(self.authoritySelection.authority.rawValue, privacy: .public) source=\(self.authoritySelection.source.rawValue, privacy: .public)"
        )

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

        let advancedItem = NSMenuItem()
        let advancedMenu = NSMenu(title: "Advanced")
        let authorityItem = NSMenuItem(title: "Engine Authority", action: nil, keyEquivalent: "")
        let authorityMenu = NSMenu(title: "Engine Authority")
        for authority in SM64ModernEngineAuthority.allCases {
            let item = NSMenuItem(
                title: authority.displayName,
                action: #selector(selectEngineAuthority(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = authority.rawValue
            item.toolTip = authority.menuDescription
            item.state = authority == authoritySelection.authority ? .on : .off
            authorityMenu.addItem(item)
        }
        authorityItem.submenu = authorityMenu
        advancedMenu.addItem(authorityItem)
        advancedItem.submenu = advancedMenu
        mainMenu.addItem(advancedItem)

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

    @objc private func selectEngineAuthority(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let authority = SM64ModernEngineAuthority(rawValue: rawValue) else {
            logger.error("engine_authority_menu_invalid_value")
            return
        }

        SM64ModernEngineAuthorityStore.persist(authority)
        sender.menu?.items.forEach { item in
            item.state = item === sender ? .on : .off
        }
        logger.notice("engine_authority_persisted authority=\(authority.rawValue, privacy: .public)")

        if authoritySelection.source == .environmentOverride {
            showEngineAuthorityRestartNotice(
                message: "The SM64_MODERN_ENGINE environment override is active. Remove it before restarting for the saved authority to take effect."
            )
        } else if SM64ModernEngineAuthoritySelection.requiresRestart(
            selectedAuthority: authority,
            activeAuthority: authoritySelection.authority
        ) {
            showEngineAuthorityRestartNotice(
                message: "Engine authority saved as \(authority.displayName). Restart SM64 Modern to apply it."
            )
        }
    }

    private func showEngineAuthorityError(invalidValue: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Invalid engine authority"
        alert.informativeText = "SM64_MODERN_ENGINE or the saved engine setting contains \"\(invalidValue)\". Choose \"swift\" or \"c\", then relaunch."
        alert.addButton(withTitle: "Quit")
        alert.runModal()
    }

    private func showEngineAuthorityRestartNotice(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Engine authority changed"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
