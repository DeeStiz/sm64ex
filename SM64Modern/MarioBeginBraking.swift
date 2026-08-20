import Foundation

enum SM64MarioBeginBrakingIntent: UInt8, Equatable, Sendable {
    case standingAgainstWall = 0
    case braking = 1
    case decelerating = 2
}

struct SM64MarioBeginBrakingInput: Equatable, Sendable {
    let actionState: UInt16
    let actionArgument: UInt32
    let forwardVelocity: Float
    let floorNormalY: Float
    let faceYaw: Int16
}

struct SM64MarioBeginBrakingResult: Equatable, Sendable {
    let action: UInt32
    let actionArgument: UInt32
    let faceYaw: Int16
    let intent: SM64MarioBeginBrakingIntent
}

/// Value counterpart of `begin_braking_action`; C retains held-object
/// dropping and action installation.
enum SM64MarioBeginBraking {
    private static let downhillFloorNormal: Float = 0.17364818

    static func update(
        _ input: SM64MarioBeginBrakingInput
    ) -> SM64MarioBeginBrakingResult? {
        guard input.forwardVelocity.isFinite, input.floorNormalY.isFinite else { return nil }
        if input.actionState == 1 {
            return SM64MarioBeginBrakingResult(
                action: SM64MarioActionID.standingAgainstWall,
                actionArgument: 0,
                faceYaw: Int16(truncatingIfNeeded: input.actionArgument),
                intent: .standingAgainstWall
            )
        }
        if input.forwardVelocity >= 16 && input.floorNormalY >= downhillFloorNormal {
            return SM64MarioBeginBrakingResult(
                action: SM64MarioActionID.braking,
                actionArgument: 0,
                faceYaw: input.faceYaw,
                intent: .braking
            )
        }
        return SM64MarioBeginBrakingResult(
            action: SM64MarioActionID.decelerating,
            actionArgument: 0,
            faceYaw: input.faceYaw,
            intent: .decelerating
        )
    }
}
