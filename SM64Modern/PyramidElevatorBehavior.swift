import Foundation

struct SM64PyramidElevatorInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let homeY: Float
    let velocityY: Float
    let marioOnPlatform: Bool
}

struct SM64PyramidElevatorOutput: Equatable, Sendable {
    let action: Int32
    let positionY: Float
    let velocityY: Float
    let markerShouldBeActive: Bool
}

/// Value counterpart of the pyramid elevator and its trajectory marker
/// lifecycle. Collision/effect delivery stays with the owner bridge.
enum SM64PyramidElevatorBehavior {
    static func update(_ input: SM64PyramidElevatorInput) -> SM64PyramidElevatorOutput {
        var action = input.action
        var positionY = input.positionY
        var velocityY = input.velocityY
        switch input.action {
        case 0:
            if input.marioOnPlatform { action = 1 }
        case 1:
            let phase = Int16(truncatingIfNeeded: input.timer &* 0x1000)
            positionY = input.homeY - SM64CanonicalTrig.sins(phase) * 10
            if input.timer == 8 { action = 2 }
        case 2:
            velocityY = -10
            positionY += velocityY
            if positionY < 128 {
                positionY = 128
                action = 3
            }
        case 3:
            let phase = Int16(truncatingIfNeeded: input.timer &* 0x1000)
            positionY = SM64CanonicalTrig.sins(phase) * 10 + 128
            if input.timer >= 8 {
                velocityY = 0
                positionY = 128
            }
        default:
            break
        }
        return SM64PyramidElevatorOutput(
            action: action,
            positionY: positionY,
            velocityY: velocityY,
            markerShouldBeActive: action == 0
        )
    }
}
