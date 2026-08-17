import Foundation

enum SM64PauseMenuState: UInt8, Equatable, Sendable {
    case opening = 0
    case vertical = 1
    case horizontal = 2
}

enum SM64PauseCameraSelection: Int8, Equatable, Sendable {
    case mario = 1
    case fixed = 2
}

enum SM64PauseMenuOutcome: Int8, Equatable, Sendable {
    case none = 0
    case resume = 1
    case exitCourse = 2
}

struct SM64PauseMenuInput: Equatable, Sendable {
    let advanceLegacyDomain: Bool
    let confirmPressed: Bool
    let verticalSelectionDelta: Int8
    let horizontalCameraDelta: Int8
    let courseNumber: Int16
    let courseMinimum: Int16
    let courseMaximum: Int16
    let canExitCourse: Bool
    let currentCameraSelection: SM64PauseCameraSelection

    init(
        advanceLegacyDomain: Bool = true,
        confirmPressed: Bool = false,
        verticalSelectionDelta: Int8 = 0,
        horizontalCameraDelta: Int8 = 0,
        courseNumber: Int16 = 1,
        courseMinimum: Int16 = 1,
        courseMaximum: Int16 = 15,
        canExitCourse: Bool = false,
        currentCameraSelection: SM64PauseCameraSelection = .mario
    ) {
        self.advanceLegacyDomain = advanceLegacyDomain
        self.confirmPressed = confirmPressed
        self.verticalSelectionDelta = verticalSelectionDelta
        self.horizontalCameraDelta = horizontalCameraDelta
        self.courseNumber = courseNumber
        self.courseMinimum = courseMinimum
        self.courseMaximum = courseMaximum
        self.canExitCourse = canExitCourse
        self.currentCameraSelection = currentCameraSelection
    }
}

struct SM64PauseMenuTickResult: Equatable, Sendable {
    let state: SM64PauseMenuState
    let selection: Int8
    let cameraSelection: SM64PauseCameraSelection
    let textAlpha: UInt16
    let menuModeActive: Bool
    let outcome: SM64PauseMenuOutcome
    let cameraChanged: Bool
}

struct SM64PauseMenuModel: Equatable, Sendable {
    private(set) var state: SM64PauseMenuState = .opening
    private(set) var selection: Int8 = 1
    private(set) var cameraSelection: SM64PauseCameraSelection = .mario
    private(set) var textAlpha: UInt16 = 0
    private(set) var menuModeActive = true

    mutating func tick(_ input: SM64PauseMenuInput) -> SM64PauseMenuTickResult {
        var outcome: SM64PauseMenuOutcome = .none
        var cameraChanged = false

        guard input.advanceLegacyDomain else {
            return result(outcome: outcome, cameraChanged: cameraChanged)
        }

        switch state {
        case .opening:
            textAlpha = 0
            menuModeActive = true
            selection = 1
            cameraSelection = input.currentCameraSelection
            if input.courseNumber >= input.courseMinimum && input.courseNumber <= input.courseMaximum {
                state = .vertical
            } else {
                state = .horizontal
            }
        case .vertical:
            if input.canExitCourse {
                selection = clamp(selection + input.verticalSelectionDelta, lower: 1, upper: 3)
                if selection == 3 {
                    let nextCamera = clampCamera(cameraSelection, delta: input.horizontalCameraDelta)
                    cameraChanged = nextCamera != cameraSelection
                    cameraSelection = nextCamera
                }
            } else {
                selection = 1
            }
            if input.confirmPressed {
                outcome = selection == 2 ? .exitCourse : .resume
                state = .opening
                menuModeActive = false
            }
        case .horizontal:
            let nextCamera = clampCamera(cameraSelection, delta: input.horizontalCameraDelta)
            cameraChanged = nextCamera != cameraSelection
            cameraSelection = nextCamera
            if input.confirmPressed {
                outcome = .resume
                state = .opening
                menuModeActive = false
            }
        }

        textAlpha = min(textAlpha + 25, 250)
        return result(outcome: outcome, cameraChanged: cameraChanged)
    }

    mutating func reopen() {
        state = .opening
        selection = 1
        menuModeActive = true
    }

    private func result(outcome: SM64PauseMenuOutcome, cameraChanged: Bool) -> SM64PauseMenuTickResult {
        SM64PauseMenuTickResult(
            state: state,
            selection: selection,
            cameraSelection: cameraSelection,
            textAlpha: textAlpha,
            menuModeActive: menuModeActive,
            outcome: outcome,
            cameraChanged: cameraChanged
        )
    }

    private func clamp(_ value: Int8, lower: Int8, upper: Int8) -> Int8 {
        min(max(value, lower), upper)
    }

    private func clampCamera(_ value: SM64PauseCameraSelection, delta: Int8) -> SM64PauseCameraSelection {
        let next = min(max(Int(value.rawValue) + Int(delta), 1), 2)
        return SM64PauseCameraSelection(rawValue: Int8(next)) ?? .mario
    }
}
