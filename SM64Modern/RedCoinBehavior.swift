import Foundation

enum SM64HiddenRedCoinStarAction: Int32, Equatable, Sendable {
    case waiting = 0
    case reveal = 1
}

struct SM64HiddenRedCoinStarInput: Equatable, Sendable {
    let action: SM64HiddenRedCoinStarAction
    let timer: Int32
    let redCoinCounter: Int32
}

struct SM64HiddenRedCoinStarOutput: Equatable, Sendable {
    let action: SM64HiddenRedCoinStarAction
    let timer: Int32
    let redCoinsCollected: Int32
    let spawnNoExitStar: Bool
    let spawnMist: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_hidden_red_coin_star_loop`.
enum SM64HiddenRedCoinStarBehavior {
    static func update(_ input: SM64HiddenRedCoinStarInput) -> SM64HiddenRedCoinStarOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var spawnNoExitStar = false
        var spawnMist = false
        var shouldDeactivate = false
        switch input.action {
        case .waiting:
            if input.redCoinCounter == 8 {
                action = .reveal
                timer = 0
            }
        case .reveal:
            if input.timer > 2 {
                spawnNoExitStar = true
                spawnMist = true
                shouldDeactivate = true
            }
        }
        return .init(
            action: action,
            timer: timer,
            redCoinsCollected: input.redCoinCounter,
            spawnNoExitStar: spawnNoExitStar,
            spawnMist: spawnMist,
            shouldDeactivate: shouldDeactivate
        )
    }
}

struct SM64RedCoinStarMarkerInput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
}

struct SM64RedCoinStarMarkerOutput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
}

/// Value counterpart of the marker's per-frame yaw loop. Initialization
/// fields (pitch, Y offset, and Z scale) are installed by the owner bridge.
enum SM64RedCoinStarMarkerBehavior {
    static func update(_ input: SM64RedCoinStarMarkerInput) -> SM64RedCoinStarMarkerOutput {
        .init(timer: input.timer &+ 1, faceYaw: input.faceYaw &+ 0x100)
    }
}

struct SM64RedCoinInput: Equatable, Sendable {
    let parentCounter: Int32?
    let interacted: Bool
}

struct SM64RedCoinOutput: Equatable, Sendable {
    let parentCounter: Int32?
    let orangeNumber: Int32?
    let soundOrdinal: Int32?
    let spawnGoldenSparkles: Bool
    let shouldDelete: Bool
    let clearInteraction: Bool
}

/// Value counterpart of `bhv_red_coin_loop`. Audio/progression delivery stays
/// an effect intent; the reducer owns only the fixed-width counter decisions.
enum SM64RedCoinBehavior {
    static func update(_ input: SM64RedCoinInput) -> SM64RedCoinOutput {
        guard input.interacted else {
            return .init(
                parentCounter: input.parentCounter,
                orangeNumber: nil,
                soundOrdinal: nil,
                spawnGoldenSparkles: false,
                shouldDelete: false,
                clearInteraction: true
            )
        }
        let nextCounter = input.parentCounter.map { $0 &+ 1 }
        return .init(
            parentCounter: nextCounter,
            orangeNumber: nextCounter.flatMap { $0 == 8 ? nil : $0 },
            soundOrdinal: nextCounter.map { $0 &- 1 },
            spawnGoldenSparkles: true,
            shouldDelete: true,
            clearInteraction: true
        )
    }
}
