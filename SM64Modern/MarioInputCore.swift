import Foundation

struct SM64MarioInputFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    static let nonzeroAnalog = Self(rawValue: 0x0001)
    static let aPressed = Self(rawValue: 0x0002)
    static let offFloor = Self(rawValue: 0x0004)
    static let aboveSlide = Self(rawValue: 0x0008)
    static let firstPerson = Self(rawValue: 0x0010)
    static let unknown5 = Self(rawValue: 0x0020)
    static let squished = Self(rawValue: 0x0040)
    static let aDown = Self(rawValue: 0x0080)
    static let inPoisonGas = Self(rawValue: 0x0100)
    static let inWater = Self(rawValue: 0x0200)
    static let unknown10 = Self(rawValue: 0x0400)
    static let interactObjGrabbable = Self(rawValue: 0x0800)
    static let unknown12 = Self(rawValue: 0x1000)
    static let bPressed = Self(rawValue: 0x2000)
    static let zDown = Self(rawValue: 0x4000)
    static let zPressed = Self(rawValue: 0x8000)
}

struct SM64MarioInputState: Equatable, Sendable {
    var input: SM64MarioInputFlags
    var intendedMagnitude: Float
    var intendedYaw: Int16
    var framesSinceA: UInt8
    var framesSinceB: UInt8
}

/// Button and joystick portion of `update_mario_inputs`. Geometry flags are
/// supplied by the collision domain so this value type does not reach through
/// a mutable surface/object graph.
enum SM64MarioInputCore {
    static func update(
        controller: SM64ControllerState,
        squishTimer: Int32,
        previousFramesSinceA: UInt8,
        previousFramesSinceB: UInt8,
        faceYaw: Int16,
        cameraYaw: Int16,
        firstPerson: Bool = false,
        interactionUnknown10: Bool = false,
        geometryFlags: SM64MarioInputFlags = []
    ) -> SM64MarioInputState {
        var input = SM64MarioInputFlags()
        if controller.buttonPressed & 0x8000 != 0 { input.insert(.aPressed) }
        if controller.buttonDown & 0x8000 != 0 { input.insert(.aDown) }
        if squishTimer == 0 {
            if controller.buttonPressed & 0x4000 != 0 { input.insert(.bPressed) }
            if controller.buttonDown & 0x2000 != 0 { input.insert(.zDown) }
            if controller.buttonPressed & 0x2000 != 0 { input.insert(.zPressed) }
        }

        var framesSinceA = previousFramesSinceA
        if input.contains(.aPressed) { framesSinceA = 0 }
        else if framesSinceA < UInt8.max { framesSinceA &+= 1 }
        var framesSinceB = previousFramesSinceB
        if input.contains(.bPressed) { framesSinceB = 0 }
        else if framesSinceB < UInt8.max { framesSinceB &+= 1 }

        let normalizedMagnitude = controller.stickMagnitude / 64
        let magnitude = (normalizedMagnitude * normalizedMagnitude) * 64
        let intendedMagnitude = squishTimer == 0 ? magnitude / 2 : magnitude / 8
        let intendedYaw: Int16
        if intendedMagnitude > 0 {
            let stickYaw = SM64CanonicalTrig.atan2s(y: -controller.stickY, x: controller.stickX)
            intendedYaw = Int16(truncatingIfNeeded: Int32(stickYaw) + Int32(cameraYaw))
            input.insert(.nonzeroAnalog)
        } else {
            intendedYaw = faceYaw
        }

        input.formUnion(geometryFlags)
        if firstPerson { input.insert(.firstPerson) }
        if interactionUnknown10 { input.insert(.unknown10) }
        if !input.contains(.nonzeroAnalog) && !input.contains(.aPressed) {
            input.insert(.unknown5)
        }

        return SM64MarioInputState(
            input: input,
            intendedMagnitude: intendedMagnitude,
            intendedYaw: intendedYaw,
            framesSinceA: framesSinceA,
            framesSinceB: framesSinceB
        )
    }
}
