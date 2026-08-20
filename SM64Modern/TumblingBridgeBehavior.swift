import Foundation

enum SM64TumblingBridgeVariant: UInt8, Equatable, Sendable {
    case wf = 0
    case bbh = 1
    case lll = 2
}

struct SM64TumblingBridgeParentInput: Equatable, Sendable {
    let action: Int32
    let distanceToMario: Float
    let variant: SM64TumblingBridgeVariant
}

struct SM64TumblingBridgeParentOutput: Equatable, Sendable {
    let action: Int32
    let spawnChildren: Bool
    let visible: Bool
}

struct SM64TumblingBridgePlatformInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let marioOnPlatform: Bool
    let angleVelocityPitch: Int32
    let angleVelocityRoll: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let floorHeight: Float
    let parentAction: Int32
    let rollStep: Int32
}

struct SM64TumblingBridgePlatformOutput: Equatable, Sendable {
    let action: Int32
    let angleVelocityPitch: Int32
    let angleVelocityRoll: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let shouldDelete: Bool
    let playSound: Bool
}

/// Value counterparts of `bhv_tumbling_bridge_loop` and
/// `bhv_tumbling_bridge_platform_loop`.
enum SM64TumblingBridgeBehavior {
    static func updateParent(
        _ input: SM64TumblingBridgeParentInput
    ) -> SM64TumblingBridgeParentOutput {
        var action = input.action
        var spawnChildren = false
        var visible = true

        switch input.action {
        case 0:
            if input.variant == .lll || input.distanceToMario < 1000 {
                action = 1
            }
        case 1:
            action = 2
            spawnChildren = true
        case 2:
            if input.variant == .lll {
                visible = true
            } else if input.distanceToMario > 1200 {
                action = 3
                visible = true
            } else {
                visible = false
            }
        case 3:
            action = 0
            visible = true
        default:
            action = 0
        }

        return SM64TumblingBridgeParentOutput(
            action: action,
            spawnChildren: spawnChildren,
            visible: visible
        )
    }

    static func updatePlatform(
        _ input: SM64TumblingBridgePlatformInput
    ) -> SM64TumblingBridgePlatformOutput {
        var action = input.action
        var angleVelocityPitch = input.angleVelocityPitch
        var angleVelocityRoll = input.angleVelocityRoll
        var facePitch = input.facePitch
        var faceRoll = input.faceRoll
        var position = input.position
        var velocityY = input.velocityY
        var playSound = false

        switch input.action {
        case 0:
            if input.marioOnPlatform {
                action = 1
            }
        case 1:
            if input.timer > 5 {
                action = 2
                playSound = true
            }
        case 2:
            if angleVelocityPitch < 0x400 {
                angleVelocityPitch &+= 0x80
            }
            if angleVelocityRoll > -0x400, angleVelocityRoll < 0x400 {
                angleVelocityRoll &+= input.rollStep
            }
            velocityY += -3
            position.y += velocityY
            facePitch &+= angleVelocityPitch
            faceRoll &+= angleVelocityRoll
            if position.y < input.floorHeight - 300 {
                action = 3
            }
        default:
            break
        }

        return SM64TumblingBridgePlatformOutput(
            action: action,
            angleVelocityPitch: angleVelocityPitch,
            angleVelocityRoll: angleVelocityRoll,
            facePitch: facePitch,
            faceRoll: faceRoll,
            position: position,
            velocityY: velocityY,
            shouldDelete: input.parentAction == 3,
            playSound: playSound
        )
    }
}
