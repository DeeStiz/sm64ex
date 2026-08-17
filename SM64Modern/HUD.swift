import Foundation

struct SM64HUDDisplayFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    static let lives = Self(rawValue: 0x0001)
    static let coinCount = Self(rawValue: 0x0002)
    static let starCount = Self(rawValue: 0x0004)
    static let cameraAndPower = Self(rawValue: 0x0008)
    static let keys = Self(rawValue: 0x0010)
    static let unknown0020 = Self(rawValue: 0x0020)
    static let timer = Self(rawValue: 0x0040)
    static let emphasizePower = Self(rawValue: 0x8000)
}

enum SM64PowerMeterAnimation: UInt8, Equatable, Sendable {
    case hidden = 0
    case emphasized = 1
    case deemphasizing = 2
    case hiding = 3
    case visible = 4
}

struct SM64HUDTimer: Equatable, Sendable {
    let frames: UInt16
    let minutes: UInt16
    let seconds: UInt16
    let fractionalSeconds: UInt16

    init(frames: UInt16) {
        self.frames = frames
        let value = UInt32(frames)
        let minutes = value / 1_800
        let seconds = (value - minutes * 1_800) / 30
        let fraction = (value - minutes * 1_800 - seconds * 30) / 3
        self.minutes = UInt16(minutes)
        self.seconds = UInt16(seconds)
        self.fractionalSeconds = UInt16(fraction)
    }
}

struct SM64HUDInput: Equatable, Sendable {
    let flags: SM64HUDDisplayFlags
    let configHUD: Bool
    let lives: Int16
    let coins: Int16
    let stars: Int16
    let keys: Int16
    let timer: UInt16
    let hudFlash: Bool
    let globalTimer: UInt32
    let healthWedges: Int16
    let marioSwimming: Bool
    let advanceLegacyDomain: Bool

    init(
        flags: SM64HUDDisplayFlags,
        configHUD: Bool = true,
        lives: Int16 = 4,
        coins: Int16 = 0,
        stars: Int16 = 0,
        keys: Int16 = 0,
        timer: UInt16 = 0,
        hudFlash: Bool = false,
        globalTimer: UInt32 = 0,
        healthWedges: Int16 = 8,
        marioSwimming: Bool = false,
        advanceLegacyDomain: Bool = true
    ) {
        self.flags = flags
        self.configHUD = configHUD
        self.lives = lives
        self.coins = coins
        self.stars = stars
        self.keys = keys
        self.timer = timer
        self.hudFlash = hudFlash
        self.globalTimer = globalTimer
        self.healthWedges = healthWedges
        self.marioSwimming = marioSwimming
        self.advanceLegacyDomain = advanceLegacyDomain
    }
}

struct SM64HUDProjection: Equatable, Sendable {
    let flags: SM64HUDDisplayFlags
    let configHUD: Bool
    let lives: Int16
    let coins: Int16
    let stars: Int16
    let keys: Int16
    let showLives: Bool
    let showCoins: Bool
    let showStars: Bool
    let showKeys: Bool
    let showCameraAndPower: Bool
    let showTimer: Bool
    let showStarMultiplier: Bool
    let timer: SM64HUDTimer
    let powerMeter: SM64PowerMeterSnapshot

    static func project(
        _ input: SM64HUDInput,
        powerMeter: inout SM64PowerMeterState
    ) -> Self {
        let countersVisible = input.configHUD && input.flags != []
        let showStars = countersVisible && input.flags.contains(.starCount)
            && !(input.hudFlash && (input.globalTimer & 0x08) != 0)
        return Self(
            flags: input.flags,
            configHUD: input.configHUD,
            lives: input.lives,
            coins: input.coins,
            stars: input.stars,
            keys: input.keys,
            showLives: countersVisible && input.flags.contains(.lives),
            showCoins: countersVisible && input.flags.contains(.coinCount),
            showStars: showStars,
            showKeys: countersVisible && input.flags.contains(.keys),
            showCameraAndPower: countersVisible && input.flags.contains(.cameraAndPower),
            showTimer: countersVisible && input.flags.contains(.timer),
            showStarMultiplier: showStars && input.stars < 100,
            timer: SM64HUDTimer(frames: input.timer),
            powerMeter: powerMeter.step(
                healthWedges: input.healthWedges,
                flags: input.flags,
                marioSwimming: input.marioSwimming,
                advanceLegacyDomain: input.advanceLegacyDomain
            )
        )
    }
}

struct SM64PowerMeterSnapshot: Equatable, Sendable {
    let animation: SM64PowerMeterAnimation
    let x: Int16
    let y: Int16
    let storedHealth: Int16
    let visibleTimer: UInt32
    let shownHealthWedges: Int16
    let render: Bool
}

struct SM64PowerMeterState: Equatable, Sendable {
    private(set) var animation: SM64PowerMeterAnimation = .hidden
    private(set) var x: Int16 = 140
    private(set) var y: Int16 = 166
    private(set) var storedHealth: Int16 = 8
    private(set) var visibleTimer: UInt32 = 0

    mutating func step(
        healthWedges: Int16,
        flags: SM64HUDDisplayFlags,
        marioSwimming: Bool,
        advanceLegacyDomain: Bool
    ) -> SM64PowerMeterSnapshot {
        guard advanceLegacyDomain else {
            return snapshot(shownHealthWedges: healthWedges)
        }

        if animation != .hiding {
            handleActions(
                healthWedges: healthWedges,
                emphasize: flags.contains(.emphasizePower),
                marioSwimming: marioSwimming
            )
        }
        let render = animation != .hidden
        if render {
            switch animation {
            case .emphasized:
                animateEmphasized(emphasize: flags.contains(.emphasizePower))
            case .deemphasizing:
                animateDeemphasizing()
            case .hiding:
                animateHiding()
            case .hidden, .visible:
                break
            }
        }
        if render {
            visibleTimer &+= 1
        }
        return snapshot(shownHealthWedges: healthWedges, render: render)
    }

    private mutating func handleActions(
        healthWedges: Int16,
        emphasize: Bool,
        marioSwimming: Bool
    ) {
        if healthWedges < 8, storedHealth == 8, animation == .hidden {
            animation = .emphasized
            y = 166
        }
        if healthWedges == 8, storedHealth == 7 {
            visibleTimer = 0
        }
        if healthWedges == 8, visibleTimer > 45 {
            animation = .hiding
        }
        storedHealth = healthWedges

        if marioSwimming {
            if animation == .hidden || animation == .emphasized {
                animation = .deemphasizing
                y = 166
            }
            visibleTimer = 0
        }
        _ = emphasize
    }

    private mutating func animateEmphasized(emphasize: Bool) {
        if !emphasize {
            if visibleTimer == 45 {
                animation = .deemphasizing
            }
        } else {
            visibleTimer = 0
        }
    }

    private mutating func animateDeemphasizing() {
        var speed: Int16 = 5
        if y >= 181 { speed = 3 }
        if y >= 191 { speed = 2 }
        if y >= 196 { speed = 1 }
        y &+= speed
        if y >= 201 {
            y = 200
            animation = .visible
        }
    }

    private mutating func animateHiding() {
        y &+= 20
        if y >= 301 {
            animation = .hidden
            visibleTimer = 0
        }
    }

    private func snapshot(
        shownHealthWedges: Int16,
        render: Bool? = nil
    ) -> SM64PowerMeterSnapshot {
        SM64PowerMeterSnapshot(
            animation: animation,
            x: x,
            y: y,
            storedHealth: storedHealth,
            visibleTimer: visibleTimer,
            shownHealthWedges: shownHealthWedges,
            render: render ?? (animation != .hidden)
        )
    }
}
