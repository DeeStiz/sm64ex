import Foundation

struct SM64CameraInputState: Equatable, Sendable {
    let rightStickX: Int16
    let rightStickY: Int16
    let buttonDown: UInt16
    let buttonPressed: UInt16
}

/// C-button camera input synthesized by `controller_sm64_modern.c` from the
/// secondary stick. Edges use the same logical-boundary admission rule as the
/// primary controller normalizer, so a held native redraw cannot replay them.
struct SM64CameraInputNormalizer: Equatable, Sendable {
    static let leftButton: UInt16 = 0x0002
    static let downButton: UInt16 = 0x0004
    static let upButton: UInt16 = 0x0008
    static let rightButton: UInt16 = 0x0001
    static let cameraMask: UInt16 = 0x000F
    static let threshold: Int16 = 0x4000

    private(set) var pendingButtonPresses: UInt16 = 0
    private(set) var previousSynthesizedButtons: UInt16 = 0

    mutating func update(
        controller: SM64ControllerState,
        advanceLegacyDomain: Bool
    ) -> SM64CameraInputState {
        var synthesized: UInt16 = 0
        if controller.extStickX < Self.threshold.negated() { synthesized |= Self.leftButton }
        if controller.extStickX > Self.threshold { synthesized |= Self.rightButton }
        if controller.extStickY > Self.threshold { synthesized |= Self.upButton }
        if controller.extStickY < Self.threshold.negated() { synthesized |= Self.downButton }

        pendingButtonPresses |= synthesized & (synthesized ^ previousSynthesizedButtons)
        previousSynthesizedButtons = synthesized
        let pressedFromPhysical = controller.buttonPressed & Self.cameraMask
        let pressedFromStick: UInt16
        if advanceLegacyDomain {
            pressedFromStick = pendingButtonPresses
            pendingButtonPresses = 0
        } else {
            pressedFromStick = 0
        }
        return SM64CameraInputState(
            rightStickX: controller.extStickX,
            rightStickY: controller.extStickY,
            buttonDown: (controller.buttonDown & Self.cameraMask) | synthesized,
            buttonPressed: pressedFromPhysical | pressedFromStick
        )
    }
}

private extension Int16 {
    func negated() -> Int16 { Int16(truncatingIfNeeded: -Int32(self)) }
}
