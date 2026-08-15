import Foundation

enum SM64MarioDiveAirVariant: UInt8, Equatable, Sendable {
    case dive = 0
    case airThrow = 1
    case forwardRollout = 2
    case backwardRollout = 3
}

enum SM64MarioDiveAirIntent: UInt8, Equatable, Sendable {
    case continueAir = 0
    case landed = 1
    case hitWall = 2
    case lavaWall = 3
    case headStuck = 4
    case diveSlide = 5
    case divePickingUp = 6
    case airThrowLand = 7
}

struct SM64MarioDiveAirActionInput: Equatable, Sendable {
    let variant: SM64MarioDiveAirVariant
    let actionArgument: UInt32
    let input: SM64MarioInputFlags
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let facePitch: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let wallAngle: Int16?
    let airStep: SM64MarioCommonAirStepOutcome
    let actionState: UInt8
    let actionTimer: UInt8
    let animationFrame: Int16
    let animationReturnValue: Int16
    let animationPastEnd: Bool
    let fallDamageOrStuck: Bool
    let shouldGetStuckInGround: Bool
    let heldObjectPresent: Bool
    let objectGrabTransitionAction: UInt32?
    let horizontalWindActive: Bool
}

struct SM64MarioDiveAirActionResult: Equatable, Sendable {
    let variant: SM64MarioDiveAirVariant
    let intent: SM64MarioDiveAirIntent
    let action: UInt32?
    let actionArgument: UInt32
    let airStep: SM64MarioCommonAirStepOutcome
    let animationID: UInt16
    let faceYaw: Int16
    let facePitch: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let graphicsPitch: Int16
    let actionState: UInt8
    let actionTimer: UInt8
    let shouldQueueRumble: Bool
    let particleMistCircle: Bool
    let particleVerticalStar: Bool
    let shouldDropHeldObject: Bool
    let shouldThrowHeldObject: Bool
    let shouldPlayLandingSound: Bool
    let shouldPlaySpinSound: Bool
}

/// Value callers for dive, air-throw, and forward/backward rollout actions.
enum SM64MarioDiveAirAction {
    static func update(
        _ input: SM64MarioDiveAirActionInput
    ) -> SM64MarioDiveAirActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.velocityY.isFinite else { return nil }

        if let objectAction = input.objectGrabTransitionAction,
           input.variant == .dive {
            return result(
                input: input, intent: .continueAir, action: objectAction,
                actionArgument: 0, animationID: 0x88,
                facePitch: input.facePitch, forwardVelocity: input.forwardVelocity,
                velocityY: input.velocityY, actionState: input.actionState,
                actionTimer: input.actionTimer, graphicsPitch: -input.facePitch,
                queueRumble: false, mist: false, verticalStar: false,
                drop: false, throwHeld: false, landingSound: false, spinSound: false
            )
        }

        var velocityY = input.velocityY
        var actionState = input.actionState
        if input.variant == .forwardRollout || input.variant == .backwardRollout,
           actionState == 0 {
            velocityY = 30
            actionState = 1
        }

        let animationID: UInt16
        switch input.variant {
        case .dive: animationID = 0x88
        case .airThrow: animationID = 0x52
        case .forwardRollout:
            animationID = actionState == 1 ? 0x6F : 0x56
        case .backwardRollout:
            animationID = actionState == 1 ? 0x70 : 0x56
        }

        let control = SM64MarioCommonAirAction.update(
            SM64MarioCommonAirActionInput(
                landAction: 0, animationID: animationID, input: input.input,
                intendedMagnitude: input.intendedMagnitude,
                intendedYaw: input.intendedYaw, faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity, velocityY: velocityY,
                wallAngle: nil, airStep: .none, fallDamageOrStuck: false,
                horizontalWindActive: input.horizontalWindActive
            )
        )!

        var actionTimer = input.actionTimer
        var throwHeld = false
        if input.variant == .airThrow {
            actionTimer = input.actionTimer &+ 1
            throwHeld = actionTimer == 4
        }

        if input.variant == .forwardRollout || input.variant == .backwardRollout,
           actionState == 1 && input.animationPastEnd {
            actionState = 2
        }

        var facePitch = input.facePitch
        var graphicsPitch = Int16(truncatingIfNeeded: -Int32(facePitch))
        var forwardVelocity = control.forwardVelocity
        var resolvedVelocityY = velocityY
        var faceYaw = control.faceYaw
        var intent: SM64MarioDiveAirIntent = .continueAir
        var action: UInt32?
        var queueRumble = false
        var mist = false
        var verticalStar = false
        var drop = false
        var landingSound = false
        var spinSound = false

        switch input.airStep {
        case .none:
            if input.variant == .dive {
                if resolvedVelocityY < 0 && facePitch > -0x2AAA {
                    facePitch = Int16(
                        max(-0x2AAA, Int32(facePitch) - 0x200)
                    )
                }
                graphicsPitch = Int16(truncatingIfNeeded: -Int32(facePitch))
            }
            if input.variant == .forwardRollout || input.variant == .backwardRollout {
                spinSound = actionState == 1 && input.animationReturnValue == 4
            }

        case .landed:
            landingSound = true
            switch input.variant {
            case .dive:
                if input.shouldGetStuckInGround && facePitch == -0x2AAA {
                    intent = .headStuck
                    action = SM64MarioActionID.headStuckInGround
                    queueRumble = true
                    mist = true
                    drop = true
                } else if !input.fallDamageOrStuck {
                    intent = input.heldObjectPresent ? .divePickingUp : .diveSlide
                    action = input.heldObjectPresent
                        ? SM64MarioActionID.divePickingUp
                        : SM64MarioActionID.diveSlide
                } else {
                    intent = .landed
                }
                facePitch = 0
                graphicsPitch = 0
            case .airThrow:
                if !input.fallDamageOrStuck {
                    intent = .airThrowLand
                    action = SM64MarioActionID.airThrowLand
                } else {
                    intent = .landed
                }
            case .forwardRollout, .backwardRollout:
                intent = .landed
                action = SM64MarioActionID.freefallLandStop
            }

        case .hitWall:
            intent = .hitWall
            switch input.variant {
            case .dive:
                faceYaw = reflectedYaw(faceYaw: faceYaw, wallAngle: input.wallAngle)
                forwardVelocity = -forwardVelocity
                facePitch = 0
                graphicsPitch = 0
                if resolvedVelocityY > 0 { resolvedVelocityY = 0 }
                action = SM64MarioActionID.backwardAirKnockback
                verticalStar = true
                drop = true
            case .airThrow, .forwardRollout, .backwardRollout:
                forwardVelocity = 0
            }

        case .grabbedLedge, .grabbedCeiling:
            // These callers do not consume ledge/ceiling outcomes specially.
            break

        case .hitLavaWall:
            intent = .lavaWall
            action = SM64MarioActionID.lavaBoost
        }

        let resultVelocityY = resolvedVelocityY
        return result(
            input: input, intent: intent, action: action,
            actionArgument: 0, animationID: animationID,
            facePitch: facePitch, forwardVelocity: forwardVelocity,
            velocityY: resultVelocityY, actionState: actionState,
            actionTimer: actionTimer, graphicsPitch: graphicsPitch,
            queueRumble: queueRumble, mist: mist, verticalStar: verticalStar,
            drop: drop, throwHeld: throwHeld, landingSound: landingSound,
            spinSound: spinSound, faceYaw: faceYaw
        )
    }

    private static func result(
        input: SM64MarioDiveAirActionInput,
        intent: SM64MarioDiveAirIntent,
        action: UInt32?,
        actionArgument: UInt32,
        animationID: UInt16,
        facePitch: Int16,
        forwardVelocity: Float,
        velocityY: Float,
        actionState: UInt8,
        actionTimer: UInt8,
        graphicsPitch: Int16,
        queueRumble: Bool,
        mist: Bool,
        verticalStar: Bool,
        drop: Bool,
        throwHeld: Bool,
        landingSound: Bool,
        spinSound: Bool,
        faceYaw: Int16? = nil
    ) -> SM64MarioDiveAirActionResult {
        SM64MarioDiveAirActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, airStep: input.airStep,
            animationID: animationID, faceYaw: faceYaw ?? input.faceYaw,
            facePitch: facePitch, forwardVelocity: forwardVelocity,
            velocityY: velocityY, graphicsPitch: graphicsPitch,
            actionState: actionState, actionTimer: actionTimer,
            shouldQueueRumble: queueRumble, particleMistCircle: mist,
            particleVerticalStar: verticalStar,
            shouldDropHeldObject: drop,
            shouldThrowHeldObject: throwHeld,
            shouldPlayLandingSound: landingSound,
            shouldPlaySpinSound: spinSound
        )
    }

    private static func reflectedYaw(faceYaw: Int16, wallAngle: Int16?) -> Int16 {
        if let wallAngle {
            return Int16(
                truncatingIfNeeded: Int32(wallAngle) * 2 - Int32(faceYaw)
            )
        }
        return Int16(truncatingIfNeeded: Int32(faceYaw) + 0x8000)
    }
}
