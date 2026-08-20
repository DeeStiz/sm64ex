import Foundation

enum SM64BlueCoinSwitchAction: Int32, Equatable, Sendable {
    case idle = 0
    case receding = 1
    case ticking = 2
}

enum SM64BlueCoinSwitchSound: UInt8, Equatable, Sendable {
    case none = 0
    case open = 1
    case tickFast = 2
    case tickSlow = 3
}

struct SM64BlueCoinSwitchInput: Equatable, Sendable {
    let action: SM64BlueCoinSwitchAction
    let timer: Int32
    let positionY: Float
    let velocityY: Float
    let marioPositionY: Float
    let marioGroundPoundOnPlatform: Bool
    let hiddenCoinCount: Int32
}

struct SM64BlueCoinSwitchOutput: Equatable, Sendable {
    let action: SM64BlueCoinSwitchAction
    let timer: Int32
    let positionY: Float
    let velocityY: Float
    let scale: Float
    let visible: Bool
    let collisionEnabled: Bool
    let loadCollisionModel: Bool
    let sound: SM64BlueCoinSwitchSound
    let spawnMist: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_blue_coin_switch_loop`.
enum SM64BlueCoinSwitchBehavior {
    static func update(_ input: SM64BlueCoinSwitchInput) -> SM64BlueCoinSwitchOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var positionY = input.positionY
        var velocityY = input.velocityY
        var visible = true
        var collisionEnabled = false
        var loadCollisionModel = false
        var sound: SM64BlueCoinSwitchSound = .none
        var spawnMist = false
        var shouldDelete = false

        switch input.action {
        case .idle:
            if input.marioGroundPoundOnPlatform {
                action = .receding
                timer = 0
                velocityY = -20
                sound = .open
            }
            // The source calls `load_object_collision_model()` after the
            // ground-pound check, so the transition callback still owns the
            // switch surface for that frame.
            loadCollisionModel = true
            collisionEnabled = true
        case .receding:
            // The original checks `oTimer > 5`, so the switch moves for six
            // callbacks before the sixth callback hides it and starts ticking.
            if input.timer > 5 {
                action = .ticking
                timer = 0
                positionY = input.marioPositionY - 40
                visible = false
                spawnMist = true
            } else {
                positionY += velocityY
                loadCollisionModel = true
                collisionEnabled = true
            }
        case .ticking:
            visible = false
            sound = input.timer < 200 ? .tickFast : .tickSlow
            shouldDelete = input.hiddenCoinCount == 0 || input.timer > 240
        }

        return .init(
            action: action,
            timer: timer,
            positionY: positionY,
            velocityY: velocityY,
            scale: 3,
            visible: visible,
            collisionEnabled: collisionEnabled,
            loadCollisionModel: loadCollisionModel,
            sound: sound,
            spawnMist: spawnMist,
            shouldDelete: shouldDelete
        )
    }
}

enum SM64HiddenBlueCoinAction: Int32, Equatable, Sendable {
    case inactive = 0
    case waiting = 1
    case active = 2
}

struct SM64HiddenBlueCoinInput: Equatable, Sendable {
    let action: SM64HiddenBlueCoinAction
    let timer: Int32
    let switchAction: SM64BlueCoinSwitchAction?
    let interacted: Bool
}

struct SM64HiddenBlueCoinOutput: Equatable, Sendable {
    let action: SM64HiddenBlueCoinAction
    let timer: Int32
    let visible: Bool
    let tangible: Bool
    let spawnGoldenSparkles: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_hidden_blue_coin_loop`.
enum SM64HiddenBlueCoinBehavior {
    static func update(_ input: SM64HiddenBlueCoinInput) -> SM64HiddenBlueCoinOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var visible = false
        var tangible = false
        var spawnGoldenSparkles = false
        var shouldDelete = false

        switch input.action {
        case .inactive:
            if input.switchAction != nil {
                action = .waiting
                timer = 0
            }
        case .waiting:
            if input.switchAction == .ticking {
                action = .active
                timer = 0
            }
        case .active:
            visible = true
            tangible = true
            if input.interacted {
                spawnGoldenSparkles = true
                shouldDelete = true
            } else if input.timer >= 200 {
                let timeBlinking = input.timer - 200
                visible = timeBlinking % 2 == 0
                if timeBlinking / 2 > 20 {
                    shouldDelete = true
                }
            }
        }

        return .init(
            action: action,
            timer: timer,
            visible: visible,
            tangible: tangible,
            spawnGoldenSparkles: spawnGoldenSparkles,
            shouldDelete: shouldDelete
        )
    }
}
