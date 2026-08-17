import Foundation

enum SM64FrontEndScreen: UInt8, Equatable, Sendable {
    case title = 0
    case fileSelect = 1
    case courseSelect = 2
    case levelSelect = 3
    case demo = 4
    case gameplay = 5
    case credits = 6
    case ending = 7
}

enum SM64IntroPhase: UInt8, Equatable, Sendable {
    case zoomIn = 0
    case hold = 1
    case zoomOut = 2
    case hidden = 3
}

enum SM64FrontEndTransition: UInt8, Equatable, Sendable {
    case none = 0
    case openFileSelect = 1
    case openCourseSelect = 2
    case startLevel = 3
    case openLevelSelect = 4
    case startDemo = 5
    case returnToTitle = 6
    case openCredits = 7
    case openEnding = 8
}

struct SM64IntroPresentationState: Equatable, Sendable {
    static let zoomInEnd: Int16 = 20
    static let holdEnd: Int16 = 75
    static let zoomOutEnd: Int16 = 91
    static let fadeStart: Int16 = 0x13
    static let fadeStep: Int16 = 0x1A
    static let fadeMax: Int16 = 0xFF

    private(set) var zoomCounter: Int16 = 0
    private(set) var fadeCounter: Int16 = 0

    var phase: SM64IntroPhase {
        switch zoomCounter {
        case 0..<Self.zoomInEnd: return .zoomIn
        case Self.zoomInEnd..<Self.holdEnd: return .hold
        case Self.holdEnd..<Self.zoomOutEnd: return .zoomOut
        default: return .hidden
        }
    }

    mutating func tick(advanceLegacyDomain: Bool, rendered: Bool = true) {
        guard rendered else {
            reset()
            return
        }
        guard advanceLegacyDomain else { return }
        zoomCounter &+= 1
        if zoomCounter >= Self.fadeStart {
            fadeCounter = min(fadeCounter + Self.fadeStep, Self.fadeMax)
        }
    }

    mutating func reset() {
        zoomCounter = 0
        fadeCounter = 0
    }
}

struct SM64PressStartDemoState: Equatable, Sendable {
    static let idleThreshold: UInt16 = 800

    private(set) var idleCounter: UInt16 = 0
    private(set) var demoIndex: UInt8 = 0

    mutating func tick(
        advanceLegacyDomain: Bool,
        hasActivity: Bool,
        demoCount: UInt8
    ) -> Bool {
        guard advanceLegacyDomain else { return false }
        guard !hasActivity else {
            idleCounter = 0
            return false
        }
        guard idleCounter < Self.idleThreshold else { return false }
        idleCounter += 1
        guard idleCounter == Self.idleThreshold else { return false }
        if demoCount > 0 {
            demoIndex = (demoIndex + 1) % demoCount
        }
        return demoCount > 0
    }

    mutating func reset() {
        idleCounter = 0
    }
}

struct SM64LevelSelectState: Equatable, Sendable {
    let minimum: Int16
    let maximum: Int16
    private(set) var level: Int16

    init(minimum: Int16 = 1, maximum: Int16 = 64, level: Int16? = nil) {
        self.minimum = minimum
        self.maximum = max(maximum, minimum)
        self.level = min(max(level ?? minimum, minimum), max(maximum, minimum))
    }

    mutating func move(by delta: Int16) {
        guard delta != 0 else { return }
        let span = Int(maximum - minimum + 1)
        var normalized = Int(level - minimum) + Int(delta)
        normalized %= span
        if normalized < 0 { normalized += span }
        level = minimum + Int16(normalized)
    }
}

struct SM64FrontEndInput: Equatable, Sendable {
    let advanceLegacyDomain: Bool
    let startPressed: Bool
    let confirmPressed: Bool
    let backPressed: Bool
    let hasActivity: Bool
    let selectionDelta: Int16
    let debugLevelSelect: Bool
    let demoComplete: Bool
    let creditsComplete: Bool
    let endingComplete: Bool

    init(
        advanceLegacyDomain: Bool = true,
        startPressed: Bool = false,
        confirmPressed: Bool = false,
        backPressed: Bool = false,
        hasActivity: Bool = false,
        selectionDelta: Int16 = 0,
        debugLevelSelect: Bool = false,
        demoComplete: Bool = false,
        creditsComplete: Bool = false,
        endingComplete: Bool = false
    ) {
        self.advanceLegacyDomain = advanceLegacyDomain
        self.startPressed = startPressed
        self.confirmPressed = confirmPressed
        self.backPressed = backPressed
        self.hasActivity = hasActivity
        self.selectionDelta = selectionDelta
        self.debugLevelSelect = debugLevelSelect
        self.demoComplete = demoComplete
        self.creditsComplete = creditsComplete
        self.endingComplete = endingComplete
    }
}

struct SM64FrontEndTickResult: Equatable, Sendable {
    let screen: SM64FrontEndScreen
    let transition: SM64FrontEndTransition
    let selectedFile: Int8
    let selectedCourse: Int16
    let selectedLevel: Int16
    let demoIndex: UInt8
    let titleZoomCounter: Int16
    let titleFadeCounter: Int16
}

struct SM64FrontEndModel: Equatable, Sendable {
    private(set) var screen: SM64FrontEndScreen = .title
    private(set) var selectedFile: Int8 = 1
    private(set) var selectedCourse: Int16 = 1
    private(set) var selectedLevel: Int16 = 1
    private(set) var title = SM64IntroPresentationState()
    private(set) var demo = SM64PressStartDemoState()
    private(set) var levelSelect = SM64LevelSelectState()

    mutating func tick(_ input: SM64FrontEndInput, demoCount: UInt8 = 8) -> SM64FrontEndTickResult {
        guard input.advanceLegacyDomain else {
            return result(transition: .none)
        }

        var transition: SM64FrontEndTransition = .none
        switch screen {
        case .title:
            title.tick(advanceLegacyDomain: true)
            if input.startPressed {
                title.reset()
                demo.reset()
                if input.debugLevelSelect {
                    screen = .levelSelect
                    transition = .openLevelSelect
                } else {
                    screen = .fileSelect
                    transition = .openFileSelect
                }
            } else if demo.tick(
                advanceLegacyDomain: true,
                hasActivity: input.hasActivity,
                demoCount: demoCount
            ) {
                title.reset()
                screen = .demo
                transition = .startDemo
            }
        case .fileSelect:
            selectedFile = Int8(wrap(Int(selectedFile) + Int(input.selectionDelta), lower: 1, upper: 4))
            if input.backPressed {
                enterTitle()
                transition = .returnToTitle
            } else if input.confirmPressed {
                screen = .courseSelect
                selectedCourse = 1
                transition = .openCourseSelect
            }
        case .courseSelect:
            selectedCourse = Int16(wrap(Int(selectedCourse + input.selectionDelta), lower: 1, upper: 15))
            if input.backPressed {
                screen = .fileSelect
                transition = .openFileSelect
            } else if input.confirmPressed {
                selectedLevel = selectedCourse
                screen = .gameplay
                transition = .startLevel
            }
        case .levelSelect:
            levelSelect.move(by: input.selectionDelta)
            selectedLevel = levelSelect.level
            if input.backPressed {
                enterTitle()
                transition = .returnToTitle
            } else if input.startPressed || input.confirmPressed {
                screen = .gameplay
                transition = .startLevel
            }
        case .demo:
            if input.demoComplete {
                enterTitle()
                transition = .returnToTitle
            }
        case .gameplay:
            if input.creditsComplete {
                screen = .credits
                transition = .openCredits
            } else if input.endingComplete {
                screen = .ending
                transition = .openEnding
            }
        case .credits:
            if input.creditsComplete {
                enterTitle()
                transition = .returnToTitle
            }
        case .ending:
            if input.endingComplete {
                enterTitle()
                transition = .returnToTitle
            }
        }
        return result(transition: transition)
    }

    mutating func enterTitle() {
        screen = .title
        title.reset()
        demo.reset()
    }

    private func result(transition: SM64FrontEndTransition) -> SM64FrontEndTickResult {
        SM64FrontEndTickResult(
            screen: screen,
            transition: transition,
            selectedFile: selectedFile,
            selectedCourse: selectedCourse,
            selectedLevel: selectedLevel,
            demoIndex: demo.demoIndex,
            titleZoomCounter: title.zoomCounter,
            titleFadeCounter: title.fadeCounter
        )
    }

    private func wrap(_ value: Int, lower: Int, upper: Int) -> Int16 {
        let span = upper - lower + 1
        var normalized = (value - lower) % span
        if normalized < 0 { normalized += span }
        return Int16(lower + normalized)
    }
}
