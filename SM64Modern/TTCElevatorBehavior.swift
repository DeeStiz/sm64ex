import Foundation

struct SM64TTCElevatorInitialization: Equatable, Sendable {
    let peakY: Float
}

struct SM64TTCElevatorInput: Equatable, Sendable {
    let speedSetting: Int32
    let timer: Int32
    let direction: Int32
    let moveTime: Int32
    let positionY: Float
    let homeY: Float
    let peakY: Float
    let gravity: Float
    let randomSign: Int32
    let randomMoveTime: Int32
}

struct SM64TTCElevatorOutput: Equatable, Sendable {
    let velocityY: Float
    let direction: Int32
    let moveTime: Int32
    let timer: Int32
    let positionY: Float
    let clampedAtEndpoint: Bool
}

/// Value counterpart of `bhv_ttc_elevator_init` and
/// `bhv_ttc_elevator_update`.
enum SM64TTCElevatorBehavior {
    private static let speeds: [Float] = [6, 10, 6, 0]

    static func initialize(positionY: Float, behaviorParameterHigh: UInt16) -> SM64TTCElevatorInitialization {
        let peakOffset = behaviorParameterHigh == 0
            ? Float(500)
            : Float(behaviorParameterHigh) * 100
        return SM64TTCElevatorInitialization(peakY: positionY + peakOffset)
    }

    static func update(_ input: SM64TTCElevatorInput) -> SM64TTCElevatorOutput {
        let speed = SM64TTCElevatorBehavior.speeds[Int(input.speedSetting)]
        var velocityY = speed * Float(input.direction)
        var direction = input.direction
        var moveTime = input.moveTime
        var timer = input.timer

        if input.speedSetting == 2 {
            if input.timer > input.moveTime {
                direction = input.randomSign
                moveTime = input.randomMoveTime
                timer = 0
            } else if input.timer < 5 {
                velocityY = 0
            }
        }

        velocityY += input.gravity
        var positionY = input.positionY + velocityY
        var clampedAtEndpoint = false
        if positionY < input.homeY {
            positionY = input.homeY
            clampedAtEndpoint = true
        } else if positionY > input.peakY {
            positionY = input.peakY
            clampedAtEndpoint = true
        }
        if clampedAtEndpoint {
            direction = -direction
        }

        return SM64TTCElevatorOutput(
            velocityY: velocityY,
            direction: direction,
            moveTime: moveTime,
            timer: timer,
            positionY: positionY,
            clampedAtEndpoint: clampedAtEndpoint
        )
    }
}
