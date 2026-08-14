import Foundation

struct SM64ControllerRawSample: Equatable, Sendable {
    var connected: Bool
    var buttons: UInt16
    var rawStickX: Int16
    var rawStickY: Int16
    var extStickX: Int16
    var extStickY: Int16

    init(
        connected: Bool = true,
        buttons: UInt16 = 0,
        rawStickX: Int16 = 0,
        rawStickY: Int16 = 0,
        extStickX: Int16 = 0,
        extStickY: Int16 = 0
    ) {
        self.connected = connected
        self.buttons = buttons
        self.rawStickX = rawStickX
        self.rawStickY = rawStickY
        self.extStickX = extStickX
        self.extStickY = extStickY
    }
}

struct SM64ControllerState: Equatable, Sendable {
    let rawStickX: Int16
    let rawStickY: Int16
    let extStickX: Int16
    let extStickY: Int16
    let stickX: Float
    let stickY: Float
    let stickMagnitude: Float
    let buttonDown: UInt16
    let buttonPressed: UInt16

    static let disconnected = SM64ControllerState(
        rawStickX: 0,
        rawStickY: 0,
        extStickX: 0,
        extStickY: 0,
        stickX: 0,
        stickY: 0,
        stickMagnitude: 0,
        buttonDown: 0,
        buttonPressed: 0
    )
}

/// Swift counterpart of `read_controller_inputs` and `adjust_analog_stick`.
/// The pending edge buffer belongs to the owner-thread simulation state so a
/// held native step cannot replay a logical button edge.
struct SM64ControllerInputNormalizer: Equatable, Sendable {
    static let validButtons: UInt16 = 0xFF3F
    private(set) var pendingButtonPresses: UInt16 = 0
    private(set) var previousButtonDown: UInt16 = 0

    mutating func update(
        _ sample: SM64ControllerRawSample,
        advanceLegacyDomain: Bool
    ) -> SM64ControllerState {
        guard sample.connected else {
            pendingButtonPresses = 0
            previousButtonDown = 0
            return .disconnected
        }

        let buttons = sample.buttons & Self.validButtons
        pendingButtonPresses |= buttons & (buttons ^ previousButtonDown)
        previousButtonDown = buttons

        let buttonPressed: UInt16
        if advanceLegacyDomain {
            buttonPressed = pendingButtonPresses
            pendingButtonPresses = 0
        } else {
            buttonPressed = 0
        }

        let adjusted = Self.adjustAnalogStick(rawX: sample.rawStickX, rawY: sample.rawStickY)
        return SM64ControllerState(
            rawStickX: sample.rawStickX,
            rawStickY: sample.rawStickY,
            extStickX: sample.extStickX,
            extStickY: sample.extStickY,
            stickX: adjusted.x,
            stickY: adjusted.y,
            stickMagnitude: adjusted.magnitude,
            buttonDown: buttons,
            buttonPressed: buttonPressed
        )
    }

    private static func adjustAnalogStick(rawX: Int16, rawY: Int16) -> (
        x: Float,
        y: Float,
        magnitude: Float
    ) {
        var x: Float = 0
        var y: Float = 0
        if rawX <= -8 { x = Float(Int32(rawX) + 6) }
        if rawX >= 8 { x = Float(Int32(rawX) - 6) }
        if rawY <= -8 { y = Float(Int32(rawY) + 6) }
        if rawY >= 8 { y = Float(Int32(rawY) - 6) }

        var magnitude = (x * x + y * y).squareRoot()
        if magnitude > 64 {
            let scale = 64 / magnitude
            x *= scale
            y *= scale
            magnitude = 64
        }
        return (x, y, magnitude)
    }
}
