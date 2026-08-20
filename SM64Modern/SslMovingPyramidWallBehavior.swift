import Foundation

enum SM64SslPyramidWallStart: Int32, Equatable, Sendable {
    case high = 0
    case middle = 1
    case low = 2
}

struct SM64SslMovingPyramidWallInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
}

struct SM64SslMovingPyramidWallOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let velocityY: Float
}

enum SM64SslMovingPyramidWallBehavior {
    static func initialize(_ positionY: Float, start: SM64SslPyramidWallStart) -> SM64SslMovingPyramidWallInput {
        switch start {
        case .high: return .init(action: 0, timer: 0, positionY: positionY)
        case .middle: return .init(action: 0, timer: 50, positionY: positionY - 256)
        case .low: return .init(action: 1, timer: 0, positionY: positionY - 512)
        }
    }

    /// Value counterpart of `bhv_ssl_moving_pyramid_wall_loop`.
    static func update(_ input: SM64SslMovingPyramidWallInput) -> SM64SslMovingPyramidWallOutput {
        var action = input.action
        let velocityY: Float
        if action == 0 {
            velocityY = -5.12
            if input.timer == 100 { action = 1 }
        } else {
            velocityY = 5.12
            if input.timer == 100 { action = 0 }
        }
        return .init(action: action, timer: input.timer &+ 1, positionY: input.positionY + velocityY, velocityY: velocityY)
    }
}
