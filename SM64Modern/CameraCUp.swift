import Foundation

struct SM64CameraCUpState: Equatable, Sendable {
    let active: Bool
    let startedExiting: Bool
    let pitch: Int16
    let modeOffsetYaw: Int16
    let headPitch: Int16
    let headYaw: Int16
    let storedPosition: SM64ObjectVector3
    let storedFocusOffsetY: Float
}

struct SM64CameraCUpHeadInput: Equatable, Sendable {
    let pitch: Int16
    let modeOffsetYaw: Int16
    let stickX: Float
    let stickY: Float
}

struct SM64CameraCUpHeadResult: Equatable, Sendable {
    let pitch: Int16
    let modeOffsetYaw: Int16
    let headPitch: Int16
    let headYaw: Int16
}

struct SM64CameraCUpPlacement: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let yaw: Int16
}

enum SM64CameraShakeEvent: Int16, Equatable, Sendable {
    case attack = 1
    case groundPound = 2
    case smallDamage = 3
    case mediumDamage = 4
    case largeDamage = 5
    case hitFromBelow = 8
    case fallDamage = 9
}

struct SM64CameraShakeChannel: Equatable, Sendable {
    let amplitude: Int16
    let decay: Int16
    let increment: Int16
}

struct SM64CameraShakePlan: Equatable, Sendable {
    let pitch: SM64CameraShakeChannel?
    let yaw: SM64CameraShakeChannel?
    let roll: SM64CameraShakeChannel?
    let fov: SM64CameraShakeChannel?
    let freezesMovement: Bool
    let changesFocusSpeed: Bool
}

/// C-up camera state and shake/FOV intent descriptors. Storing the camera
/// vectors and delivering head/effect mutations remains an owner-thread task.
enum SM64CameraCUp {
    static let pitchMin: Int16 = -0x2000
    static let pitchMax: Int16 = 0x38E3
    static let yawMin: Int16 = -0x5555
    static let yawMax: Int16 = 0x5555

    static func enter(
        state: SM64CameraCUpState,
        cameraPosition: SM64ObjectVector3,
        marioPosition: SM64ObjectVector3,
        cameraFocus: SM64ObjectVector3
    ) -> SM64CameraCUpState? {
        guard finite(cameraPosition), finite(marioPosition), finite(cameraFocus) else { return nil }
        guard !state.active else { return state }
        return SM64CameraCUpState(
            active: true,
            startedExiting: false,
            pitch: state.pitch,
            modeOffsetYaw: state.modeOffsetYaw,
            headPitch: state.headPitch,
            headYaw: state.headYaw,
            storedPosition: SM64ObjectVector3(
                x: cameraPosition.x - marioPosition.x,
                y: cameraPosition.y - marioPosition.y,
                z: cameraPosition.z - marioPosition.z
            ),
            storedFocusOffsetY: cameraFocus.y - marioPosition.y
        )
    }

    static func updateHead(_ input: SM64CameraCUpHeadInput) -> SM64CameraCUpHeadResult? {
        guard input.stickX.isFinite, input.stickY.isFinite else { return nil }
        var pitch = input.pitch &+ Int16(truncatingIfNeeded: Int32(input.stickY * 10))
        var yaw = input.modeOffsetYaw &- Int16(truncatingIfNeeded: Int32(input.stickX * 10))
        pitch = min(max(pitch, Self.pitchMin), Self.pitchMax)
        yaw = min(max(yaw, Self.yawMin), Self.yawMax)
        return SM64CameraCUpHeadResult(
            pitch: pitch,
            modeOffsetYaw: yaw,
            headPitch: Int16(truncatingIfNeeded: Int32(pitch) * 3 / 4),
            headYaw: Int16(truncatingIfNeeded: Int32(yaw) * 3 / 4)
        )
    }

    static func update(
        marioPosition: SM64ObjectVector3,
        marioFaceYaw: Int16,
        pitch: Int16,
        modeOffsetYaw: Int16,
        lakituPitch: Int16 = 0
    ) -> SM64CameraCUpPlacement? {
        let yaw = marioFaceYaw &+ modeOffsetYaw &+ Int16(bitPattern: 0x8000)
        return SM64CameraGeometry.focusOnMario(
            marioPosition: marioPosition,
            positionYOffset: 125,
            focusYOffset: 125,
            distance: 250,
            pitch: pitch,
            yaw: yaw,
            lakituPitch: lakituPitch
        ).map { SM64CameraCUpPlacement(focus: $0.focus, position: $0.position, yaw: yaw) }
    }

    static func requestExit(state: SM64CameraCUpState) -> SM64CameraCUpState {
        guard state.active else { return state }
        return SM64CameraCUpState(
            active: true,
            startedExiting: true,
            pitch: state.pitch,
            modeOffsetYaw: state.modeOffsetYaw,
            headPitch: state.headPitch,
            headYaw: state.headYaw,
            storedPosition: state.storedPosition,
            storedFocusOffsetY: state.storedFocusOffsetY
        )
    }

    static func shake(
        _ event: SM64CameraShakeEvent,
        waterOrMetalAction: Bool
    ) -> SM64CameraShakePlan {
        let none: SM64CameraShakeChannel? = nil
        switch event {
        case .attack:
            return SM64CameraShakePlan(
                pitch: none, yaw: none, roll: none, fov: none,
                freezesMovement: true, changesFocusSpeed: true
            )
        case .groundPound:
            return SM64CameraShakePlan(
                pitch: .init(amplitude: 0x60, decay: 0xC, increment: Int16(bitPattern: 0x8000)),
                yaw: none, roll: none, fov: none,
                freezesMovement: false, changesFocusSpeed: false
            )
        case .fallDamage:
            let channel = SM64CameraShakeChannel(amplitude: 0x60, decay: 3, increment: Int16(bitPattern: 0x8000))
            return SM64CameraShakePlan(
                pitch: channel, yaw: none, roll: channel, fov: none,
                freezesMovement: false, changesFocusSpeed: false
            )
        case .hitFromBelow:
            return SM64CameraShakePlan(
                pitch: none, yaw: none, roll: none, fov: none,
                freezesMovement: false, changesFocusSpeed: true
            )
        case .smallDamage, .mediumDamage, .largeDamage:
            let swimming: (SM64CameraShakeChannel, SM64CameraShakeChannel, SM64CameraShakeChannel)
            switch (event, waterOrMetalAction) {
            case (.smallDamage, true):
                swimming = (.init(amplitude: 0x200, decay: 0x10, increment: 0x1000),
                            .init(amplitude: 0x400, decay: 0x20, increment: 0x1000),
                            .init(amplitude: 0x100, decay: 0x30, increment: Int16(bitPattern: 0x8000)))
            case (.mediumDamage, true):
                swimming = (.init(amplitude: 0x400, decay: 0x20, increment: 0x1000),
                            .init(amplitude: 0x600, decay: 0x30, increment: 0x1000),
                            .init(amplitude: 0x180, decay: 0x40, increment: Int16(bitPattern: 0x8000)))
            case (.largeDamage, true):
                swimming = (.init(amplitude: 0x600, decay: 0x30, increment: 0x1000),
                            .init(amplitude: 0x800, decay: 0x40, increment: 0x1000),
                            .init(amplitude: 0x200, decay: 0x50, increment: Int16(bitPattern: 0x8000)))
            case (.smallDamage, false):
                swimming = (.init(amplitude: 0x80, decay: 8, increment: 0x4000),
                            .init(amplitude: 0x80, decay: 8, increment: 0x4000),
                            .init(amplitude: 0x100, decay: 0x30, increment: Int16(bitPattern: 0x8000)))
            case (.mediumDamage, false):
                swimming = (.init(amplitude: 0x100, decay: 0x10, increment: 0x4000),
                            .init(amplitude: 0x100, decay: 0x10, increment: 0x4000),
                            .init(amplitude: 0x180, decay: 0x40, increment: Int16(bitPattern: 0x8000)))
            default:
                swimming = (.init(amplitude: 0x180, decay: 0x20, increment: 0x4000),
                            .init(amplitude: 0x200, decay: 0x20, increment: 0x4000),
                            .init(amplitude: 0x200, decay: 0x50, increment: Int16(bitPattern: 0x8000)))
            }
            return SM64CameraShakePlan(
                pitch: none, yaw: swimming.0, roll: swimming.1, fov: swimming.2,
                freezesMovement: false, changesFocusSpeed: true
            )
        }
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
