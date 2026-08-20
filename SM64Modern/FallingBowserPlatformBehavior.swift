import Foundation

struct SM64FallingBowserPlatformInput: Equatable, Sendable {
    let action: Int32
    let subAction: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let gravity: Float
    let variant: Int32
    let bowserPresent: Bool
    let bowserOnPlatform: Bool
    let bowserAction: Int32
    let bowserFireFlag: Bool
    let bowserHealth: Int32
    let bowserHeld: Bool
    let debugValue: Int32
    let shakeCounter: Int32
}

struct SM64FallingBowserPlatformOutput: Equatable, Sendable {
    let action: Int32
    let subAction: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let gravity: Float
    let shakeCounter: Int32
    let collisionVariant: Int32
    let cameraShake: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_falling_bowser_platform_loop`.
enum SM64FallingBowserPlatformBehavior {
    static let collisionAnchors: [SM64ObjectVector3] = [
        .init(x: 0, y: 0, z: 0),
        .init(x: -800, y: -1000, z: -20992),
        .init(x: -1158, y: 390, z: -18432),
        .init(x: -1158, y: 390, z: -7680),
        .init(x: 0, y: 1240, z: -6144),
        .init(x: 0, y: 1240, z: 6144),
        .init(x: 1158, y: 390, z: 7680),
        .init(x: 1158, y: 390, z: 18432),
        .init(x: 800, y: -1000, z: 20992),
        .init(x: 800, y: -1000, z: -31744),
        .init(x: -800, y: -1000, z: 31744),
    ]

    static func update(_ input: SM64FallingBowserPlatformInput) -> SM64FallingBowserPlatformOutput {
        var action = input.action
        var subAction = input.subAction
        var timer = input.timer &+ 1
        var position = input.position
        var velocityY = input.velocityY
        var gravity = input.gravity
        var shakeCounter = input.shakeCounter
        var cameraShake = false
        var shouldDelete = false

        switch input.action {
        case 0:
            if input.bowserPresent { action = 1; timer = 0 }
        case 1:
            if input.bowserOnPlatform && input.bowserAction == 13 && input.bowserFireFlag { action = 2; timer = 0 }
            if input.bowserHealth == 1 && (input.bowserAction == 3 || input.bowserHeld) { subAction = 1 }
            if subAction == 0 {
                shakeCounter = 0
            } else {
                if (input.debugValue + 20) * (input.variant - 1) < shakeCounter { action = 2; timer = 0 }
                shakeCounter &+= 1
            }
        case 2:
            if input.timer < 22 {
                velocityY = 8
                gravity = 0
                cameraShake = true
            } else {
                gravity = -4
            }
            position.y += velocityY
            velocityY += gravity
            if input.timer > 300 { shouldDelete = true }
            cameraShake = cameraShake || input.timer < 22
        default:
            action = 0
            timer = 0
        }

        return .init(
            action: action,
            subAction: subAction,
            timer: timer,
            position: position,
            velocityY: velocityY,
            gravity: gravity,
            shakeCounter: shakeCounter,
            collisionVariant: max(0, min(input.variant, Int32(collisionAnchors.count - 1))),
            cameraShake: cameraShake,
            shouldDelete: shouldDelete
        )
    }
}
