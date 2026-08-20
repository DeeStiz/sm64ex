import Foundation

struct SM64LllRotatingHexagonalPlatformInput: Equatable, Sendable {
    let moveYaw: Int32
}

struct SM64LllRotatingHexagonalPlatformOutput: Equatable, Sendable {
    let moveYaw: Int32
    let faceYaw: Int32
    let angleVelocityYaw: Int32
}

/// Value counterpart of the authored `bhvLllRotatingHexagonalPlatform` loop.
enum SM64LllRotatingHexagonalPlatformBehavior {
    static func update(_ input: SM64LllRotatingHexagonalPlatformInput)
        -> SM64LllRotatingHexagonalPlatformOutput
    {
        let yaw = input.moveYaw &+ 0x100
        return SM64LllRotatingHexagonalPlatformOutput(
            moveYaw: yaw, faceYaw: yaw, angleVelocityYaw: 0x100
        )
    }
}
