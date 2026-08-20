import Foundation

enum SM64ExclamationBoxContent: UInt8, Equatable, Sendable {
    case none = 0
    case wingCap = 1
    case metalCap = 2
    case vanishCap = 3
    case koopaShell = 4
    case oneCoin = 5
    case threeCoins = 6
    case tenCoins = 7
    case oneUpWalking = 8
    case spawnedStar = 9
    case oneUpRunningAway = 10
}

struct SM64ExclamationBoxInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let behaviorByte: Int32
    let saveCollected: Bool
    let overrideActive: Bool
    let attacked: Bool
    let phase: Int32
}

struct SM64ExclamationBoxOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let animationState: Int32
    let visible: Bool
    let tangible: Bool
    let shouldDelete: Bool
    let model: UInt32
    let scaleX: Float
    let scaleY: Float
    let graphYOffset: Float
    let phase: Int32
    let velocityY: Float
    let spawnRotatingMark: Bool
    let content: SM64ExclamationBoxContent
    let contentParameter: Int32
    let spawnMist: Bool
    let spawnTriangles: Bool
    let playBreakSound: Bool
    let loadCollisionModel: Bool
}

enum SM64ExclamationBoxBehavior {
    static func update(_ input: SM64ExclamationBoxInput) -> SM64ExclamationBoxOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var animationState = input.behaviorByte < 3 ? input.behaviorByte : 3
        var visible = true
        var tangible = false
        var shouldDelete = false
        var model: UInt32 = 0x89
        var scaleX: Float = 2
        var scaleY: Float = 2
        var graphYOffset: Float = 0
        var phase = input.phase
        var velocityY: Float = 0
        var spawnRotatingMark = false
        var content: SM64ExclamationBoxContent = .none
        var contentParameter: Int32 = 0
        var spawnMist = false
        var spawnTriangles = false
        var playBreakSound = false
        let loadCollisionModel = true

        switch input.action {
        case 0:
            if input.behaviorByte >= 3 { animationState = 3; action = 2 }
            else { action = (input.saveCollected || input.overrideActive) ? 2 : 1 }
            timer = 0
            tangible = action == 2
            spawnRotatingMark = action == 1

        case 1:
            tangible = false
            model = 0x83
            if input.timer == 0 { spawnRotatingMark = true }
            if input.saveCollected || input.overrideActive { action = 2; model = 0x89; tangible = true }

        case 2:
            tangible = true
            if input.timer == 0 { graphYOffset = 0 }
            if input.attacked {
                tangible = false
                phase = 0x4000
                velocityY = 30
                action = 3
            }

        case 3:
            tangible = false
            let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: phase))
            scaleX = (-sine + 1) * 1 + 2
            scaleY = (sine + 1) * 0.6
            graphYOffset = (-sine + 1) * 26
            phase &+= 0x1000
            if input.timer == 7 { action = 4; timer = 0 }

        case 4:
            tangible = false
            visible = false
            content = contentFor(byte: input.behaviorByte)
            contentParameter = input.behaviorByte >= 10 ? input.behaviorByte - 10 : 0
            spawnMist = true
            spawnTriangles = true
            playBreakSound = true
            if input.behaviorByte < 3 { action = 5; timer = 0 }
            else { shouldDelete = true }

        case 5:
            visible = false
            tangible = false
            if input.timer > 300 { action = 2; timer = 0; visible = true; tangible = true }

        default:
            action = 0
            timer = 0
        }

        return .init(action: action, timer: timer, animationState: animationState,
                     visible: visible, tangible: tangible, shouldDelete: shouldDelete,
                     model: model, scaleX: scaleX, scaleY: scaleY,
                     graphYOffset: graphYOffset, phase: phase, velocityY: velocityY,
                     spawnRotatingMark: spawnRotatingMark, content: content,
                     contentParameter: contentParameter, spawnMist: spawnMist,
                     spawnTriangles: spawnTriangles, playBreakSound: playBreakSound,
                     loadCollisionModel: loadCollisionModel)
    }

    private static func contentFor(byte: Int32) -> SM64ExclamationBoxContent {
        switch byte {
        case 0: return .wingCap
        case 1: return .metalCap
        case 2: return .vanishCap
        case 3: return .koopaShell
        case 4: return .oneCoin
        case 5: return .threeCoins
        case 6: return .tenCoins
        case 7: return .oneUpWalking
        case 8, 10, 11, 12, 13, 14: return .spawnedStar
        case 9: return .oneUpRunningAway
        default: return .none
        }
    }
}
