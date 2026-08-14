import Foundation

/// Immutable values supplied by the engine owner thread for one native
/// simulation step. The coordinator deliberately receives the collision world
/// by value so it cannot share mutable C object-graph state across threads.
struct SM64SwiftGameplayTickInput: Equatable, Sendable {
    let sample: SM64ControllerRawSample
    let focused: Bool
    let advanceLegacyDomain: Bool
    let rumbleRequest: SM64RumbleRequest?
    let position: SM64ObjectVector3
    let graphicsPosition: SM64ObjectVector3
    let world: SM64SurfaceCollisionWorld
    let terrainType: UInt16
    let isLavaLevel: Bool
    let isCrawling: Bool
    let squishTimer: Int32
    let faceYaw: Int16
    let cameraYaw: Int16
    let firstPerson: Bool
    let interactionUnknown10: Bool

    init(
        sample: SM64ControllerRawSample,
        focused: Bool,
        advanceLegacyDomain: Bool,
        rumbleRequest: SM64RumbleRequest? = nil,
        position: SM64ObjectVector3,
        graphicsPosition: SM64ObjectVector3,
        world: SM64SurfaceCollisionWorld,
        terrainType: UInt16 = 0,
        isLavaLevel: Bool = false,
        isCrawling: Bool = false,
        squishTimer: Int32 = 0,
        faceYaw: Int16 = 0,
        cameraYaw: Int16 = 0,
        firstPerson: Bool = false,
        interactionUnknown10: Bool = false
    ) {
        self.sample = sample
        self.focused = focused
        self.advanceLegacyDomain = advanceLegacyDomain
        self.rumbleRequest = rumbleRequest
        self.position = position
        self.graphicsPosition = graphicsPosition
        self.world = world
        self.terrainType = terrainType
        self.isLavaLevel = isLavaLevel
        self.isCrawling = isCrawling
        self.squishTimer = squishTimer
        self.faceYaw = faceYaw
        self.cameraYaw = cameraYaw
        self.firstPerson = firstPerson
        self.interactionUnknown10 = interactionUnknown10
    }
}

struct SM64SwiftGameplayTickState: Equatable, Sendable {
    let simulationTick: UInt64
    let globalTimer: UInt64
    let demoState: SM64DemoInputState?
    let framesSinceA: UInt8
    let framesSinceB: UInt8
}

struct SM64SwiftGameplayTickResult: Equatable, Sendable {
    let frame: SM64MarioInputFrame
    let rumble: SM64RumbleTickResult
    let state: SM64SwiftGameplayTickState
}

/// First owner-thread Swift gameplay boundary. It composes the already
/// qualified input/geometry domains and advances only the legacy-rate state on
/// logical boundaries; held native redraw steps remain observable but do not
/// consume edges, demo time, rumble timers, or global time.
struct SM64SwiftGameplayTick: Equatable, Sendable {
    private(set) var state: SM64SwiftGameplayTickState
    private var controllerNormalizer: SM64ControllerInputNormalizer
    private var cameraNormalizer: SM64CameraInputNormalizer
    private var rumbleScheduler: SM64RumbleScheduler

    init(
        initialSimulationTick: UInt64 = 0,
        initialGlobalTimer: UInt64 = 0,
        initialDemoState: SM64DemoInputState? = nil,
        initialFramesSinceA: UInt8 = 0,
        initialFramesSinceB: UInt8 = 0,
        rumbleDisabled: Bool = false
    ) {
        self.state = SM64SwiftGameplayTickState(
            simulationTick: initialSimulationTick,
            globalTimer: initialGlobalTimer,
            demoState: initialDemoState,
            framesSinceA: initialFramesSinceA,
            framesSinceB: initialFramesSinceB
        )
        self.controllerNormalizer = SM64ControllerInputNormalizer()
        self.cameraNormalizer = SM64CameraInputNormalizer()
        var scheduler = SM64RumbleScheduler()
        scheduler.disabled = rumbleDisabled
        self.rumbleScheduler = scheduler
    }

    mutating func setDemoState(_ demoState: SM64DemoInputState?) {
        state = SM64SwiftGameplayTickState(
            simulationTick: state.simulationTick,
            globalTimer: state.globalTimer,
            demoState: demoState,
            framesSinceA: state.framesSinceA,
            framesSinceB: state.framesSinceB
        )
    }

    mutating func enqueueRumble(strength: Int16, duration: Int16) {
        rumbleScheduler.enqueue(strength: strength, duration: duration)
    }

    mutating func resetRumbleTimers() {
        rumbleScheduler.resetTimers()
    }

    mutating func resetRumbleTimers2(_ value: Int32) {
        rumbleScheduler.resetTimers2(value)
    }

    mutating func setRumbleCancelTimer(_ value: Int16) {
        rumbleScheduler.setCancelTimer(value)
    }

    mutating func cancelRumble() {
        rumbleScheduler.cancel()
    }

    mutating func step(_ input: SM64SwiftGameplayTickInput) -> SM64SwiftGameplayTickResult {
        let composed = SM64MarioInputFrameComposer.update(
            normalizer: &controllerNormalizer,
            cameraNormalizer: &cameraNormalizer,
            simulationTick: state.simulationTick,
            sample: input.sample,
            focused: input.focused,
            advanceLegacyDomain: input.advanceLegacyDomain,
            demoState: state.demoState,
            rumbleRequest: input.rumbleRequest,
            position: input.position,
            graphicsPosition: input.graphicsPosition,
            world: input.world,
            terrainType: input.terrainType,
            isLavaLevel: input.isLavaLevel,
            isCrawling: input.isCrawling,
            squishTimer: input.squishTimer,
            previousFramesSinceA: state.framesSinceA,
            previousFramesSinceB: state.framesSinceB,
            faceYaw: input.faceYaw,
            cameraYaw: input.cameraYaw,
            firstPerson: input.firstPerson,
            interactionUnknown10: input.interactionUnknown10
        )
        let rumble = rumbleScheduler.tick(
            globalTimer: state.globalTimer,
            advanceLegacyDomain: input.advanceLegacyDomain
        )
        let nextState = SM64SwiftGameplayTickState(
            simulationTick: state.simulationTick &+ 1,
            globalTimer: input.advanceLegacyDomain ? state.globalTimer &+ 1 : state.globalTimer,
            demoState: composed.nextDemoState,
            framesSinceA: composed.frame.mario.framesSinceA,
            framesSinceB: composed.frame.mario.framesSinceB
        )
        state = nextState
        return SM64SwiftGameplayTickResult(
            frame: composed.frame,
            rumble: rumble,
            state: nextState
        )
    }
}
