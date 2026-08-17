import AppKit
import CoreHaptics
import Foundation
import GameController
import os

private let inputLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Input")
private let hapticLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Haptics")
// These bases are the persisted legacy configuration namespace declared by
// VK_BASE_SDL_GAMEPAD and VK_BASE_SDL_MOUSE in the portable controller backend.
private let gamepadVirtualKeyBase: UInt32 = 0x1000
private let mouseVirtualKeyBase: UInt32 = 0x1100

private func appleInputService(from context: UnsafeMutableRawPointer?) -> AppleInputService? {
    guard let context else { return nil }
    return Unmanaged<AppleInputService>.fromOpaque(context).takeUnretainedValue()
}

private func inputRead(
    _ context: UnsafeMutableRawPointer?,
    _ outSnapshot: UnsafeMutablePointer<SM64ModernInputSnapshotV1>?
) -> SM64ModernStatus {
    guard let service = appleInputService(from: context), let outSnapshot else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.read(into: outSnapshot)
}

// These private callbacks keep haptics on the same copied-POD boundary as
// input. The C core resolves them weakly so standalone smoke binaries do not
// need CoreHaptics, while the signed app routes rumble to GameController.
@_cdecl("sm64_modern_input_rumble_play")
func sm64ModernInputRumblePlay(
    _ context: UnsafeMutableRawPointer?,
    _ strength: Float,
    _ duration: Float
) {
    appleInputService(from: context)?.playRumble(strength: strength, duration: duration)
}

@_cdecl("sm64_modern_input_rumble_stop")
func sm64ModernInputRumbleStop(_ context: UnsafeMutableRawPointer?) {
    appleInputService(from: context)?.stopRumble()
}

func makeAppleInputAPI(service: AppleInputService) -> SM64ModernInputApiV1 {
    var api = SM64ModernInputApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernInputApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.read = inputRead
    return api
}

/// Lock-protected bridge between main-queue AppKit/GameController callbacks and
/// owner-thread input sampling. The service itself is not Sendable; only its
/// copied POD snapshot crosses the C callback boundary, and haptic state has a
/// separate lock.
final class AppleInputService {
    private struct ControllerState {
        var buttons: UInt32 = 0
        var leftX: Int16 = 0
        var leftY: Int16 = 0
        var rightX: Int16 = 0
        var rightY: Int16 = 0

        var isActive: Bool {
            buttons != 0 || leftX != 0 || leftY != 0 || rightX != 0 || rightY != 0
        }
    }

    private let lock = NSLock()
    private let automatedMenuInput = ProcessInfo.processInfo.environment["SM64_MODERN_AUTOMATED_MENU"] != nil
    private let automatedGameplayInput = ProcessInfo.processInfo.environment["SM64_MODERN_AUTOMATED_GAMEPLAY"] != nil
    private var automatedMenuReadCount: UInt32 = 0
    // The front-end observer is fed from the same owner-thread read that
    // produces the legacy C snapshot. It is intentionally independent of the
    // C input ABI's lifetime and is only a monotonic boundary timestamp.
    private var frontendSimulationTick: UInt64 = 0
    private let hapticLock = NSLock()
    private var keyboardWords = [UInt32](repeating: 0, count: Int(SM64_MODERN_INPUT_KEYBOARD_WORD_COUNT))
    private var pendingKeyboardPressWords = [UInt32](
        repeating: 0,
        count: Int(SM64_MODERN_INPUT_KEYBOARD_WORD_COUNT)
    )
    private var mouseButtons: UInt32 = 0
    private var pendingMousePresses: UInt32 = 0
    private var pendingRawKey = SM64_MODERN_INPUT_NO_KEY
    private var lastControllerButtons: UInt32 = 0
    private var focused = true
    private var loggedKeyboardActivity = false
    private var loggedMouseActivity = false
    private var loggedControllerActivity = false
    private var loggedBufferedControllerActivity = false
    private var loggedSnapshotRead = false
    private var hapticEngines: [ObjectIdentifier: CHHapticEngine] = [:]
    private var hapticPlayers: [ObjectIdentifier: CHHapticPatternPlayer] = [:]
    private var currentControllerID: ObjectIdentifier?
    private var loggedHapticsUnavailable = false
    private var observers: [NSObjectProtocol] = []

    init() {
        precondition(Thread.isMainThread, "AppKit input must be installed on the main thread")
        for controller in GCController.controllers() {
            configure(controller)
        }
        if let current = GCController.current {
            setCurrentController(current)
        }
        let center = NotificationCenter.default
        let contextAddress = UInt(bitPattern: Unmanaged.passUnretained(self).toOpaque())
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { note in
            guard let context = UnsafeMutableRawPointer(bitPattern: contextAddress) else { return }
            let service = Unmanaged<AppleInputService>.fromOpaque(context).takeUnretainedValue()
            let controller = note.object as? GCController
            if let controller { service.configure(controller) }
            let name = controller?.vendorName ?? "unknown"
            inputLogger.notice("controller_connected name=\(name, privacy: .public)")
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { note in
            guard let context = UnsafeMutableRawPointer(bitPattern: contextAddress) else { return }
            let service = Unmanaged<AppleInputService>.fromOpaque(context).takeUnretainedValue()
            let controller = note.object as? GCController
            if let controller { service.disconnect(controller) }
            let name = controller?.vendorName ?? "unknown"
            inputLogger.notice("controller_disconnected name=\(name, privacy: .public)")
        })
        observers.append(center.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: .main) { note in
            guard let context = UnsafeMutableRawPointer(bitPattern: contextAddress) else { return }
            let service = Unmanaged<AppleInputService>.fromOpaque(context).takeUnretainedValue()
            let controller = note.object as? GCController
            if let controller { service.setCurrentController(controller) }
            let name = controller?.vendorName ?? "unknown"
            inputLogger.notice("controller_current name=\(name, privacy: .public)")
        })
        inputLogger.notice("input_service_ready controllers=\(GCController.controllers().count)")
        if automatedMenuInput {
            inputLogger.notice("automated_menu_input_enabled")
        }
        if automatedGameplayInput {
            inputLogger.notice("automated_gameplay_input_enabled")
        }
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        hapticLock.lock()
        let engines = Array(hapticEngines.values)
        let players = Array(hapticPlayers.values)
        hapticEngines.removeAll()
        hapticPlayers.removeAll()
        hapticLock.unlock()
        for player in players { try? player.stop(atTime: CHHapticTimeImmediate) }
        for engine in engines { engine.stop() }
    }

    func setFocused(_ value: Bool) {
        lock.lock()
        let changed = focused != value
        focused = value
        if !value {
            keyboardWords = [UInt32](repeating: 0, count: keyboardWords.count)
            pendingKeyboardPressWords = [UInt32](repeating: 0, count: pendingKeyboardPressWords.count)
            mouseButtons = 0
            pendingMousePresses = 0
            pendingRawKey = SM64_MODERN_INPUT_NO_KEY
            lastControllerButtons = 0
        }
        lock.unlock()
        if !value {
            stopRumble()
        }
        if changed {
            inputLogger.notice("input_focus active=\(value)")
        }
    }

    func keyChanged(appKitKeyCode: UInt16, pressed: Bool, isRepeat: Bool = false) {
        guard let virtualKey = Self.virtualKey(for: appKitKeyCode) else { return }
        lock.lock()
        let word = Int(virtualKey / 32)
        precondition(word < keyboardWords.count, "Mapped key must fit the input snapshot")
        let mask = UInt32(1) << (virtualKey % 32)
        let wasPressed = (keyboardWords[word] & mask) != 0
        if pressed {
            keyboardWords[word] |= mask
            if !wasPressed && !isRepeat {
                pendingKeyboardPressWords[word] |= mask
                pendingRawKey = virtualKey
            }
        } else {
            keyboardWords[word] &= ~mask
        }
        let shouldLog = pressed && !wasPressed && !loggedKeyboardActivity
        if shouldLog { loggedKeyboardActivity = true }
        lock.unlock()
        if shouldLog {
            inputLogger.notice("keyboard_input_detected virtual_key=\(virtualKey)")
        }
    }

    func modifierChanged(appKitKeyCode: UInt16, flags: NSEvent.ModifierFlags) {
        let pressed: Bool
        let deviceFlags = flags.rawValue
        switch appKitKeyCode {
        // The low device-dependent bits distinguish left/right modifiers.
        // Using only AppKit's aggregate flags leaves one side stuck when both
        // physical keys are held and then released independently.
        case 54: pressed = deviceFlags & 0x0000_0010 != 0 // right command
        case 55: pressed = deviceFlags & 0x0000_0008 != 0 // left command
        case 56: pressed = deviceFlags & 0x0000_0002 != 0 // left shift
        case 57: pressed = flags.contains(.capsLock)
        case 58: pressed = deviceFlags & 0x0000_0020 != 0 // left option
        case 59: pressed = deviceFlags & 0x0000_0001 != 0 // left control
        case 60: pressed = deviceFlags & 0x0000_0004 != 0 // right shift
        case 61: pressed = deviceFlags & 0x0000_0040 != 0 // right option
        case 62: pressed = deviceFlags & 0x0000_2000 != 0 // right control
        default: return
        }
        keyChanged(appKitKeyCode: appKitKeyCode, pressed: pressed)
    }

    func mouseButtonChanged(appKitButton: Int, pressed: Bool) {
        guard let button = Self.sdlMouseButton(for: appKitButton) else { return }
        let mask = UInt32(1) << button
        lock.lock()
        let wasPressed = (mouseButtons & mask) != 0
        if pressed {
            mouseButtons |= mask
            if !wasPressed {
                pendingMousePresses |= mask
                pendingRawKey = mouseVirtualKeyBase + button
            }
        } else {
            mouseButtons &= ~mask
        }
        let shouldLog = pressed && !wasPressed && !loggedMouseActivity
        if shouldLog { loggedMouseActivity = true }
        lock.unlock()
        if shouldLog {
            inputLogger.notice("mouse_button_input_detected button=\(button)")
        }
    }

    fileprivate func read(into outSnapshot: UnsafeMutablePointer<SM64ModernInputSnapshotV1>) -> SM64ModernStatus {
        let controllerCapture = Self.captureCurrentController()
        let controllerState = controllerCapture.state

        lock.lock()
        let isFocused = focused
        let pendingKeys = pendingKeyboardPressWords
        let pendingMouseButtons = pendingMousePresses
        var keys = isFocused
            ? zip(keyboardWords, pendingKeyboardPressWords).map { $0 | $1 }
            : [UInt32](repeating: 0, count: keyboardWords.count)
        let mouse = isFocused ? mouseButtons | pendingMousePresses : 0
        let gamepad = isFocused ? controllerState : ControllerState()
        var automatedGamepadButtons = gamepad.buttons
        pendingKeyboardPressWords = [UInt32](repeating: 0, count: pendingKeyboardPressWords.count)
        pendingMousePresses = 0
        let risingButtons = gamepad.buttons & ~lastControllerButtons
        lastControllerButtons = gamepad.buttons
        var rawKey = pendingRawKey
        pendingRawKey = SM64_MODERN_INPUT_NO_KEY
        if rawKey == SM64_MODERN_INPUT_NO_KEY, risingButtons != 0 {
            rawKey = gamepadVirtualKeyBase + UInt32(risingButtons.trailingZeroBitCount)
        }
        var automatedVirtualKey: UInt32?
        if automatedMenuInput {
            // The milestone harness is intentionally opt-in and emits a
            // bounded Start/A sequence using the persisted default keyboard
            // scan codes. It lets a headless run reach Mario actions without
            // posting GUI events or changing normal input behavior.
            let read = automatedMenuReadCount
            automatedMenuReadCount &+= 1
            let virtualKey: UInt32?
            let isAutomatedStartPulse = (read >= 8 && read < 16)
                || (read >= 40 && read < 48)
                || (read >= 88 && read < 96)
                || (read >= 136 && read < 144)
                || (read >= 184 && read < 192)
                || (read >= 232 && read < 240)
                || (read >= 280 && read < 288)
                || (read >= 328 && read < 336)
            if isAutomatedStartPulse {
                virtualKey = 0x39 // Space / Start
                automatedGamepadButtons |= UInt32(1) << 6 // SDL menu / Start
            } else if (read >= 72 && read < 80)
                        || (read >= 144 && read < 152)
                        || (read >= 216 && read < 224)
                        || (read >= 288 && read < 296) {
                virtualKey = 0x26 // A in the native default keyboard map
                automatedGamepadButtons |= UInt32(1) // SDL A
            } else {
                virtualKey = nil
            }
            automatedVirtualKey = virtualKey
            if let virtualKey {
                let word = Int(virtualKey / 32)
                if word < keys.count {
                    keys[word] |= UInt32(1) << (virtualKey % 32)
                }
            }
        } else {
            automatedVirtualKey = nil
        }
        let automatedLeftStickX: Int16 = automatedGameplayInput ? 16_000 : gamepad.leftX
        let automatedLeftStickY: Int16 = automatedGameplayInput ? 0 : gamepad.leftY
        let shouldLogController = gamepad.isActive && !loggedControllerActivity
        if shouldLogController { loggedControllerActivity = true }
        let shouldLogBufferedController = isFocused
            && controllerCapture.recoveredButtons != 0
            && !loggedBufferedControllerActivity
        if shouldLogBufferedController { loggedBufferedControllerActivity = true }
        let shouldLogSnapshot = !loggedSnapshotRead
        if shouldLogSnapshot { loggedSnapshotRead = true }
        lock.unlock()

        if shouldLogSnapshot {
            inputLogger.notice("input_snapshot_started owner_main=\(Thread.isMainThread)")
        }
        if shouldLogController {
            inputLogger.notice("controller_input_detected buttons=0x\(gamepad.buttons, format: .hex)")
        }
        if shouldLogBufferedController {
            inputLogger.notice(
                "controller_buffered_press_recovered buttons=0x\(controllerCapture.recoveredButtons, format: .hex)"
            )
        }

        var snapshot = SM64ModernInputSnapshotV1()
        snapshot.header.abi_version = SM64_MODERN_ABI_VERSION_1
        snapshot.header.struct_size = UInt32(MemoryLayout<SM64ModernInputSnapshotV1>.size)
        withUnsafeMutableBytes(of: &snapshot.keyboard_keys) { destination in
            keys.withUnsafeBytes { source in destination.copyBytes(from: source) }
        }
        snapshot.gamepad_buttons = automatedGamepadButtons
        snapshot.mouse_buttons = mouse
        snapshot.left_stick_x = automatedLeftStickX
        snapshot.left_stick_y = automatedLeftStickY
        snapshot.right_stick_x = gamepad.rightX
        snapshot.right_stick_y = gamepad.rightY
        snapshot.last_virtual_key = rawKey
        snapshot.reserved = 0
        outSnapshot.pointee = snapshot

        // M31z consumes this immutable edge from the same read boundary as C.
        // The callback is optional and therefore has no effect in C-only
        // compatibility binaries or before the Swift host installs it.
        frontendSimulationTick &+= 1
        func pendingKey(_ key: UInt32) -> Bool {
            let word = Int(key / 32)
            guard word < pendingKeys.count else { return false }
            return pendingKeys[word] & (UInt32(1) << (key % 32)) != 0
        }
        let pendingStart = pendingKey(0x39) || automatedVirtualKey == 0x39
        let pendingConfirm = pendingKey(0x26) || automatedVirtualKey == 0x26
        let pendingBack = pendingKey(0x25)
            || risingButtons & (UInt32(1) << 1) != 0
        let startPressed = pendingStart
            || risingButtons & (UInt32(1) << 6) != 0
        let confirmPressed = pendingConfirm
            || risingButtons & (UInt32(1) << 0) != 0
        let selectionDelta: Int16
        if automatedLeftStickY >= 16 {
            selectionDelta = 1
        } else if automatedLeftStickY <= -16 {
            selectionDelta = -1
        } else {
            selectionDelta = 0
        }
        let hasActivity = gamepad.isActive
            || keys.contains { $0 != 0 }
            || pendingMouseButtons != 0
        var frontEndInput = SM64ModernFrontEndInputV1()
        frontEndInput.header.abi_version = SM64_MODERN_ABI_VERSION_1
        frontEndInput.header.struct_size = UInt32(
            MemoryLayout<SM64ModernFrontEndInputV1>.size
        )
        frontEndInput.simulation_tick = frontendSimulationTick
        frontEndInput.advance_legacy_domain = 1
        frontEndInput.start_pressed = startPressed ? 1 : 0
        frontEndInput.confirm_pressed = confirmPressed ? 1 : 0
        frontEndInput.back_pressed = pendingBack ? 1 : 0
        frontEndInput.has_activity = hasActivity ? 1 : 0
        frontEndInput.debug_level_select = 0
        frontEndInput.demo_complete = 0
        frontEndInput.credits_complete = 0
        frontEndInput.ending_complete = 0
        frontEndInput.demo_count = 8
        frontEndInput.selection_delta = selectionDelta
        frontEndInput.reserved = 0
        var frontEndOutput = SM64ModernFrontEndOutputV1()
        let frontEndStatus = sm64_modern_frontend_evaluate(
            &frontEndInput, &frontEndOutput
        )
        guard frontEndStatus == SM64_MODERN_STATUS_OK else {
            return frontEndStatus
        }
        return SM64_MODERN_STATUS_OK
    }

    private func configure(_ controller: GCController) {
        // The engine samples on every native 60 Hz step. Apple's default depth
        // of one can still discard a complete press/release pair between ticks,
        // so retain enough immutable input states for the owner thread to drain.
        controller.input.inputStateQueueDepth = 20

        let identifier = ObjectIdentifier(controller)
        guard let haptics = controller.haptics else {
            hapticLogger.notice(
                "controller_haptics_unavailable name=\(controller.vendorName ?? "unknown", privacy: .public)"
            )
            return
        }
        // Prefer the handle locality when available, then follow Apple's
        // required default-locality fallback. A nil engine is supported when
        // the user has disabled controller haptics.
        guard let engine = haptics.createEngine(withLocality: .handles)
            ?? haptics.createEngine(withLocality: .default) else {
            hapticLogger.notice(
                "controller_haptics_disabled name=\(controller.vendorName ?? "unknown", privacy: .public)"
            )
            return
        }
        engine.resetHandler = {
            hapticLogger.notice("controller_haptics_reset")
        }
        engine.stoppedHandler = { reason in
            // Core Haptics may auto-stop an engine after its idle window or
            // after a device interruption. playRumble() synchronously starts
            // the retained engine before every new pattern.
            hapticLogger.notice(
                "controller_haptics_stopped reason=\(String(describing: reason), privacy: .public)"
            )
        }
        hapticLock.lock()
        hapticEngines[identifier] = engine
        if currentControllerID == nil {
            currentControllerID = identifier
        }
        hapticLock.unlock()
        hapticLogger.notice(
            "controller_haptics_ready name=\(controller.vendorName ?? "unknown", privacy: .public)"
        )
    }

    private func setCurrentController(_ controller: GCController) {
        hapticLock.lock()
        currentControllerID = ObjectIdentifier(controller)
        hapticLock.unlock()
    }

    private func disconnect(_ controller: GCController) {
        let identifier = ObjectIdentifier(controller)
        hapticLock.lock()
        let engine = hapticEngines.removeValue(forKey: identifier)
        let player = hapticPlayers.removeValue(forKey: identifier)
        if currentControllerID == identifier {
            currentControllerID = nil
        }
        hapticLock.unlock()
        try? player?.stop(atTime: CHHapticTimeImmediate)
        engine?.stop()
    }

    fileprivate func playRumble(strength: Float, duration: Float) {
        let intensity = strength.clamped(to: 0 ... 1)
        let eventDuration = TimeInterval(duration.clamped(to: 0.01 ... 5.0))
        hapticLock.lock()
        guard let identifier = currentControllerID, let engine = hapticEngines[identifier] else {
            let shouldLog = !loggedHapticsUnavailable
            loggedHapticsUnavailable = true
            hapticLock.unlock()
            if shouldLog { hapticLogger.notice("rumble_unavailable") }
            return
        }
        let previousPlayer = hapticPlayers.removeValue(forKey: identifier)
        hapticLock.unlock()

        try? previousPlayer?.stop(atTime: CHHapticTimeImmediate)
        do {
            try engine.start()
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                ],
                relativeTime: 0,
                duration: eventDuration
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            hapticLock.lock()
            hapticPlayers[identifier] = player
            hapticLock.unlock()
        } catch {
            hapticLogger.error(
                "rumble_start_failed error=\(error.localizedDescription, privacy: .public)"
            )
        }
    }

    fileprivate func stopRumble() {
        hapticLock.lock()
        guard let identifier = currentControllerID,
              let player = hapticPlayers.removeValue(forKey: identifier) else {
            hapticLock.unlock()
            return
        }
        hapticLock.unlock()
        try? player.stop(atTime: CHHapticTimeImmediate)
    }

    private static func captureCurrentController() -> (state: ControllerState, recoveredButtons: UInt32) {
        guard let input = GCController.current?.input else { return (ControllerState(), 0) }
        let liveState = controllerState(from: input.capture())
        var bufferedButtons: UInt32 = 0
        while let bufferedState = input.nextInputState() {
            bufferedButtons |= controllerButtons(from: bufferedState)
        }
        var state = liveState
        state.buttons |= bufferedButtons
        return (state, bufferedButtons & ~liveState.buttons)
    }

    private static func controllerState(from input: GCControllerInputState) -> ControllerState {
        var state = ControllerState()
        state.buttons = controllerButtons(from: input)

        if let left = input.dpads[.leftThumbstick]?.xyAxes.value {
            state.leftX = fixedAxis(left.x)
            state.leftY = fixedAxis(left.y)
        }
        if let right = input.dpads[.rightThumbstick]?.xyAxes.value {
            state.rightX = fixedAxis(right.x)
            state.rightY = fixedAxis(right.y)
        }
        return state
    }

    private static func controllerButtons(from input: GCControllerInputState) -> UInt32 {
        var buttons: UInt32 = 0
        // Indices mirror SDL_GameControllerButton so existing 0x1000-based
        // bindings retain their meaning. Triggers retain SDL's synthetic 26/27.
        func record(_ index: UInt32, _ pressed: Bool) {
            if pressed { buttons |= UInt32(1) << index }
        }
        record(0, input.buttons[.a]?.pressedInput.isPressed == true)
        record(1, input.buttons[.b]?.pressedInput.isPressed == true)
        record(2, input.buttons[.x]?.pressedInput.isPressed == true)
        record(3, input.buttons[.y]?.pressedInput.isPressed == true)
        record(4, input.buttons[.options]?.pressedInput.isPressed == true)
        record(5, input.buttons[.home]?.pressedInput.isPressed == true)
        record(6, input.buttons[.menu]?.pressedInput.isPressed == true)
        record(7, input.buttons[.leftThumbstickButton]?.pressedInput.isPressed == true)
        record(8, input.buttons[.rightThumbstickButton]?.pressedInput.isPressed == true)
        record(9, input.buttons[.leftShoulder]?.pressedInput.isPressed == true)
        record(10, input.buttons[.rightShoulder]?.pressedInput.isPressed == true)
        record(26, input.buttons[.leftTrigger]?.pressedInput.isPressed == true)
        record(27, input.buttons[.rightTrigger]?.pressedInput.isPressed == true)
        if let dpad = input.dpads[.directionPad] {
            record(11, dpad.up.isPressed)
            record(12, dpad.down.isPressed)
            record(13, dpad.left.isPressed)
            record(14, dpad.right.isPressed)
        }
        return buttons
    }

    private static func fixedAxis(_ value: Float) -> Int16 {
        let normalized = value.clamped(to: -1 ... 1)
        let scale = normalized < 0 ? -Float(Int16.min) : Float(Int16.max)
        return Int16((normalized * scale).rounded())
    }

    private static func sdlMouseButton(for appKitButton: Int) -> UInt32? {
        switch appKitButton {
        case 0: 1 // left
        case 1: 3 // right
        case 2: 2 // middle
        case 3: 4
        case 4: 5
        default: nil
        }
    }

    // AppKit reports hardware positions. Translate them to the Windows Set 1
    // scancode namespace already persisted by the legacy configuration file.
    private static func virtualKey(for code: UInt16) -> UInt32? {
        keyCodeMap[code]
    }

    private static let keyCodeMap: [UInt16: UInt32] = [
        0: 0x1E, 1: 0x1F, 2: 0x20, 3: 0x21, 4: 0x23, 5: 0x22,
        6: 0x2C, 7: 0x2D, 8: 0x2E, 9: 0x2F, 11: 0x30, 12: 0x10,
        13: 0x11, 14: 0x12, 15: 0x13, 16: 0x15, 17: 0x14, 18: 0x02,
        19: 0x03, 20: 0x04, 21: 0x05, 22: 0x07, 23: 0x06, 24: 0x0D,
        25: 0x0A, 26: 0x08, 27: 0x0C, 28: 0x09, 29: 0x0B, 30: 0x1B,
        31: 0x18, 32: 0x16, 33: 0x1A, 34: 0x17, 35: 0x19, 36: 0x1C,
        37: 0x26, 38: 0x24, 39: 0x28, 40: 0x25, 41: 0x27, 42: 0x2B,
        43: 0x33, 44: 0x35, 45: 0x31, 46: 0x32, 47: 0x34, 48: 0x0F,
        49: 0x39, 50: 0x29, 51: 0x0E, 53: 0x01, 54: 0x15C, 55: 0x15B,
        56: 0x2A, 57: 0x3A, 58: 0x38, 59: 0x1D, 60: 0x36, 61: 0x138,
        62: 0x11D, 64: 0x68, 65: 0x53, 67: 0x37, 69: 0x4E, 71: 0x45,
        75: 0x135, 76: 0x11C, 78: 0x4A, 79: 0x69, 80: 0x6A, 81: 0x0D,
        82: 0x52, 83: 0x4F, 84: 0x50, 85: 0x51, 86: 0x4B, 87: 0x4C,
        88: 0x4D, 89: 0x47, 91: 0x48, 92: 0x49, 96: 0x3F, 97: 0x40,
        98: 0x41, 99: 0x3D, 100: 0x42, 101: 0x43, 103: 0x57, 105: 0x64,
        106: 0x67, 107: 0x65, 109: 0x44, 111: 0x58, 113: 0x66, 114: 0x152,
        115: 0x147, 116: 0x149,
        117: 0x153, 118: 0x3E, 119: 0x14F, 120: 0x3C, 121: 0x151,
        122: 0x3B, 123: 0x14B, 124: 0x14D, 125: 0x150, 126: 0x148,
    ]
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
