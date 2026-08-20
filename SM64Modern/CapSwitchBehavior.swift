import Foundation

enum SM64CapSwitchAction: Int32, Equatable, Sendable {
    case initialize = 0
    case waiting = 1
    case pressing = 2
    case pressed = 3
}

struct SM64CapSwitchInput: Equatable, Sendable {
    let action: SM64CapSwitchAction
    let timer: Int32
    let variant: Int32
    let positionY: Float
    let saveFlags: UInt32
    let levelIsUnknown32: Bool
    let marioOnPlatform: Bool
    let dialogComplete: Bool
}

struct SM64CapSwitchOutput: Equatable, Sendable {
    let action: SM64CapSwitchAction
    let timer: Int32
    let variant: Int32
    let positionY: Float
    let scaleX: Float
    let scaleY: Float
    let scaleZ: Float
    let animationState: Int32
    let spawnBase: Bool
    let saveFlagToSet: UInt32
    let playSound: Bool
    let spawnMist: Bool
    let spawnTriangleBreak: Bool
    let rumble: Bool
    let shouldLoadCollisionModel: Bool
}

enum SM64CapSwitchBehavior {
    static let wingFlag: UInt32 = 1 << 1
    static let metalFlag: UInt32 = 1 << 2
    static let vanishFlag: UInt32 = 1 << 3

    static func saveFlag(for variant: Int32) -> UInt32 {
        switch variant {
        case 0: return wingFlag
        case 1: return metalFlag
        case 2: return vanishFlag
        default: return 0
        }
    }

    static func update(_ input: SM64CapSwitchInput) -> SM64CapSwitchOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var positionY = input.positionY
        var scaleX: Float = 1
        var scaleY: Float = 1
        var scaleZ: Float = 1
        let animationState = input.variant
        var spawnBase = false
        var saveFlagToSet: UInt32 = 0
        var playSound = false
        var spawnMist = false
        var spawnTriangleBreak = false
        var rumble = false

        switch input.action {
        case .initialize:
            positionY += 71
            scaleX = 0.5; scaleY = 0.5; scaleZ = 0.5
            spawnBase = true
            let flag = saveFlag(for: input.variant)
            if !input.levelIsUnknown32 && input.saveFlags & flag != 0 {
                action = .pressed
                scaleY = 0.1
                timer = 0
            } else {
                action = .waiting
                timer = 0
            }
        case .waiting:
            scaleX = 0.5; scaleY = 0.5; scaleZ = 0.5
            if input.marioOnPlatform {
                saveFlagToSet = saveFlag(for: input.variant)
                action = .pressing
                timer = 0
                playSound = true
            }
        case .pressing:
            scaleX = 0.5; scaleZ = 0.5
            if input.timer < 5 {
                scaleY = 0.5 - 0.1 * Float(input.timer)
                if input.timer == 4 {
                    scaleY = 0.1
                    spawnMist = true
                    spawnTriangleBreak = true
                    rumble = true
                }
            } else {
                scaleY = 0.1
                if input.dialogComplete {
                    action = .pressed
                    timer = 0
                }
            }
        case .pressed:
            scaleX = 0.5; scaleY = 0.1; scaleZ = 0.5
        }

        return .init(
            action: action,
            timer: timer,
            variant: input.variant,
            positionY: positionY,
            scaleX: scaleX,
            scaleY: scaleY,
            scaleZ: scaleZ,
            animationState: animationState,
            spawnBase: spawnBase,
            saveFlagToSet: saveFlagToSet,
            playSound: playSound,
            spawnMist: spawnMist,
            spawnTriangleBreak: spawnTriangleBreak,
            rumble: rumble,
            shouldLoadCollisionModel: true
        )
    }
}

struct SM64CapSwitchBaseInput: Equatable, Sendable { let timer: Int32 }
struct SM64CapSwitchBaseOutput: Equatable, Sendable { let timer: Int32; let shouldLoadCollisionModel: Bool }
enum SM64CapSwitchBaseBehavior {
    static func update(_ input: SM64CapSwitchBaseInput) -> SM64CapSwitchBaseOutput {
        .init(timer: input.timer &+ 1, shouldLoadCollisionModel: true)
    }
}
