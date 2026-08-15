import Foundation

enum SM64MarioCommonAirStepOutcome: UInt8, Equatable, Sendable {
    case none = 0
    case landed = 1
    case hitWall = 2
    case grabbedLedge = 3
    case grabbedCeiling = 4
    case hitLavaWall = 5
}

enum SM64MarioCommonAirIntent: UInt8, Equatable, Sendable {
    case continueAir = 0
    case land = 1
    case hardFall = 2
    case lowSpeedWallStop = 3
    case airHitWall = 4
    case backwardAirKnockback = 5
    case softBonk = 6
    case ledgeGrab = 7
    case hanging = 8
    case lavaWall = 9
}

struct SM64MarioCommonAirActionInput: Equatable, Sendable {
    let landAction: UInt32
    let animationID: UInt16
    let input: SM64MarioInputFlags
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let wallAngle: Int16?
    let airStep: SM64MarioCommonAirStepOutcome
    let fallDamageOrStuck: Bool
    let horizontalWindActive: Bool
}

struct SM64MarioCommonAirActionResult: Equatable, Sendable {
    let intent: SM64MarioCommonAirIntent
    let action: UInt32?
    let actionArgument: UInt32
    let airStep: SM64MarioCommonAirStepOutcome
    let animationID: UInt16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let shouldQueueRumble: Bool
    let particleVerticalStar: Bool
    let shouldReflectBonk: Bool
    let shouldDropHeldObject: Bool
    let shouldPlayLavaBoost: Bool
}

/// Shared value counterpart of `common_air_action_step`.
///
/// The owner thread supplies a collision outcome and optional wall normal
/// angle. This boundary owns C's air-control math and exact branch ordering;
/// gravity, collision queries, action installation, sound, and object/held
/// references remain explicit effects for the owner thread.
enum SM64MarioCommonAirAction {
    private static let idleOnLedgeAnimation: UInt16 = 0x33

    static func update(
        _ input: SM64MarioCommonAirActionInput
    ) -> SM64MarioCommonAirActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.velocityY.isFinite else {
            return nil
        }

        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var faceYaw = input.faceYaw
        var sidewaysSpeed: Float = 0

        if !input.horizontalWindActive {
            forwardVelocity = SM64DeterministicPrimitives.approachFloat(
                current: forwardVelocity, target: 0, increment: 0.35, decrement: 0.35
            )
            if input.input.contains(.nonzeroAnalog) {
                let intendedDYaw = Int16(
                    truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)
                )
                let intendedMag = input.intendedMagnitude / 32
                forwardVelocity += intendedMag
                    * SM64CanonicalTrig.coss(intendedDYaw) * 1.5
                sidewaysSpeed = intendedMag
                    * SM64CanonicalTrig.sins(intendedDYaw) * 10
            }
            if forwardVelocity > 32 { forwardVelocity -= 1 }
            if forwardVelocity < -16 { forwardVelocity += 2 }
        }

        var resultAnimation = input.animationID
        var intent: SM64MarioCommonAirIntent = .continueAir
        var action: UInt32?
        let actionArgument: UInt32 = 0
        var queueRumble = false
        var verticalStar = false
        var reflectedBonk = false
        var dropHeldObject = false
        var lavaBoost = false

        switch input.airStep {
        case .none:
            break

        case .landed:
            if input.fallDamageOrStuck {
                intent = .hardFall
                action = SM64MarioActionID.hardBackwardGroundKnockback
            } else {
                intent = .land
                action = input.landAction
            }

        case .hitWall:
            resultAnimation = input.animationID
            if forwardVelocity > 16 {
                queueRumble = true
                reflectedBonk = true

                if let wallAngle = input.wallAngle {
                    faceYaw = Int16(
                        truncatingIfNeeded: Int32(wallAngle) * 2
                            - Int32(faceYaw) + Int32(Int16(bitPattern: 0x8000))
                    )
                } else {
                    // mario_bonk_reflection(FALSE) and the following explicit
                    // +0x8000 cancel when no wall is retained by collision.
                    faceYaw = Int16(
                        truncatingIfNeeded: Int32(faceYaw)
                            + 0x1_0000
                    )
                }

                if input.wallAngle != nil {
                    intent = .airHitWall
                    action = SM64MarioActionID.airHitWall
                } else {
                    if velocityY > 0 { velocityY = 0 }
                    if forwardVelocity >= 38 {
                        intent = .backwardAirKnockback
                        action = SM64MarioActionID.backwardAirKnockback
                        verticalStar = true
                    } else {
                        if forwardVelocity > 8 { forwardVelocity = -8 }
                        intent = .softBonk
                        action = SM64MarioActionID.softBonk
                    }
                }
            } else {
                intent = .lowSpeedWallStop
                forwardVelocity = 0
            }

        case .grabbedLedge:
            intent = .ledgeGrab
            action = SM64MarioActionID.ledgeGrab
            resultAnimation = Self.idleOnLedgeAnimation
            dropHeldObject = true

        case .grabbedCeiling:
            intent = .hanging
            action = SM64MarioActionID.startHanging

        case .hitLavaWall:
            intent = .lavaWall
            action = SM64MarioActionID.lavaBoost
            lavaBoost = true
        }

        let velocity = SM64ObjectVector3(
            x: forwardVelocity * SM64CanonicalTrig.sins(faceYaw)
                + sidewaysSpeed * SM64CanonicalTrig.sins(
                    Int16(truncatingIfNeeded: Int32(faceYaw) + Int32(Int16(bitPattern: 0x4000)))
                ),
            y: velocityY,
            z: forwardVelocity * SM64CanonicalTrig.coss(faceYaw)
                + sidewaysSpeed * SM64CanonicalTrig.coss(
                    Int16(truncatingIfNeeded: Int32(faceYaw) + Int32(Int16(bitPattern: 0x4000)))
                )
        )

        return SM64MarioCommonAirActionResult(
            intent: intent, action: action, actionArgument: actionArgument,
            airStep: input.airStep, animationID: resultAnimation,
            faceYaw: faceYaw, forwardVelocity: forwardVelocity,
            velocity: velocity, shouldQueueRumble: queueRumble,
            particleVerticalStar: verticalStar,
            shouldReflectBonk: reflectedBonk,
            shouldDropHeldObject: dropHeldObject,
            shouldPlayLavaBoost: lavaBoost
        )
    }
}
