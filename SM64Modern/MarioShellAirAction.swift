import Foundation

enum SM64MarioShellAirIntent: UInt8, Equatable, Sendable {
    case continueAir = 0
    case landed = 1
    case hitWall = 2
    case lavaWall = 3
}

struct SM64MarioShellAirActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let airStep: SM64MarioAirStepOutcome
    let horizontalWindActive: Bool
}

struct SM64MarioShellAirActionResult: Equatable, Sendable {
    let intent: SM64MarioShellAirIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let airStep: SM64MarioAirStepOutcome
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let graphicsYOffset: Float
    let shouldPlayTerrainJumpSound: Bool
    let shouldPlayLavaBoost: Bool
}

/// Value counterpart of `act_riding_shell_air`.
///
/// Horizontal air control is evaluated here from immutable input. Collision,
/// gravity, action installation, and the final graphics-object write remain
/// owner-thread responsibilities; the fixed +42 graphics lift is returned as
/// an explicit presentation effect.
enum SM64MarioShellAirAction {
    private static let jumpRidingShellAnimation: UInt16 = 0x4A

    static func update(
        _ input: SM64MarioShellAirActionInput
    ) -> SM64MarioShellAirActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.velocityY.isFinite else {
            return nil
        }

        var forwardVelocity = input.forwardVelocity
        var sidewaysSpeed: Float = 0

        if !input.horizontalWindActive {
            forwardVelocity = SM64DeterministicPrimitives.approachFloat(
                current: forwardVelocity, target: 0, increment: 0.35, decrement: 0.35
            )

            if input.input.contains(.nonzeroAnalog) {
                let intendedDeltaYaw = Int16(
                    truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)
                )
                let intendedMagnitude = input.intendedMagnitude / 32
                forwardVelocity += intendedMagnitude
                    * SM64CanonicalTrig.coss(intendedDeltaYaw) * 1.5
                sidewaysSpeed = intendedMagnitude
                    * SM64CanonicalTrig.sins(intendedDeltaYaw) * 10
            }

            if forwardVelocity > 32 {
                forwardVelocity -= 1
            }
            if forwardVelocity < -16 {
                forwardVelocity += 2
            }
        }

        let sideYaw = Int16(
            truncatingIfNeeded: Int32(input.faceYaw) + Int32(Int16(bitPattern: 0x4000))
        )
        let forwardX = forwardVelocity * SM64CanonicalTrig.sins(input.faceYaw)
        let forwardZ = forwardVelocity * SM64CanonicalTrig.coss(input.faceYaw)
        let velocity = SM64ObjectVector3(
            x: forwardX + sidewaysSpeed * SM64CanonicalTrig.sins(sideYaw),
            y: input.velocityY,
            z: forwardZ + sidewaysSpeed * SM64CanonicalTrig.coss(sideYaw)
        )

        switch input.airStep {
        case .none:
            return result(
                input: input, intent: .continueAir, action: nil, actionArgument: 0,
                forwardVelocity: forwardVelocity, velocity: velocity,
                shouldPlayLavaBoost: false
            )
        case .landed:
            return result(
                input: input, intent: .landed, action: SM64MarioActionID.ridingShellGround,
                actionArgument: 1, forwardVelocity: forwardVelocity, velocity: velocity,
                shouldPlayLavaBoost: false
            )
        case .hitWall:
            return result(
                input: input, intent: .hitWall, action: nil, actionArgument: 0,
                forwardVelocity: 0, velocity: SM64ObjectVector3(
                    x: 0, y: velocity.y, z: 0
                ), shouldPlayLavaBoost: false
            )
        case .hitLavaWall:
            return result(
                input: input, intent: .lavaWall, action: SM64MarioActionID.lavaBoost,
                actionArgument: 0, forwardVelocity: forwardVelocity, velocity: velocity,
                shouldPlayLavaBoost: true
            )
        }
    }

    private static func result(
        input: SM64MarioShellAirActionInput,
        intent: SM64MarioShellAirIntent,
        action: UInt32?,
        actionArgument: UInt32,
        forwardVelocity: Float,
        velocity: SM64ObjectVector3,
        shouldPlayLavaBoost: Bool
    ) -> SM64MarioShellAirActionResult {
        SM64MarioShellAirActionResult(
            intent: intent, action: action, actionArgument: actionArgument,
            animationID: Self.jumpRidingShellAnimation, airStep: input.airStep,
            forwardVelocity: forwardVelocity, velocity: velocity,
            graphicsYOffset: 42, shouldPlayTerrainJumpSound: true,
            shouldPlayLavaBoost: shouldPlayLavaBoost
        )
    }
}
