import Foundation

/// Camera angle, alternate-selection, and mode values retained by the C
/// camera implementation. The raw values intentionally mirror camera.h so
/// the owner-thread adapter can pass them across the ABI without translation.
enum SM64CameraAngle: Int16, Equatable, Sendable {
    case mario = 1
    case lakitu = 2
}

enum SM64CameraSelection: Int16, Equatable, Sendable {
    case mario = 1
    case fixed = 2
}

enum SM64CameraMode: Int16, Equatable, Sendable {
    case none = 0
    case radial = 1
    case outwardRadial = 2
    case behindMario = 3
    case close = 4
    case cUp = 6
    case waterSurface = 8
    case slideHoot = 9
    case insideCannon = 10
    case bossFight = 11
    case parallelTracking = 12
    case fixed = 13
    case eightDirections = 14
    case freeRoam = 16
    case spiralStairs = 17
    case newCam = 18
}

/// A value-only copy of the camera state touched by the selection and mode
/// transition helpers in camera.c. Collision, camera geometry, cutscenes,
/// audio delivery, and Lakitu/render mutation remain owner-thread work.
struct SM64CameraModeState: Equatable, Sendable {
    var selectionFlags: UInt16
    var movementFlags: UInt16
    var soundFlags: UInt16
    var statusFlags: UInt16
    var mode: Int16
    var defaultMode: Int16
    var lastMode: Int16
    var newMode: Int16
    var transitionFramesLeft: Int32
    var transitionMax: Int16
    var transitionFrame: Int16
    var cUpCameraPitch: Int16
    var modeOffsetYaw: Int16
    var lakituDistance: Int16
    var lakituPitch: Int16
    var areaYawChange: Int16
    var panDistance: Float
    var cannonYOffset: Float

    init(
        selectionFlags: UInt16 = 0,
        movementFlags: UInt16 = 0,
        soundFlags: UInt16 = 0,
        statusFlags: UInt16 = 0,
        mode: Int16 = SM64CameraMode.none.rawValue,
        defaultMode: Int16 = SM64CameraMode.none.rawValue,
        lastMode: Int16 = SM64CameraMode.none.rawValue,
        newMode: Int16 = SM64CameraMode.none.rawValue,
        transitionFramesLeft: Int32 = 0,
        transitionMax: Int16 = 0,
        transitionFrame: Int16 = 0,
        cUpCameraPitch: Int16 = 0,
        modeOffsetYaw: Int16 = 0,
        lakituDistance: Int16 = 0,
        lakituPitch: Int16 = 0,
        areaYawChange: Int16 = 0,
        panDistance: Float = 0,
        cannonYOffset: Float = 0
    ) {
        self.selectionFlags = selectionFlags
        self.movementFlags = movementFlags
        self.soundFlags = soundFlags
        self.statusFlags = statusFlags
        self.mode = mode
        self.defaultMode = defaultMode
        self.lastMode = lastMode
        self.newMode = newMode
        self.transitionFramesLeft = transitionFramesLeft
        self.transitionMax = transitionMax
        self.transitionFrame = transitionFrame
        self.cUpCameraPitch = cUpCameraPitch
        self.modeOffsetYaw = modeOffsetYaw
        self.lakituDistance = lakituDistance
        self.lakituPitch = lakituPitch
        self.areaYawChange = areaYawChange
        self.panDistance = panDistance
        self.cannonYOffset = cannonYOffset
    }
}

struct SM64CameraSelectionResult: Equatable, Sendable {
    let state: SM64CameraModeState
    let selection: SM64CameraSelection
}

struct SM64CameraAngleResult: Equatable, Sendable {
    let state: SM64CameraModeState
    let angle: SM64CameraAngle
}

struct SM64CameraHUDStatus: OptionSet, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    static let mario = Self(rawValue: 1 << 0)
    static let lakitu = Self(rawValue: 1 << 1)
    static let fixed = Self(rawValue: 1 << 2)
    static let cDown = Self(rawValue: 1 << 3)
    static let cUp = Self(rawValue: 1 << 4)
}

struct SM64CameraModeResult: Equatable, Sendable {
    let state: SM64CameraModeState
    let changed: Bool
}

/// Pure camera selection and transition state kernels. These are deliberately
/// small seams: later camera-mode passes can consume this state without
/// sharing raw C globals or object-graph pointers with Swift.
enum SM64CameraModeStateMachine {
    static let modeMarioActive: UInt16 = 0x0001
    static let modeLakituWasZoomedOut: UInt16 = 0x0002
    static let modeMarioSelected: UInt16 = 0x0004

    static let moveReturnToMiddle: UInt16 = 0x0001
    static let moveZoomedOut: UInt16 = 0x0002
    static let moveRotateRight: UInt16 = 0x0004
    static let moveRotateLeft: UInt16 = 0x0008
    static let moveEnteredRotateSurface: UInt16 = 0x0010
    static let moveMetalBelowWater: UInt16 = 0x0020
    static let moveFixInPlace: UInt16 = 0x0040
    static let moveUnknown8: UInt16 = 0x0080
    static let moveRestrict: UInt16 = moveEnteredRotateSurface
        | moveMetalBelowWater | moveFixInPlace | moveUnknown8
    static let moveRotate: UInt16 = moveReturnToMiddle | moveRotateRight | moveRotateLeft

    static let soundMarioActive: UInt16 = 0x0002
    static let soundNormalActive: UInt16 = 0x0004
    static let soundUnusedSelectMario: UInt16 = 0x0008
    static let soundUnusedSelectFixed: UInt16 = 0x0010

    static let flagFrameAfterCameraInit: UInt16 = 0x0004
    static let flagStartTransition: UInt16 = 0x0400
    static let flagTransitionOutOfCUp: UInt16 = 0x0800

    static func selectAlternateMode(
        _ selection: Int16,
        state: SM64CameraModeState
    ) -> SM64CameraSelectionResult {
        var state = state
        if selection == SM64CameraSelection.mario.rawValue {
            state.selectionFlags |= Self.modeMarioSelected
            state.soundFlags |= Self.soundUnusedSelectMario
        }

        if selection == SM64CameraSelection.fixed.rawValue
            && state.selectionFlags & Self.modeMarioSelected != 0 {
            state = setCameraAngle(
                SM64CameraAngle.lakitu.rawValue, state: state
            ).state
            state.selectionFlags &= ~Self.modeMarioSelected
            state.soundFlags |= Self.soundUnusedSelectFixed
        }

        let current = state.selectionFlags & Self.modeMarioSelected != 0
            ? SM64CameraSelection.mario
            : SM64CameraSelection.fixed
        return SM64CameraSelectionResult(state: state, selection: current)
    }

    static func setCameraAngle(
        _ angle: Int16,
        state: SM64CameraModeState
    ) -> SM64CameraAngleResult {
        var state = state
        if angle == SM64CameraAngle.mario.rawValue
            && state.selectionFlags & Self.modeMarioActive == 0 {
            state.selectionFlags |= Self.modeMarioActive
            if state.movementFlags & Self.moveZoomedOut != 0 {
                state.selectionFlags |= Self.modeLakituWasZoomedOut
                state.movementFlags &= ~Self.moveZoomedOut
            }
            state.soundFlags |= Self.soundMarioActive
        }

        if angle == SM64CameraAngle.lakitu.rawValue
            && state.selectionFlags & Self.modeMarioActive != 0 {
            state.selectionFlags &= ~Self.modeMarioActive
            if state.selectionFlags & Self.modeLakituWasZoomedOut != 0 {
                state.selectionFlags &= ~Self.modeLakituWasZoomedOut
                state.movementFlags |= Self.moveZoomedOut
            } else {
                state.movementFlags &= ~Self.moveZoomedOut
            }
            state.soundFlags |= Self.soundNormalActive
        }

        let current = state.selectionFlags & Self.modeMarioActive != 0
            ? SM64CameraAngle.mario
            : SM64CameraAngle.lakitu
        return SM64CameraAngleResult(state: state, angle: current)
    }

    static func transitionNextState(
        frames: Int16,
        state: SM64CameraModeState
    ) -> SM64CameraModeResult {
        var state = state
        guard state.statusFlags & Self.flagFrameAfterCameraInit == 0 else {
            return SM64CameraModeResult(state: state, changed: false)
        }
        state.statusFlags |= Self.flagStartTransition | Self.flagTransitionOutOfCUp
        state.transitionFramesLeft = Int32(frames)
        return SM64CameraModeResult(state: state, changed: true)
    }

    static func transitionToCameraMode(
        _ newMode: Int16,
        frames: Int16,
        state: SM64CameraModeState
    ) -> SM64CameraModeResult {
        guard state.mode != newMode else {
            return SM64CameraModeResult(state: state, changed: false)
        }

        var state = state
        state.newMode = newMode == -1 ? state.lastMode : newMode
        state.lastMode = state.mode
        state.mode = state.newMode
        state.movementFlags &= ~(Self.moveRestrict | Self.moveRotate)

        guard state.statusFlags & Self.flagFrameAfterCameraInit == 0 else {
            return SM64CameraModeResult(state: state, changed: true)
        }

        state = transitionNextState(frames: frames, state: state).state
        state.cUpCameraPitch = 0
        state.modeOffsetYaw = 0
        state.lakituDistance = 0
        state.lakituPitch = 0
        state.areaYawChange = 0
        state.panDistance = 0
        state.cannonYOffset = 0
        return SM64CameraModeResult(state: state, changed: true)
    }

    static func hudStatus(
        cutsceneActive: Bool,
        rightTriggerDown: Bool,
        state: SM64CameraModeState
    ) -> SM64CameraHUDStatus {
        let alternate = state.selectionFlags & Self.modeMarioSelected != 0
            ? SM64CameraSelection.mario
            : SM64CameraSelection.fixed
        let angle = setCameraAngle(0, state: state).angle
        var status: SM64CameraHUDStatus
        if cutsceneActive || (rightTriggerDown && alternate == .fixed) {
            status = .fixed
        } else if angle == .mario {
            status = .mario
        } else {
            status = .lakitu
        }
        if state.movementFlags & Self.moveZoomedOut != 0 { status.insert(.cDown) }
        if state.movementFlags & 0x2000 != 0 { status.insert(.cUp) }
        return status
    }
}
