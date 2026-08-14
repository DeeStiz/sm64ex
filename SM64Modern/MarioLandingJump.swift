import Foundation

struct SM64MarioLandingJumpInput: Equatable, Sendable {
    let quicksandDepth: Float
    let heldObjectPresent: Bool
    let floorIsSteep: Bool
    let doubleJumpTimer: UInt8
    let squishTimer: UInt8
    let previousAction: UInt32
    let wingCap: Bool
    let forwardVelocity: Float
}

struct SM64MarioLandingJumpResult: Equatable, Sendable {
    let action: UInt32
    let actionArgument: UInt32
    let didResetDoubleJumpTimer: Bool
    let shouldRunSteepJumpPhysics: Bool
    let shouldDropHeldObject: Bool
}

/// Value counterpart of `set_jump_from_landing`. Steep-jump kinematics and
/// action-entry velocity mutation remain separate seams; this boundary owns
/// only the exact action selection and timer/drop intents.
enum SM64MarioLandingJump {
    static func update(_ input: SM64MarioLandingJumpInput) -> SM64MarioLandingJumpResult? {
        guard input.quicksandDepth.isFinite,
              input.forwardVelocity.isFinite else {
            return nil
        }

        let action: UInt32
        let steepPhysics: Bool
        let drop: Bool

        if input.quicksandDepth >= 11 {
            action = input.heldObjectPresent
                ? SM64MarioActionID.holdQuicksandJumpLand
                : SM64MarioActionID.quicksandJumpLand
            steepPhysics = false
            drop = false
        } else if input.floorIsSteep {
            action = SM64MarioActionID.steepJump
            steepPhysics = true
            drop = true
        } else if input.doubleJumpTimer == 0 || input.squishTimer != 0 {
            action = SM64MarioActionID.jump
            steepPhysics = false
            drop = false
        } else {
            switch input.previousAction {
            case SM64MarioActionID.jumpLand,
                 SM64MarioActionID.freefallLand,
                 SM64MarioActionID.sideFlipLandStop:
                action = SM64MarioActionID.doubleJump
                steepPhysics = false
                drop = false

            case SM64MarioActionID.doubleJumpLand:
                if input.wingCap {
                    action = SM64MarioActionID.flyingTripleJump
                } else if input.forwardVelocity > 20 {
                    action = SM64MarioActionID.tripleJump
                } else {
                    action = SM64MarioActionID.jump
                }
                steepPhysics = false
                drop = false

            default:
                action = SM64MarioActionID.jump
                steepPhysics = false
                drop = false
            }
        }

        return SM64MarioLandingJumpResult(
            action: action,
            actionArgument: 0,
            didResetDoubleJumpTimer: true,
            shouldRunSteepJumpPhysics: steepPhysics,
            shouldDropHeldObject: drop
        )
    }
}
