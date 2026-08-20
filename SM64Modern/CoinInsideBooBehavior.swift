import Foundation

enum SM64CoinInsideBooAction: Int32, Equatable, Sendable {
    case inside = 0
    case released = 1
}

struct SM64CoinInsideBooInput: Equatable, Sendable {
    let action: SM64CoinInsideBooAction
    let timer: Int32
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let parentPosition: SM64ObjectVector3
    let parentDying: Bool
    let marioMoveYaw: Int32
    let levelIsBBH: Bool
    let landed: Bool
    let interacted: Bool
}

struct SM64CoinInsideBooOutput: Equatable, Sendable {
    let action: SM64CoinInsideBooAction
    let timer: Int32
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let tangible: Bool
    let blueModel: Bool
    let scale: Float
    let spawnGoldenSparkles: Bool
    let shouldDelete: Bool
}

enum SM64CoinInsideBooBehavior {
    static func update(_ input: SM64CoinInsideBooInput) -> SM64CoinInsideBooOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var velocity = input.velocity
        var tangible = false
        let blueModel = input.levelIsBBH && input.timer == 0
        let scale: Float = blueModel ? 0.7 : 1
        var shouldDelete = false

        switch input.action {
        case .inside:
            tangible = false
            position = input.parentPosition
            if input.parentDying {
                action = .released
                timer = 0
                let yaw = Int16(truncatingIfNeeded: input.marioMoveYaw)
                velocity = .init(
                    x: SM64CanonicalTrig.sins(yaw) * 3,
                    y: 35,
                    z: SM64CanonicalTrig.coss(yaw) * 3
                )
            }
        case .released:
            position.x += velocity.x
            position.y += velocity.y
            position.z += velocity.z
            velocity.y -= 4
            tangible = input.landed || input.timer > 90
        }

        if input.interacted {
            shouldDelete = true
        }

        return .init(
            action: action,
            timer: timer,
            position: position,
            velocity: velocity,
            tangible: tangible,
            blueModel: blueModel,
            scale: scale,
            spawnGoldenSparkles: input.interacted,
            shouldDelete: shouldDelete
        )
    }
}
