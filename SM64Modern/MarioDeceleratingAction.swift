import Foundation

enum SM64MarioDeceleratingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case beginSliding = 1
    case jump = 2
    case dive = 3
    case movePunching = 4
    case walking = 5
    case crouchSlide = 6
    case idle = 7
    case freefall = 8
}

struct SM64MarioDeceleratingActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let floorClass: SM64MarioFloorClass
    let faceYaw: Int16
    let forwardVelocity: Float
    let stickMagnitude: Float
    let velocityY: Float
    let landingJump: SM64MarioLandingJumpInput?
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioDeceleratingActionResult: Equatable, Sendable {
    let intent: SM64MarioDeceleratingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let animationAcceleration: Int32
    let particleDust: Bool
    let reflectedBonk: Bool
}

/// Value counterpart of `act_decelerating`. Common exits, speed approach,
/// floor-class animation choice, and very-slippery wall reflection are kept as
/// explicit scalar/effect results for owner-thread application.
enum SM64MarioDeceleratingAction {
    private static let walkingAnimation: UInt16 = 0x48
    private static let idleHeadLeftAnimation: UInt16 = 0xC3

    static func update(
        _ input: SM64MarioDeceleratingActionInput
    ) -> SM64MarioDeceleratingActionResult? {
        guard input.forwardVelocity.isFinite,
              input.stickMagnitude.isFinite,
              input.velocityY.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        if !input.input.contains(.firstPerson) {
            if input.input.contains(.aboveSlide),
               input.terrainIsSlide || input.forwardVelocity <= -1 || input.facingDownhill {
                return early(.beginSliding, action: SM64MarioActionID.beginSliding, input: input)
            }

            if input.input.contains(.aPressed) {
                guard let landingJump = input.landingJump,
                      let jump = SM64MarioLandingJump.update(landingJump) else {
                    return nil
                }
                return early(.jump, action: jump.action, input: input)
            }

            if input.input.contains(.bPressed) {
                if input.forwardVelocity >= 29 && input.stickMagnitude > 48 {
                    var velocity = input.groundStep.velocity
                    velocity.y = 20
                    return early(
                        .dive,
                        action: SM64MarioActionID.dive,
                        actionArgument: 1,
                        input: input,
                        velocity: velocity
                    )
                }
                return early(.movePunching, action: SM64MarioActionID.movePunching, input: input)
            }

            if input.input.contains(.nonzeroAnalog) {
                return early(.walking, action: SM64MarioActionID.walking, input: input)
            }

            if input.input.contains(.zPressed) {
                return early(.crouchSlide, action: SM64MarioActionID.crouchSlide, input: input)
            }
        }

        guard let speed = SM64MarioDeceleratingSpeed.update(
            SM64MarioDeceleratingSpeedInput(
                forwardVelocity: input.forwardVelocity,
                faceYaw: input.faceYaw,
                velocityY: input.velocityY
            )
        ) else {
            return nil
        }

        if speed.stopped {
            return result(
                intent: .idle,
                action: SM64MarioActionID.idle,
                input: input,
                faceYaw: input.faceYaw,
                forwardVelocity: speed.forwardVelocity,
                velocity: speed.velocity,
                groundStep: nil,
                animationID: nil,
                animationAcceleration: 0,
                particleDust: false,
                reflectedBonk: false
            )
        }

        let stepInput = SM64MarioGroundStepInput(
            position: input.groundStep.position,
            velocity: speed.velocity,
            floor: input.groundStep.floor,
            faceYaw: Int32(input.faceYaw),
            nativeStepScale: input.groundStep.nativeStepScale,
            ridingShell: input.groundStep.ridingShell,
            terrainSoundAddend: input.groundStep.terrainSoundAddend,
            quarterProbes: input.groundStep.quarterProbes
        )
        guard let groundStep = SM64MarioGroundStep.update(stepInput) else {
            return nil
        }

        switch groundStep.result {
        case .leftGround:
            return result(
                intent: .freefall,
                action: SM64MarioActionID.freefall,
                input: input,
                faceYaw: input.faceYaw,
                forwardVelocity: speed.forwardVelocity,
                velocity: speed.velocity,
                groundStep: groundStep,
                animationID: nil,
                animationAcceleration: 0,
                particleDust: false,
                reflectedBonk: false
            )

        case .none:
            if input.floorClass == .verySlippery {
                return result(
                    intent: .continueGround,
                    action: nil,
                    input: input,
                    faceYaw: input.faceYaw,
                    forwardVelocity: speed.forwardVelocity,
                    velocity: speed.velocity,
                    groundStep: groundStep,
                    animationID: idleHeadLeftAnimation,
                    animationAcceleration: 0,
                    particleDust: true,
                    reflectedBonk: false
                )
            }
            let acceleration = max(
                Int32((speed.forwardVelocity / 4 * 65_536).rounded(.towardZero)),
                0x1000
            )
            return result(
                intent: .continueGround,
                action: nil,
                input: input,
                faceYaw: input.faceYaw,
                forwardVelocity: speed.forwardVelocity,
                velocity: speed.velocity,
                groundStep: groundStep,
                animationID: walkingAnimation,
                animationAcceleration: acceleration,
                particleDust: false,
                reflectedBonk: false
            )

        case .hitWall, .hitWallContinueQuarterSteps:
            if input.floorClass == .verySlippery,
               let wall = input.groundStep.quarterProbes.compactMap(\.upperWall).first {
                let wallAngle = SM64CanonicalTrig.atan2s(y: wall.normalZ, x: wall.normalX)
                let reflectedYaw = Int16(
                    truncatingIfNeeded: Int32(wallAngle)
                        - Int32(Int16(truncatingIfNeeded: Int32(input.faceYaw) - Int32(wallAngle)))
                )
                let reflectedVelocity = -speed.forwardVelocity
                let reflected = SM64ObjectVector3(
                    x: SM64CanonicalTrig.sins(reflectedYaw) * reflectedVelocity,
                    y: speed.velocity.y,
                    z: SM64CanonicalTrig.coss(reflectedYaw) * reflectedVelocity
                )
                return result(
                    intent: .continueGround,
                    action: nil,
                    input: input,
                    faceYaw: reflectedYaw,
                    forwardVelocity: reflectedVelocity,
                    velocity: reflected,
                    groundStep: groundStep,
                    animationID: idleHeadLeftAnimation,
                    animationAcceleration: 0,
                    particleDust: true,
                    reflectedBonk: true
                )
            }
            let stopped = SM64ObjectVector3(x: 0, y: speed.velocity.y, z: 0)
            return result(
                intent: .continueGround,
                action: nil,
                input: input,
                faceYaw: input.faceYaw,
                forwardVelocity: 0,
                velocity: stopped,
                groundStep: groundStep,
                animationID: input.floorClass == .verySlippery ? idleHeadLeftAnimation : walkingAnimation,
                animationAcceleration: input.floorClass == .verySlippery ? 0 : 0x1000,
                particleDust: input.floorClass == .verySlippery,
                reflectedBonk: false
            )
        }
    }

    private static func early(
        _ intent: SM64MarioDeceleratingIntent,
        action: UInt32,
        actionArgument: UInt32 = 0,
        input: SM64MarioDeceleratingActionInput,
        velocity: SM64ObjectVector3? = nil
    ) -> SM64MarioDeceleratingActionResult {
        result(
            intent: intent,
            action: action,
            input: input,
            faceYaw: input.faceYaw,
            forwardVelocity: input.forwardVelocity,
            velocity: velocity ?? input.groundStep.velocity,
            groundStep: nil,
            animationID: nil,
            animationAcceleration: 0,
            particleDust: false,
            reflectedBonk: false,
            actionArgument: actionArgument
        )
    }

    private static func result(
        intent: SM64MarioDeceleratingIntent,
        action: UInt32?,
        input: SM64MarioDeceleratingActionInput,
        faceYaw: Int16,
        forwardVelocity: Float,
        velocity: SM64ObjectVector3,
        groundStep: SM64MarioGroundStepResult?,
        animationID: UInt16?,
        animationAcceleration: Int32,
        particleDust: Bool,
        reflectedBonk: Bool,
        actionArgument: UInt32 = 0
    ) -> SM64MarioDeceleratingActionResult {
        SM64MarioDeceleratingActionResult(
            intent: intent,
            action: action,
            actionArgument: actionArgument,
            faceYaw: faceYaw,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            groundStep: groundStep,
            animationID: animationID,
            animationAcceleration: animationAcceleration,
            particleDust: particleDust,
            reflectedBonk: reflectedBonk
        )
    }
}
