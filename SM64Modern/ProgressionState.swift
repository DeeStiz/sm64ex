import Foundation

struct SM64ProgressionWarpDestination: Equatable, Sendable {
    let level: Int16
    let area: Int16
    let node: Int16
    let argument: Int32
}

struct SM64ProgressionCheckpoint: Equatable, Sendable {
    let act: UInt8
    let course: UInt8
    let level: UInt8
    let area: UInt8
    let node: UInt8
}

enum SM64ProgressionCollectionKind: UInt8, Equatable, Sendable {
    case courseStar = 0
    case secretStar = 1
    case key1 = 2
    case key2 = 3
    case grandStar = 4
}

enum SM64ProgressionCapLocation: UInt8, Equatable, Sendable {
    case none = 0
    case ground = 1
    case klepto = 2
    case ukiki = 3
    case mrBlizzard = 4
}

enum SM64ProgressionEvent: Equatable, Sendable {
    case collectCoin(value: Int16)
    case collectStarOrKey(
        kind: SM64ProgressionCollectionKind,
        starIndex: Int16,
        coinScore: Int16,
        globalMaxCoinScore: Int16
    )
    case unlockCannon
    case pressSwitch(index: UInt8)
    case openDoor(requiredStars: Int16, flag: UInt32)
    case setCapOnGround(level: UInt8, area: UInt8, position: SM64ObjectVector3)
    case setCapLocation(SM64ProgressionCapLocation)
    case setCheckpoint(SM64ProgressionCheckpoint)
    case requestWarp(
        destination: SM64ProgressionWarpDestination,
        checkpoint: SM64ProgressionCheckpoint?
    )
    case addLife(value: Int16)
}

struct SM64ProgressionState: Equatable, Sendable {
    static let courseCount = 25
    static let stageCount = 15

    var flags: UInt32
    var courseStars: [UInt8]
    var courseCoinScores: [UInt8]
    var secretStars: UInt8
    var switchFlags: UInt32
    var coins: Int16
    var lives: Int16
    var courseNumber: Int16
    var lastCompletedCourse: Int16
    var lastCompletedStar: Int16
    var capLocation: SM64ProgressionCapLocation
    var capLevel: UInt8
    var capArea: UInt8
    var capPosition: SM64ObjectVector3
    var checkpoint: SM64ProgressionCheckpoint?
    var saveModified: Bool

    init(
        flags: UInt32 = 0,
        courseStars: [UInt8] = Array(repeating: 0, count: SM64ProgressionState.courseCount),
        courseCoinScores: [UInt8] = Array(repeating: 0, count: SM64ProgressionState.stageCount),
        secretStars: UInt8 = 0,
        switchFlags: UInt32 = 0,
        coins: Int16 = 0,
        lives: Int16 = 4,
        courseNumber: Int16 = 1,
        lastCompletedCourse: Int16 = 0,
        lastCompletedStar: Int16 = 0,
        capLocation: SM64ProgressionCapLocation = .none,
        capLevel: UInt8 = 0,
        capArea: UInt8 = 0,
        capPosition: SM64ObjectVector3 = .init(x: 0, y: 0, z: 0),
        checkpoint: SM64ProgressionCheckpoint? = nil,
        saveModified: Bool = false
    ) {
        precondition(courseStars.count == Self.courseCount)
        precondition(courseCoinScores.count == Self.stageCount)
        self.flags = flags
        self.courseStars = courseStars
        self.courseCoinScores = courseCoinScores
        self.secretStars = secretStars
        self.switchFlags = switchFlags
        self.coins = coins
        self.lives = lives
        self.courseNumber = courseNumber
        self.lastCompletedCourse = lastCompletedCourse
        self.lastCompletedStar = lastCompletedStar
        self.capLocation = capLocation
        self.capLevel = capLevel
        self.capArea = capArea
        self.capPosition = capPosition
        self.checkpoint = checkpoint
        self.saveModified = saveModified
    }

    var totalStars: Int16 {
        let course = courseStars.reduce(Int16(0)) {
            $0 &+ Int16(($1 & 0x7F).nonzeroBitCount)
        }
        return course + Int16((secretStars & 0x7F).nonzeroBitCount)
    }
}

struct SM64ProgressionEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let coin = Self(rawValue: 1 << 0)
    static let starOrKey = Self(rawValue: 1 << 1)
    static let cannon = Self(rawValue: 1 << 2)
    static let switchPressed = Self(rawValue: 1 << 3)
    static let doorOpened = Self(rawValue: 1 << 4)
    static let capMoved = Self(rawValue: 1 << 5)
    static let checkpoint = Self(rawValue: 1 << 6)
    static let warp = Self(rawValue: 1 << 7)
    static let life = Self(rawValue: 1 << 8)
    static let save = Self(rawValue: 1 << 9)
    static let rumble = Self(rawValue: 1 << 10)
}

struct SM64ProgressionReduceResult: Equatable, Sendable {
    let state: SM64ProgressionState
    let effects: SM64ProgressionEffect
    let accepted: Bool
    let warp: SM64ProgressionWarpDestination?
}

/// Save/progression event reducer.  It mirrors the C save-file mutation
/// order while returning render/audio/rumble/warp intents instead of invoking
/// global C services on the simulation thread.
enum SM64ProgressionReducer {
    static let fileExists: UInt32 = 1 << 0
    static let haveWingCap: UInt32 = 1 << 1
    static let haveMetalCap: UInt32 = 1 << 2
    static let haveVanishCap: UInt32 = 1 << 3
    static let haveKey1: UInt32 = 1 << 4
    static let haveKey2: UInt32 = 1 << 5
    static let unlockedBasementDoor: UInt32 = 1 << 6
    static let unlockedUpstairsDoor: UInt32 = 1 << 7
    static let capOnGround: UInt32 = 1 << 16
    static let capOnKlepto: UInt32 = 1 << 17
    static let capOnUkiki: UInt32 = 1 << 18
    static let capOnMrBlizzard: UInt32 = 1 << 19

    static func reduce(
        _ event: SM64ProgressionEvent,
        state: SM64ProgressionState
    ) -> SM64ProgressionReduceResult? {
        var state = state
        var effects: SM64ProgressionEffect = []
        var accepted = true
        var warp: SM64ProgressionWarpDestination?

        switch event {
        case let .collectCoin(value):
            guard value > 0 else { return nil }
            state.coins = state.coins &+ value
            effects = [.coin, .rumble]

        case let .collectStarOrKey(kind, starIndex, coinScore, globalMax):
            guard (0..<7).contains(Int(starIndex)), coinScore >= 0,
                  globalMax >= 0 else { return nil }
            let starFlag = UInt8(1) << UInt8(starIndex)
            let courseIndex = Int(state.courseNumber) - 1
            guard courseIndex >= 0 && courseIndex < state.courseStars.count else {
                return nil
            }
            state.lastCompletedCourse = state.courseNumber
            state.lastCompletedStar = starIndex &+ 1
            state.flags |= Self.fileExists

            switch kind {
            case .courseStar:
                if coinScore > Int16(state.courseCoinScores[courseIndex]) {
                    state.courseCoinScores[courseIndex] = UInt8(truncatingIfNeeded: coinScore)
                    state.saveModified = true
                    effects.insert(.save)
                }
                if state.courseStars[courseIndex] & starFlag == 0 {
                    state.courseStars[courseIndex] |= starFlag
                    state.saveModified = true
                    effects.insert(.save)
                }
            case .secretStar:
                state.secretStars |= starFlag
                state.saveModified = true
                effects.insert(.save)
            case .key1:
                state.flags |= Self.haveKey1
                state.saveModified = true
                effects.insert(.save)
            case .key2:
                state.flags |= Self.haveKey2
                state.saveModified = true
                effects.insert(.save)
            case .grandStar:
                break
            }
            if Int16(coinScore) > globalMax { effects.insert(.save) }
            effects.formUnion([.starOrKey, .rumble])

        case .unlockCannon:
            let index = Int(state.courseNumber)
            guard index >= 0 && index < state.courseStars.count else { return nil }
            state.courseStars[index] |= 0x80
            state.flags |= Self.fileExists
            state.saveModified = true
            effects = [.cannon, .save]

        case let .pressSwitch(index):
            guard index < 32 else { return nil }
            state.switchFlags |= UInt32(1) << UInt32(index)
            effects = [.switchPressed, .rumble]

        case let .openDoor(requiredStars, flag):
            guard requiredStars >= 0 else { return nil }
            if state.totalStars >= requiredStars {
                state.flags |= flag
                state.saveModified = true
                effects = [.doorOpened, .save]
            } else {
                accepted = false
            }

        case let .setCapOnGround(level, area, position):
            guard finite(position) else { return nil }
            state.capLocation = .ground
            state.capLevel = level
            state.capArea = area
            state.capPosition = position
            state.flags |= Self.capOnGround
            state.flags &= ~(Self.capOnKlepto | Self.capOnUkiki | Self.capOnMrBlizzard)
            state.saveModified = true
            effects = [.capMoved, .save]

        case let .setCapLocation(location):
            state.capLocation = location
            state.flags &= ~(Self.capOnGround | Self.capOnKlepto
                | Self.capOnUkiki | Self.capOnMrBlizzard)
            switch location {
            case .none: break
            case .ground: state.flags |= Self.capOnGround
            case .klepto: state.flags |= Self.capOnKlepto
            case .ukiki: state.flags |= Self.capOnUkiki
            case .mrBlizzard: state.flags |= Self.capOnMrBlizzard
            }
            state.saveModified = true
            effects = [.capMoved, .save]

        case let .setCheckpoint(checkpoint):
            state.checkpoint = checkpoint
            effects = [.checkpoint]

        case let .requestWarp(destination, checkpoint):
            guard destination.level >= 0, destination.area >= 0,
                  destination.node >= 0 else { return nil }
            if let checkpoint { state.checkpoint = checkpoint }
            warp = destination
            effects = [.warp]

        case let .addLife(value):
            guard value > 0 else { return nil }
            state.lives = min(100, state.lives &+ value)
            effects = [.life]
        }

        return SM64ProgressionReduceResult(
            state: state, effects: effects, accepted: accepted, warp: warp
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
