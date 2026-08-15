import Foundation

struct SM64ProgressionActorState: Equatable, Sendable {
    static let redCoinTarget: UInt8 = 8

    var redCoinsCollected: UInt8
    var redCoinStarSpawned: Bool
    var capSwitchesPressed: UInt8
    var levelCompleted: Bool

    init(
        redCoinsCollected: UInt8 = 0,
        redCoinStarSpawned: Bool = false,
        capSwitchesPressed: UInt8 = 0,
        levelCompleted: Bool = false
    ) {
        precondition(redCoinsCollected <= Self.redCoinTarget)
        self.redCoinsCollected = redCoinsCollected
        self.redCoinStarSpawned = redCoinStarSpawned
        self.capSwitchesPressed = capSwitchesPressed
        self.levelCompleted = levelCompleted
    }
}

enum SM64ProgressionActorEvent: Equatable, Sendable {
    case resetLevel
    case collectRedCoin
    case pressCapSwitch(index: UInt8)
    case completeLevel(
        kind: SM64ProgressionCollectionKind,
        starIndex: Int16,
        coinScore: Int16,
        globalMaxCoinScore: Int16
    )
}

struct SM64ProgressionActorEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let redCoin = Self(rawValue: 1 << 0)
    static let redCoinStarSpawned = Self(rawValue: 1 << 1)
    static let capSwitchPressed = Self(rawValue: 1 << 2)
    static let cutscene = Self(rawValue: 1 << 3)
    static let levelCompleted = Self(rawValue: 1 << 4)
    static let reward = Self(rawValue: 1 << 5)
    static let levelReset = Self(rawValue: 1 << 6)
    static let rumble = Self(rawValue: 1 << 7)
}

struct SM64ProgressionActorReduceResult: Equatable, Sendable {
    let actor: SM64ProgressionActorState
    let progression: SM64ProgressionState
    let effects: SM64ProgressionActorEffect
    let progressionEffects: SM64ProgressionEffect
    let accepted: Bool
}

/// Value-only actor routes for red coins, cap switches, and level rewards.
/// Owner-thread services consume the returned sound/camera/rumble/render
/// intents; this reducer never calls legacy object or save globals.
enum SM64ProgressionActorReducer {
    private static let capSwitchFlags: [UInt32] = [
        SM64ProgressionReducer.haveWingCap,
        SM64ProgressionReducer.haveMetalCap,
        SM64ProgressionReducer.haveVanishCap
    ]

    static func reduce(
        _ event: SM64ProgressionActorEvent,
        actor: SM64ProgressionActorState,
        progression: SM64ProgressionState
    ) -> SM64ProgressionActorReduceResult? {
        var actor = actor
        var progression = progression
        var effects: SM64ProgressionActorEffect = []
        var progressionEffects: SM64ProgressionEffect = []

        switch event {
        case .resetLevel:
            actor.redCoinsCollected = 0
            actor.redCoinStarSpawned = false
            actor.levelCompleted = false
            effects = [.levelReset]

        case .collectRedCoin:
            guard actor.redCoinsCollected < SM64ProgressionActorState.redCoinTarget,
                  !actor.redCoinStarSpawned else {
                return result(
                    actor: actor, progression: progression,
                    effects: [], progressionEffects: [], accepted: false
                )
            }
            guard let coin = SM64ProgressionReducer.reduce(
                .collectCoin(value: 2), state: progression
            ) else { return nil }
            progression = coin.state
            progressionEffects = coin.effects
            actor.redCoinsCollected &+= 1
            effects = [.redCoin, .rumble]
            if actor.redCoinsCollected == SM64ProgressionActorState.redCoinTarget {
                actor.redCoinStarSpawned = true
                effects.formUnion([.redCoinStarSpawned, .cutscene])
            }

        case let .pressCapSwitch(index):
            guard Int(index) < Self.capSwitchFlags.count else { return nil }
            let bit = Self.capSwitchFlags[Int(index)]
            let actorBit = UInt8(1) << index
            guard progression.flags & bit == 0 else {
                return result(
                    actor: actor, progression: progression,
                    effects: [], progressionEffects: [], accepted: false
                )
            }
            progression.flags |= bit | SM64ProgressionReducer.fileExists
            progression.saveModified = true
            actor.capSwitchesPressed |= actorBit
            effects = [.capSwitchPressed, .cutscene, .rumble]
            progressionEffects = [.save]

        case let .completeLevel(kind, starIndex, coinScore, globalMaxCoinScore):
            guard !actor.levelCompleted else {
                return result(
                    actor: actor, progression: progression,
                    effects: [], progressionEffects: [], accepted: false
                )
            }
            guard let reward = SM64ProgressionReducer.reduce(
                .collectStarOrKey(
                    kind: kind, starIndex: starIndex, coinScore: coinScore,
                    globalMaxCoinScore: globalMaxCoinScore
                ), state: progression
            ) else { return nil }
            progression = reward.state
            progressionEffects = reward.effects
            actor.levelCompleted = true
            effects = [.levelCompleted, .reward, .cutscene]
        }

        return result(
            actor: actor, progression: progression,
            effects: effects, progressionEffects: progressionEffects, accepted: true
        )
    }

    private static func result(
        actor: SM64ProgressionActorState,
        progression: SM64ProgressionState,
        effects: SM64ProgressionActorEffect,
        progressionEffects: SM64ProgressionEffect,
        accepted: Bool
    ) -> SM64ProgressionActorReduceResult {
        SM64ProgressionActorReduceResult(
            actor: actor, progression: progression, effects: effects,
            progressionEffects: progressionEffects, accepted: accepted
        )
    }
}
