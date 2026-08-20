import Foundation

struct SM64MarioGroundDivePunchInput: Equatable, Sendable {
    let bPressed: Bool
    let forwardVelocity: Float
    let stickMagnitude: Float
    let velocityY: Float
}

struct SM64MarioGroundDivePunchResult: Equatable, Sendable {
    let triggered: Bool
    let action: UInt32
    let actionArgument: UInt32
    let velocityY: Float
}

/// Value counterpart of `check_ground_dive_or_punch`.
enum SM64MarioGroundDivePunch {
    private static let dive: UInt32 = 0x0188_088A
    private static let movePunching: UInt32 = 0x0080_0457

    static func update(
        _ input: SM64MarioGroundDivePunchInput
    ) -> SM64MarioGroundDivePunchResult? {
        guard input.forwardVelocity.isFinite,
              input.stickMagnitude.isFinite,
              input.velocityY.isFinite else { return nil }
        guard input.bPressed else {
            return SM64MarioGroundDivePunchResult(
                triggered: false, action: 0, actionArgument: 0, velocityY: input.velocityY
            )
        }
        if input.forwardVelocity >= 29 && input.stickMagnitude > 48 {
            return SM64MarioGroundDivePunchResult(
                triggered: true, action: dive, actionArgument: 1, velocityY: 20
            )
        }
        return SM64MarioGroundDivePunchResult(
            triggered: true, action: movePunching, actionArgument: 0, velocityY: input.velocityY
        )
    }
}
