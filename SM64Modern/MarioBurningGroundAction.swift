import Foundation

enum SM64MarioBurningGroundIntent: UInt8, Equatable, Sendable {
    case burningJump = 0
    case expired = 1
    case extinguished = 2
    case continueGround = 3
    case burningFall = 4
    case death = 5
}

enum SM64MarioBurningGroundSound: UInt8, Equatable, Sendable {
    case flameOut = 0
    case lavaBurn = 1
}

struct SM64MarioBurningGroundActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let burnTimer: UInt16
    let waterLevel: Float
    let floorHeight: Float
    let forwardVelocity: Float
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let health: UInt16
    let groundStep: SM64MarioGroundStepInput
    let slope: SM64MarioSlopeInput?
}

struct SM64MarioBurningGroundActionResult: Equatable, Sendable {
    let intent: SM64MarioBurningGroundIntent
    let action: UInt32?
    let actionArgument: UInt32
    let burnTimer: UInt16
    let health: UInt16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let animationAcceleration: Int32?
    let particleFire: Bool
    let eyeStateDead: Bool
    let shouldResetRumble: Bool
    let shouldPlayStepSound: Bool
    let sound: SM64MarioBurningGroundSound?
}

/// Value counterpart of `act_burning_ground`.
///
/// Timer, water, speed, yaw, slope, ground-step, and health decisions are
/// computed from immutable snapshots. Particle, audio, eye-state, rumble,
/// action installation, and object mutation are returned as owner-thread
/// effects rather than performed through a C object graph.
enum SM64MarioBurningGroundAction {
    private static let runningAnimation: UInt16 = 0x72

    static func update(
        _ input: SM64MarioBurningGroundActionInput
    ) -> SM64MarioBurningGroundActionResult? {
        guard input.waterLevel.isFinite,
              input.floorHeight.isFinite,
              input.forwardVelocity.isFinite,
              input.intendedMagnitude.isFinite else {
            return nil
        }

        if input.input.contains(.aPressed) {
            return transition(
                input, intent: .burningJump, action: SM64MarioActionID.burningJump,
                burnTimer: input.burnTimer, health: input.health
            )
        }

        let burnTimer = input.burnTimer &+ 2
        if burnTimer > 160 {
            return transition(
                input, intent: .expired, action: SM64MarioActionID.walking,
                burnTimer: burnTimer, health: input.health
            )
        }

        if input.waterLevel - input.floorHeight > 50 {
            return SM64MarioBurningGroundActionResult(
                intent: .extinguished, action: SM64MarioActionID.walking,
                actionArgument: 0, burnTimer: burnTimer, health: input.health,
                faceYaw: input.faceYaw, forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity, groundStep: nil,
                animationID: nil, animationAcceleration: nil, particleFire: false,
                eyeStateDead: false, shouldResetRumble: false,
                shouldPlayStepSound: false, sound: .flameOut
            )
        }

        var forwardVelocity = input.forwardVelocity
        if forwardVelocity < 8 { forwardVelocity = 8 }
        if forwardVelocity > 48 { forwardVelocity = 48 }
        forwardVelocity = SM64DeterministicPrimitives.approachFloat(
            current: forwardVelocity, target: 32, increment: 4, decrement: 1
        )

        var faceYaw = input.faceYaw
        if input.input.contains(.nonzeroAnalog) {
            let delta = Int32(Int16(
                truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)
            ))
            let adjusted = SM64DeterministicPrimitives.approachS32(
                current: delta, target: 0, increment: 0x600, decrement: 0x600
            )
            faceYaw = Int16(
                truncatingIfNeeded: Int32(input.intendedYaw) - adjusted
            )
        }

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
                    action: SM64MarioActionID.burningGround
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
                ridingShell: false,
                terrainSoundAddend: input.groundStep.terrainSoundAddend,
                quarterProbes: input.groundStep.quarterProbes
            )
        ) else { return nil }

        let action: UInt32? = groundStep.result == .leftGround
            ? SM64MarioActionID.burningFall
            : nil
        let intent: SM64MarioBurningGroundIntent = groundStep.result == .leftGround
            ? .burningFall
            : .continueGround
        let health = input.health &- 10
        let died = health < 0x100
        let resolvedAction = died ? SM64MarioActionID.standingDeath : action
        let resolvedIntent: SM64MarioBurningGroundIntent = died ? .death : intent

        return SM64MarioBurningGroundActionResult(
            intent: resolvedIntent, action: resolvedAction, actionArgument: 0,
            burnTimer: burnTimer, health: health, faceYaw: finalFaceYaw,
            forwardVelocity: finalForwardVelocity, velocity: velocity,
            groundStep: groundStep, animationID: Self.runningAnimation,
            animationAcceleration: Int32(finalForwardVelocity / 2 * 0x10000),
            particleFire: true, eyeStateDead: true, shouldResetRumble: true,
            shouldPlayStepSound: true, sound: .lavaBurn
        )
    }

    private static func transition(
        _ input: SM64MarioBurningGroundActionInput,
        intent: SM64MarioBurningGroundIntent,
        action: UInt32,
        burnTimer: UInt16,
        health: UInt16
    ) -> SM64MarioBurningGroundActionResult {
        SM64MarioBurningGroundActionResult(
            intent: intent, action: action, actionArgument: 0,
            burnTimer: burnTimer, health: health, faceYaw: input.faceYaw,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity, groundStep: nil,
            animationID: nil, animationAcceleration: nil, particleFire: false,
            eyeStateDead: false, shouldResetRumble: false,
            shouldPlayStepSound: false, sound: nil
        )
    }
}
