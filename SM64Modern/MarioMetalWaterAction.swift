import Foundation

enum SM64MarioMetalWaterVariant: UInt8, Equatable, Sendable {
    case standing = 0
    case heldStanding = 1
    case walking = 2
    case heldWalking = 3
    case jump = 4
    case heldJump = 5
    case falling = 6
    case heldFalling = 7
    case jumpLand = 8
    case heldJumpLand = 9
    case fallLand = 10
    case heldFallLand = 11
}

enum SM64MarioMetalWaterGroundOutcome: UInt8, Equatable, Sendable {
    case none = 0
    case leftGround = 1
    case hitWall = 2
}

enum SM64MarioMetalWaterAirOutcome: UInt8, Equatable, Sendable {
    case none = 0
    case landed = 1
    case hitWall = 2
}

enum SM64MarioMetalWaterIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case waterIdle = 1
    case holdWaterIdle = 2
    case metalWaterStanding = 3
    case holdMetalWaterStanding = 4
    case metalWaterWalking = 5
    case holdMetalWaterWalking = 6
    case metalWaterFalling = 7
    case holdMetalWaterFalling = 8
    case metalWaterJump = 9
    case holdMetalWaterJump = 10
    case metalWaterJumpLand = 11
    case holdMetalWaterJumpLand = 12
    case metalWaterFallLand = 13
    case holdMetalWaterFallLand = 14
    case waterJump = 15
    case holdWaterJump = 16
}

struct SM64MarioMetalWaterActionInput: Equatable, Sendable {
    let variant: SM64MarioMetalWaterVariant
    let input: SM64MarioInputFlags
    let metalCap: Bool
    let dropObjectRequested: Bool
    let actionSoundPlayed: Bool
    let animationAtEnd: Bool
    let animationPastFrame10Or49: Bool
    let actionArgument: UInt32
    let actionState: UInt8
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let facePitch: Int16
    let faceRoll: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let positionY: Float
    let waterLevel: Float
    let buoyancy: Float
    let floorNormalY: Float
    let groundStep: SM64MarioMetalWaterGroundOutcome
    let airStep: SM64MarioMetalWaterAirOutcome
    let waterStep: SM64MarioWaterStepOutcome
}

struct SM64MarioMetalWaterActionResult: Equatable, Sendable {
    let variant: SM64MarioMetalWaterVariant
    let intent: SM64MarioMetalWaterIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionState: UInt8
    let animationID: UInt16
    let animationAcceleration: Int32
    let faceYaw: Int16
    let facePitch: Int16
    let faceRoll: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let shouldDropHeldObject: Bool
    let shouldStopAtFloor: Bool
    let shouldStationarySlowDown: Bool
    let shouldPlayJumpSound: Bool
    let shouldPlayLandingSound: Bool
    let shouldParticleMistCircle: Bool
    let shouldPlayStepSound: Bool
    let shouldParticleDust: Bool
    let shouldParticleIdleWaterWave: Bool
}

/// Value counterpart of the metal-water action family in
/// `mario_actions_submerged.c`. Collision, animation/audio installation,
/// object drops, and particle delivery remain owner-thread effects.
enum SM64MarioMetalWaterAction {
    private static let idleHeadLeft: UInt16 = 0xC3
    private static let idleHeadRight: UInt16 = 0xC4
    private static let idleHeadCenter: UInt16 = 0xC5
    private static let idleWithLightObject: UInt16 = 0x3F
    private static let walking: UInt16 = 0x48
    private static let runWithLightObject: UInt16 = 0x17
    private static let singleJump: UInt16 = 0x4D
    private static let jumpWithLightObject: UInt16 = 0x41
    private static let generalFall: UInt16 = 0x56
    private static let fallFromWater: UInt16 = 0xA9
    private static let fallWithLightObject: UInt16 = 0x43
    private static let landFromSingleJump: UInt16 = 0x4E
    private static let jumpLandWithLightObject: UInt16 = 0x40
    private static let generalLand: UInt16 = 0x57
    private static let fallLandWithLightObject: UInt16 = 0x42

    static func update(
        _ input: SM64MarioMetalWaterActionInput
    ) -> SM64MarioMetalWaterActionResult? {
        guard finite(input) else { return nil }
        switch input.variant {
        case .standing: return standing(input, held: false)
        case .heldStanding: return standing(input, held: true)
        case .walking: return walking(input, held: false)
        case .heldWalking: return walking(input, held: true)
        case .jump: return jump(input, held: false)
        case .heldJump: return jump(input, held: true)
        case .falling: return falling(input, held: false)
        case .heldFalling: return falling(input, held: true)
        case .jumpLand: return landing(input, held: false, jump: true)
        case .heldJumpLand: return landing(input, held: true, jump: true)
        case .fallLand: return landing(input, held: false, jump: false)
        case .heldFallLand: return landing(input, held: true, jump: false)
        }
    }

    private static func standing(
        _ input: SM64MarioMetalWaterActionInput,
        held: Bool
    ) -> SM64MarioMetalWaterActionResult {
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .metalWaterStanding,
                action: SM64MarioActionID.metalWaterStanding,
                drop: true
            )
        }
        if !input.metalCap {
            return transition(
                input, intent: held ? .holdWaterIdle : .waterIdle,
                action: held ? SM64MarioActionID.holdWaterIdle : SM64MarioActionID.waterIdle,
                drop: false
            )
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: held ? .holdMetalWaterJump : .metalWaterJump,
                action: held ? SM64MarioActionID.holdMetalWaterJump
                    : SM64MarioActionID.metalWaterJump
            )
        }
        if input.input.contains(.nonzeroAnalog) {
            return transition(
                input, intent: held ? .holdMetalWaterWalking : .metalWaterWalking,
                action: held ? SM64MarioActionID.holdMetalWaterWalking
                    : SM64MarioActionID.metalWaterWalking
            )
        }

        var actionState = input.actionState
        let animation: UInt16
        if held {
            animation = Self.idleWithLightObject
        } else {
            switch actionState {
            case 1: animation = Self.idleHeadRight
            case 2: animation = Self.idleHeadCenter
            default: animation = Self.idleHeadLeft
            }
            if input.animationAtEnd {
                actionState &+= 1
                if actionState == 3 { actionState = 0 }
            }
        }
        return result(
            input, intent: .continueAction, action: nil, actionState: actionState,
            animationID: animation, forwardVelocity: 0,
            shouldStopAtFloor: true,
            shouldParticleIdleWaterWave: input.positionY >= input.waterLevel - 150
        )
    }

    private static func walking(
        _ input: SM64MarioMetalWaterActionInput,
        held: Bool
    ) -> SM64MarioMetalWaterActionResult {
        if !input.metalCap {
            return transition(
                input, intent: held ? .holdWaterIdle : .waterIdle,
                action: held ? SM64MarioActionID.holdWaterIdle : SM64MarioActionID.waterIdle
            )
        }
        if (!held && input.input.contains(.firstPerson))
            || input.input.contains(.unknown5) {
            return transition(
                input,
                intent: held ? .holdMetalWaterStanding : .metalWaterStanding,
                action: held ? SM64MarioActionID.holdMetalWaterStanding
                    : SM64MarioActionID.metalWaterStanding
            )
        }
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .metalWaterWalking,
                action: SM64MarioActionID.metalWaterWalking, drop: true
            )
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: held ? .holdMetalWaterJump : .metalWaterJump,
                action: held ? SM64MarioActionID.holdMetalWaterJump
                    : SM64MarioActionID.metalWaterJump
            )
        }

        let magnitude = held ? input.intendedMagnitude * 0.4 : input.intendedMagnitude
        let acceleration = Int32(max(
            Float(0x1000), input.forwardVelocity / (held ? 2 : 4) * 0x10000
        ))
        var forwardVelocity = input.forwardVelocity
        if forwardVelocity <= 0 {
            forwardVelocity += 1.1
        } else {
            let target = magnitude / 1.5
            if forwardVelocity <= target {
                forwardVelocity += 1.1 - forwardVelocity / 43
            } else if input.floorNormalY >= 0.95 {
                forwardVelocity -= 1
            }
        }
        forwardVelocity = min(forwardVelocity, 32)
        let yawDelta = Int32(Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)))
        let yaw = Int16(truncatingIfNeeded: Int32(input.intendedYaw)
            - SM64DeterministicPrimitives.approachS32(
                current: yawDelta, target: 0, increment: 0x800, decrement: 0x800
            ))
        var resultIntent: SM64MarioMetalWaterIntent = .continueAction
        var action: UInt32?
        var actionArgument: UInt32 = 0
        if input.groundStep == .leftGround {
            resultIntent = held ? .holdMetalWaterFalling : .metalWaterFalling
            action = held ? SM64MarioActionID.holdMetalWaterFalling
                : SM64MarioActionID.metalWaterFalling
            actionArgument = 1
        }
        if input.groundStep == .hitWall { forwardVelocity = 0 }
        return result(
            input, intent: resultIntent, action: action,
            actionArgument: actionArgument, animationID: held ? Self.runWithLightObject : Self.walking,
            animationAcceleration: acceleration, faceYaw: yaw,
            forwardVelocity: forwardVelocity,
            velocity: SM64ObjectVector3(
                x: forwardVelocity * SM64CanonicalTrig.sins(yaw), y: 0,
                z: forwardVelocity * SM64CanonicalTrig.coss(yaw)
            ),
            shouldPlayStepSound: input.animationPastFrame10Or49,
            shouldParticleDust: input.animationPastFrame10Or49
        )
    }

    private static func jump(
        _ input: SM64MarioMetalWaterActionInput,
        held: Bool
    ) -> SM64MarioMetalWaterActionResult {
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .metalWaterFalling,
                action: SM64MarioActionID.metalWaterFalling,
                drop: true
            )
        }
        if !input.metalCap {
            return transition(
                input, intent: held ? .holdWaterIdle : .waterIdle,
                action: held ? SM64MarioActionID.holdWaterIdle : SM64MarioActionID.waterIdle
            )
        }
        let waterSurface = input.waterLevel - 100
        if input.velocity.y > 0 && input.positionY > waterSurface {
            return transition(
                input, intent: held ? .holdWaterJump : .waterJump,
                action: held ? SM64MarioActionID.holdWaterJump : SM64MarioActionID.waterJump,
                argument: 1
            )
        }
        var forwardVelocity = input.forwardVelocity
        var faceYaw = input.faceYaw
        if input.input.contains(.nonzeroAnalog) {
            let intendedDYaw = Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(faceYaw))
            forwardVelocity += 0.8 * SM64CanonicalTrig.coss(intendedDYaw)
            faceYaw = faceYaw &+ Int16(truncatingIfNeeded: Int32(0x200) * Int32(SM64CanonicalTrig.sins(intendedDYaw)))
        } else {
            forwardVelocity = SM64DeterministicPrimitives.approachFloat(
                current: forwardVelocity, target: 0, increment: 0.25, decrement: 0.25
            )
        }
        if forwardVelocity > 16 { forwardVelocity -= 1 }
        if forwardVelocity < 0 { forwardVelocity += 2 }
        if input.airStep == .hitWall { forwardVelocity = 0 }
        let landed = input.airStep == .landed
        return result(
            input,
            intent: landed ? (held ? .holdMetalWaterJumpLand : .metalWaterJumpLand) : .continueAction,
            action: landed ? (held ? SM64MarioActionID.holdMetalWaterJumpLand
                : SM64MarioActionID.metalWaterJumpLand) : nil,
            animationID: held ? Self.jumpWithLightObject : Self.singleJump,
            faceYaw: faceYaw, forwardVelocity: forwardVelocity,
            velocity: SM64ObjectVector3(
                x: forwardVelocity * SM64CanonicalTrig.sins(faceYaw), y: input.velocity.y,
                z: forwardVelocity * SM64CanonicalTrig.coss(faceYaw)
            ),
            shouldPlayJumpSound: !input.actionSoundPlayed,
            shouldParticleMistCircle: !input.actionSoundPlayed
        )
    }

    private static func falling(
        _ input: SM64MarioMetalWaterActionInput,
        held: Bool
    ) -> SM64MarioMetalWaterActionResult {
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .metalWaterFalling,
                action: SM64MarioActionID.metalWaterFalling,
                drop: true
            )
        }
        if !input.metalCap {
            return transition(
                input, intent: held ? .holdWaterIdle : .waterIdle,
                action: held ? SM64MarioActionID.holdWaterIdle : SM64MarioActionID.waterIdle
            )
        }
        var faceYaw = input.faceYaw
        if input.input.contains(.nonzeroAnalog) {
            let delta = SM64CanonicalTrig.sins(
                Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(faceYaw))
            )
            faceYaw = faceYaw &+ Int16(truncatingIfNeeded: Int32(0x400) * Int32(delta))
        }
        let animation = held ? Self.fallWithLightObject
            : (input.actionArgument == 0 ? Self.generalFall : Self.fallFromWater)
        let slow = stationarySlowDown(input, faceYaw: faceYaw)
        let landed = input.waterStep == .hitFloor
        return result(
            input,
            intent: landed ? (held ? .holdMetalWaterFallLand : .metalWaterFallLand) : .continueAction,
            action: landed ? (held ? SM64MarioActionID.holdMetalWaterFallLand
                : SM64MarioActionID.metalWaterFallLand) : nil,
            animationID: animation, faceYaw: slow.faceYaw, facePitch: slow.facePitch,
            faceRoll: slow.faceRoll, forwardVelocity: slow.forwardVelocity,
            velocity: slow.velocity, shouldStationarySlowDown: true
        )
    }

    private static func landing(
        _ input: SM64MarioMetalWaterActionInput,
        held: Bool,
        jump: Bool
    ) -> SM64MarioMetalWaterActionResult {
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .metalWaterStanding,
                action: SM64MarioActionID.metalWaterStanding,
                drop: true, shouldPlayLandingSound: true,
                shouldParticleMistCircle: !input.actionSoundPlayed
            )
        }
        if !input.metalCap {
            return transition(
                input, intent: held ? .holdWaterIdle : .waterIdle,
                action: held ? SM64MarioActionID.holdWaterIdle : SM64MarioActionID.waterIdle,
                shouldPlayLandingSound: true,
                shouldParticleMistCircle: !input.actionSoundPlayed
            )
        }
        if input.input.contains(.nonzeroAnalog) {
            return transition(
                input,
                intent: held ? .holdMetalWaterWalking : .metalWaterWalking,
                action: held ? SM64MarioActionID.holdMetalWaterWalking
                    : SM64MarioActionID.metalWaterWalking,
                shouldPlayLandingSound: true,
                shouldParticleMistCircle: !input.actionSoundPlayed
            )
        }
        let animation = held
            ? (jump ? Self.jumpLandWithLightObject : Self.fallLandWithLightObject)
            : (jump ? Self.landFromSingleJump : Self.generalLand)
        return result(
            input,
            intent: input.animationAtEnd
                ? (held ? .holdMetalWaterStanding : .metalWaterStanding)
                : .continueAction,
            action: input.animationAtEnd
                ? (held ? SM64MarioActionID.holdMetalWaterStanding
                    : SM64MarioActionID.metalWaterStanding) : nil,
            animationID: animation, shouldStopAtFloor: true,
            shouldPlayLandingSound: true,
            shouldParticleMistCircle: !input.actionSoundPlayed
        )
    }

    private static func transition(
        _ input: SM64MarioMetalWaterActionInput,
        intent: SM64MarioMetalWaterIntent,
        action: UInt32?,
        argument: UInt32 = 0,
        drop: Bool = false,
        shouldPlayLandingSound: Bool = false,
        shouldParticleMistCircle: Bool = false
    ) -> SM64MarioMetalWaterActionResult {
        result(
            input, intent: intent, action: action, actionArgument: argument,
            shouldDropHeldObject: drop,
            shouldPlayLandingSound: shouldPlayLandingSound,
            shouldParticleMistCircle: shouldParticleMistCircle
        )
    }

    private static func stationarySlowDown(
        _ input: SM64MarioMetalWaterActionInput,
        faceYaw: Int16
    ) -> (faceYaw: Int16, facePitch: Int16, faceRoll: Int16,
          forwardVelocity: Float, velocity: SM64ObjectVector3) {
        let forwardVelocity = SM64DeterministicPrimitives.approachFloat(
            current: input.forwardVelocity, target: 0, increment: 1, decrement: 1
        )
        let velocityY = SM64DeterministicPrimitives.approachFloat(
            current: input.velocity.y, target: input.buoyancy, increment: 2, decrement: 1
        )
        let pitch = Int16(truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
            current: Int32(input.facePitch), target: 0, increment: 0x200, decrement: 0x200
        ))
        let roll = Int16(truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
            current: Int32(input.faceRoll), target: 0, increment: 0x100, decrement: 0x100
        ))
        return (
            faceYaw: faceYaw, facePitch: pitch, faceRoll: roll,
            forwardVelocity: forwardVelocity,
            velocity: SM64ObjectVector3(
                x: forwardVelocity * SM64CanonicalTrig.coss(pitch)
                    * SM64CanonicalTrig.sins(faceYaw),
                y: velocityY,
                z: forwardVelocity * SM64CanonicalTrig.coss(pitch)
                    * SM64CanonicalTrig.coss(faceYaw)
            )
        )
    }

    private static func result(
        _ input: SM64MarioMetalWaterActionInput,
        intent: SM64MarioMetalWaterIntent,
        action: UInt32?,
        actionArgument: UInt32 = 0,
        actionState: UInt8? = nil,
        animationID: UInt16 = 0,
        animationAcceleration: Int32 = 0,
        faceYaw: Int16? = nil,
        facePitch: Int16? = nil,
        faceRoll: Int16? = nil,
        forwardVelocity: Float? = nil,
        velocity: SM64ObjectVector3? = nil,
        shouldDropHeldObject: Bool = false,
        shouldStopAtFloor: Bool = false,
        shouldStationarySlowDown: Bool = false,
        shouldPlayJumpSound: Bool = false,
        shouldPlayLandingSound: Bool = false,
        shouldParticleMistCircle: Bool = false,
        shouldPlayStepSound: Bool = false,
        shouldParticleDust: Bool = false,
        shouldParticleIdleWaterWave: Bool = false
    ) -> SM64MarioMetalWaterActionResult {
        SM64MarioMetalWaterActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, actionState: actionState ?? input.actionState,
            animationID: animationID, animationAcceleration: animationAcceleration,
            faceYaw: faceYaw ?? input.faceYaw, facePitch: facePitch ?? input.facePitch,
            faceRoll: faceRoll ?? input.faceRoll,
            forwardVelocity: forwardVelocity ?? input.forwardVelocity,
            velocity: velocity ?? input.velocity,
            shouldDropHeldObject: shouldDropHeldObject,
            shouldStopAtFloor: shouldStopAtFloor,
            shouldStationarySlowDown: shouldStationarySlowDown,
            shouldPlayJumpSound: shouldPlayJumpSound,
            shouldPlayLandingSound: shouldPlayLandingSound,
            shouldParticleMistCircle: shouldParticleMistCircle,
            shouldPlayStepSound: shouldPlayStepSound,
            shouldParticleDust: shouldParticleDust,
            shouldParticleIdleWaterWave: shouldParticleIdleWaterWave
        )
    }

    private static func finite(_ input: SM64MarioMetalWaterActionInput) -> Bool {
        input.intendedMagnitude.isFinite && input.forwardVelocity.isFinite
            && input.velocity.x.isFinite && input.velocity.y.isFinite
            && input.velocity.z.isFinite && input.positionY.isFinite
            && input.waterLevel.isFinite && input.buoyancy.isFinite
            && input.floorNormalY.isFinite
    }
}
