import Foundation

enum SM64MarioShellGroundIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case shellJump = 1
    case crouchSlide = 2
    case shellFall = 3
    case backwardGroundKnockback = 4
}

enum SM64MarioShellSound: UInt8, Equatable, Sendable {
    case terrain = 0
    case lava = 1
    case bonk = 2
}

struct SM64MarioShellGroundActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let actionArgument: UInt32
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let floorNormalY: Float
    let floorIsSlow: Bool
    let floorIsBurning: Bool
    let terrainSoundAddend: UInt32
    let metalCap: Bool
    let groundStep: SM64MarioGroundStepInput
    let slope: SM64MarioSlopeInput?
}

struct SM64MarioShellGroundActionResult: Equatable, Sendable {
    let intent: SM64MarioShellGroundIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let particleVerticalStar: Bool
    let shouldStopRiding: Bool
    let shouldTiltBody: Bool
    let shouldResetRumble: Bool
    let sound: SM64MarioShellSound?
    let soundAddend: UInt32
}

/// Value counterpart of `act_riding_shell_ground` and `update_shell_speed`.
/// Shell ownership, object detachment, body tilt, sound playback, and rumble
/// are returned as explicit effects for the owner thread.
enum SM64MarioShellGroundAction {
    private static let startRidingShellAnimation: UInt16 = 0x6D
    private static let ridingShellAnimation: UInt16 = 0x47

    static func update(
        _ input: SM64MarioShellGroundActionInput
    ) -> SM64MarioShellGroundActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.floorNormalY.isFinite,
              input.groundStep.position.x.isFinite,
              input.groundStep.position.y.isFinite,
              input.groundStep.position.z.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        if input.input.contains(.aPressed) {
            return transition(input, intent: .shellJump, action: SM64MarioActionID.ridingShellJump)
        }
        if input.input.contains(.zPressed) {
            let forward = max(input.forwardVelocity, 24)
            let velocity = SM64ObjectVector3(
                x: SM64CanonicalTrig.sins(input.faceYaw) * forward,
                y: input.groundStep.velocity.y,
                z: SM64CanonicalTrig.coss(input.faceYaw) * forward
            )
            return SM64MarioShellGroundActionResult(
                intent: .crouchSlide, action: SM64MarioActionID.crouchSlide,
                actionArgument: 0, faceYaw: input.faceYaw,
                forwardVelocity: forward, velocity: velocity,
                groundStep: nil, animationID: nil,
                particleVerticalStar: false, shouldStopRiding: true,
                shouldTiltBody: false, shouldResetRumble: false,
                sound: nil, soundAddend: 0
            )
        }

        let maxTargetSpeed: Float = input.floorIsSlow ? 48 : 64
        var targetSpeed = min(input.intendedMagnitude * 2, maxTargetSpeed)
        if targetSpeed < 24 { targetSpeed = 24 }

        var forwardVelocity = input.forwardVelocity
        if forwardVelocity <= 0 {
            forwardVelocity += 1.1
        } else if forwardVelocity <= targetSpeed {
            forwardVelocity += 1.1 - forwardVelocity / 58
        } else if input.floorNormalY >= 0.95 {
            forwardVelocity -= 1
        }
        if forwardVelocity > 64 { forwardVelocity = 64 }

        let delta = Int32(Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)))
        let adjustedDelta = SM64DeterministicPrimitives.approachS32(
            current: delta, target: 0, increment: 0x800, decrement: 0x800
        )
        let faceYaw = Int16(
            truncatingIfNeeded: Int32(input.intendedYaw) - adjustedDelta
        )

        let appliedSlope: SM64MarioSlopeResult?
        if let slope = input.slope {
            guard let updated = SM64MarioSlope.update(
                SM64MarioSlopeInput(
                    floorClass: slope.floorClass,
                    terrainIsSlide: slope.terrainIsSlide,
                    floorNormalX: slope.floorNormalX,
                    floorNormalY: slope.floorNormalY,
                    floorNormalZ: slope.floorNormalZ,
                    floorAngle: slope.floorAngle,
                    faceYaw: faceYaw,
                    forwardVelocity: forwardVelocity,
                    action: SM64MarioActionID.ridingShellGround
                )
            ) else { return nil }
            appliedSlope = updated
        } else {
            appliedSlope = nil
        }

        let finalForwardVelocity = appliedSlope?.forwardVelocity ?? forwardVelocity
        let finalFaceYaw = appliedSlope?.slideYaw ?? faceYaw
        let velocity = appliedSlope?.velocity ?? SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(finalFaceYaw) * finalForwardVelocity,
            y: 0,
            z: SM64CanonicalTrig.coss(finalFaceYaw) * finalForwardVelocity
        )
        guard let groundStep = SM64MarioGroundStep.update(
            SM64MarioGroundStepInput(
                position: input.groundStep.position,
                velocity: velocity,
                floor: input.groundStep.floor,
                faceYaw: Int32(finalFaceYaw),
                nativeStepScale: input.groundStep.nativeStepScale,
                ridingShell: true,
                terrainSoundAddend: input.groundStep.terrainSoundAddend,
                quarterProbes: input.groundStep.quarterProbes
            )
        ) else { return nil }

        let animationID = input.actionArgument == 0
            ? Self.startRidingShellAnimation
            : Self.ridingShellAnimation
        switch groundStep.result {
        case .leftGround:
            return SM64MarioShellGroundActionResult(
                intent: .shellFall, action: SM64MarioActionID.ridingShellFall,
                actionArgument: 0, faceYaw: finalFaceYaw,
                forwardVelocity: finalForwardVelocity, velocity: velocity,
                groundStep: groundStep, animationID: animationID,
                particleVerticalStar: false, shouldStopRiding: false,
                shouldTiltBody: true, shouldResetRumble: true,
                sound: input.floorIsBurning ? .lava : .terrain,
                soundAddend: input.terrainSoundAddend
            )
        case .hitWall, .hitWallContinueQuarterSteps:
            return SM64MarioShellGroundActionResult(
                intent: .backwardGroundKnockback,
                action: SM64MarioActionID.backwardGroundKnockback,
                actionArgument: 0, faceYaw: finalFaceYaw,
                forwardVelocity: finalForwardVelocity, velocity: velocity,
                groundStep: groundStep, animationID: animationID,
                particleVerticalStar: true, shouldStopRiding: true,
                shouldTiltBody: true, shouldResetRumble: true,
                sound: .bonk, soundAddend: 0
            )
        case .none:
            return SM64MarioShellGroundActionResult(
                intent: .continueGround, action: nil, actionArgument: 0,
                faceYaw: finalFaceYaw, forwardVelocity: finalForwardVelocity,
                velocity: velocity, groundStep: groundStep,
                animationID: animationID, particleVerticalStar: false,
                shouldStopRiding: false, shouldTiltBody: true,
                shouldResetRumble: true,
                sound: input.floorIsBurning ? .lava : .terrain,
                soundAddend: input.terrainSoundAddend
            )
        }
    }

    private static func transition(
        _ input: SM64MarioShellGroundActionInput,
        intent: SM64MarioShellGroundIntent,
        action: UInt32
    ) -> SM64MarioShellGroundActionResult {
        SM64MarioShellGroundActionResult(
            intent: intent, action: action, actionArgument: 0,
            faceYaw: input.faceYaw, forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity, groundStep: nil,
            animationID: nil, particleVerticalStar: false,
            shouldStopRiding: false, shouldTiltBody: false,
            shouldResetRumble: false, sound: nil, soundAddend: 0
        )
    }
}
