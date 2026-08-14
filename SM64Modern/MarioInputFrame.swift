import Foundation

struct SM64DemoInputState: Equatable, Sendable {
    var timer: UInt8
    var buttonMask: UInt8
    var rawStickX: Int16
    var rawStickY: Int16
}

struct SM64DemoInputOverlayResult: Equatable, Sendable {
    let sample: SM64ControllerRawSample
    let nextState: SM64DemoInputState
    let didEnd: Bool
}

/// Pure counterpart of `run_demo_inputs`. The demo byte stores A/B/Z/Start in
/// its upper nibble and the four C buttons in its lower nibble. The live Start
/// bit is retained so a user can terminate a demo while it is playing.
enum SM64DemoInputOverlay {
    static let startButton: UInt16 = 0x1000
    static let endDemoButton: UInt16 = 0x0080

    static func apply(
        sample: SM64ControllerRawSample,
        state: SM64DemoInputState,
        advanceLegacyDomain: Bool
    ) -> SM64DemoInputOverlayResult {
        let startButton = sample.buttons & Self.startButton
        if state.timer == 0 {
            return SM64DemoInputOverlayResult(
                sample: SM64ControllerRawSample(
                    connected: true,
                    buttons: Self.endDemoButton | startButton,
                    rawStickX: 0,
                    rawStickY: 0,
                    extStickX: sample.extStickX,
                    extStickY: sample.extStickY
                ),
                nextState: state,
                didEnd: true
            )
        }

        let demoButtons = (UInt16(state.buttonMask & 0xF0) << 8)
            | UInt16(state.buttonMask & 0x0F)
            | startButton
        var nextState = state
        if advanceLegacyDomain { nextState.timer &-= 1 }
        return SM64DemoInputOverlayResult(
            sample: SM64ControllerRawSample(
                connected: true,
                buttons: demoButtons,
                rawStickX: state.rawStickX,
                rawStickY: state.rawStickY,
                extStickX: sample.extStickX,
                extStickY: sample.extStickY
            ),
            nextState: nextState,
            didEnd: false
        )
    }
}

struct SM64RumbleRequest: Equatable, Sendable {
    let strength: Float
    let duration: Float
}

/// The portable controller backend rejects haptic calls on held native redraw
/// steps. This value boundary keeps that admission rule with the input frame;
/// the platform service remains responsible for delivering the admitted event.
enum SM64RumbleBoundary {
    static func admitted(
        _ request: SM64RumbleRequest?,
        focused: Bool,
        advanceLegacyDomain: Bool
    ) -> SM64RumbleRequest? {
        guard focused, advanceLegacyDomain, let request else { return nil }
        guard request.strength.isFinite, request.duration.isFinite else { return nil }
        return request
    }
}

struct SM64MarioInputFrame: Equatable, Sendable {
    let simulationTick: UInt64
    let focused: Bool
    let demoEnded: Bool
    let demoTimer: UInt8?
    let controller: SM64ControllerState
    let mario: SM64MarioInputState
    let geometry: SM64MarioGeometryInputResult
    let rumbleRequest: SM64RumbleRequest?
}

struct SM64MarioInputFrameResult: Equatable, Sendable {
    let frame: SM64MarioInputFrame
    let nextDemoState: SM64DemoInputState?
}

/// Owner-thread composition boundary for one logical Mario input sample.
/// Focus, demo replacement, controller edge admission, collision-derived
/// geometry, Mario button/joystick derivation, and rumble admission are all
/// explicit values so the live Swift runtime can replace C piecemeal.
enum SM64MarioInputFrameComposer {
    static func update(
        normalizer: inout SM64ControllerInputNormalizer,
        simulationTick: UInt64,
        sample: SM64ControllerRawSample,
        focused: Bool,
        advanceLegacyDomain: Bool,
        demoState: SM64DemoInputState? = nil,
        rumbleRequest: SM64RumbleRequest? = nil,
        position: SM64ObjectVector3,
        graphicsPosition: SM64ObjectVector3,
        world: SM64SurfaceCollisionWorld,
        terrainType: UInt16 = 0,
        isLavaLevel: Bool = false,
        isCrawling: Bool = false,
        squishTimer: Int32,
        previousFramesSinceA: UInt8,
        previousFramesSinceB: UInt8,
        faceYaw: Int16,
        cameraYaw: Int16,
        firstPerson: Bool = false,
        interactionUnknown10: Bool = false
    ) -> SM64MarioInputFrameResult {
        let focusedSample = focused ? sample : SM64ControllerRawSample(connected: false)
        let overlay = demoState.map {
            SM64DemoInputOverlay.apply(
                sample: focusedSample,
                state: $0,
                advanceLegacyDomain: advanceLegacyDomain
            )
        }
        var controller = normalizer.update(
            overlay?.sample ?? focusedSample,
            advanceLegacyDomain: advanceLegacyDomain
        )
        if overlay?.didEnd == true {
            // END_DEMO is intentionally outside VALID_BUTTONS because a real
            // controller cannot press it. The legacy demo path injects it
            // after that mask and level_update consumes the sentinel.
            controller = SM64ControllerState(
                rawStickX: controller.rawStickX,
                rawStickY: controller.rawStickY,
                extStickX: controller.extStickX,
                extStickY: controller.extStickY,
                stickX: controller.stickX,
                stickY: controller.stickY,
                stickMagnitude: controller.stickMagnitude,
                buttonDown: controller.buttonDown | SM64DemoInputOverlay.endDemoButton,
                buttonPressed: controller.buttonPressed | SM64DemoInputOverlay.endDemoButton
            )
        }
        let geometry = SM64MarioGeometryInput.update(
            position: position,
            graphicsPosition: graphicsPosition,
            world: world,
            terrainType: terrainType,
            isLavaLevel: isLavaLevel,
            isCrawling: isCrawling
        )
        let mario = SM64MarioInputCore.update(
            controller: controller,
            squishTimer: squishTimer,
            previousFramesSinceA: previousFramesSinceA,
            previousFramesSinceB: previousFramesSinceB,
            faceYaw: faceYaw,
            cameraYaw: cameraYaw,
            firstPerson: firstPerson,
            interactionUnknown10: interactionUnknown10,
            geometryFlags: geometry.flags
        )
        let frame = SM64MarioInputFrame(
            simulationTick: simulationTick,
            focused: focused,
            demoEnded: overlay?.didEnd ?? false,
            demoTimer: overlay?.nextState.timer,
            controller: controller,
            mario: mario,
            geometry: geometry,
            rumbleRequest: SM64RumbleBoundary.admitted(
                rumbleRequest,
                focused: focused,
                advanceLegacyDomain: advanceLegacyDomain
            )
        )
        return SM64MarioInputFrameResult(
            frame: frame,
            nextDemoState: overlay.map(\.nextState)
        )
    }
}
