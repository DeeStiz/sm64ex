import Foundation

enum SM64MarioPoleHangingVariant: UInt8, Equatable, Sendable {
    case holdingPole = 0
    case climbingPole = 1
    case grabPoleSlow = 2
    case grabPoleFast = 3
    case topOfPoleTransition = 4
    case topOfPole = 5
    case startHanging = 6
    case hanging = 7
    case hangMoving = 8
}

enum SM64MarioPolePlacement: UInt8, Equatable, Sendable {
    case none = 0
    case touchedFloor = 1
    case fellOff = 2
    case softBonk = 3
}

enum SM64MarioHangStep: UInt8, Equatable, Sendable {
    case none = 0
    case hitCeilingOrOutOfBounds = 1
    case leftCeiling = 2
}

enum SM64MarioPoleHangingIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case idle = 1
    case freefall = 2
    case softBonk = 3
    case wallKickAir = 4
    case holdingPole = 5
    case climbingPole = 6
    case grabPoleSlow = 7
    case grabPoleFast = 8
    case topOfPoleTransition = 9
    case topOfPole = 10
    case topOfPoleJump = 11
    case hanging = 12
    case hangMoving = 13
    case groundPound = 14
}

struct SM64MarioPoleHangingActionInput: Equatable, Sendable {
    let variant: SM64MarioPoleHangingVariant
    let input: SM64MarioInputFlags
    let health: UInt16
    let marioSoundPlayed: Bool
    let stickX: Float
    let stickY: Float
    let cameraYaw: Int16
    let faceYaw: Int16
    let polePosition: Float
    let poleTop: Float
    let poleYawVelocity: Int16
    let actionArgument: UInt32
    let actionTimer: UInt16
    let animationAtEnd: Bool
    let animationFrame: Int16
    let poleIsGiant: Bool
    let polePlacement: SM64MarioPolePlacement
    let ceilingHangable: Bool
    let hangStep: SM64MarioHangStep
    let intendedYaw: Int16
    let ceilNormalY: Float
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
}

struct SM64MarioPoleHangingActionResult: Equatable, Sendable {
    let variant: SM64MarioPoleHangingVariant
    let intent: SM64MarioPoleHangingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let animationID: UInt16
    let animationAcceleration: Int32
    let faceYaw: Int16
    let polePosition: Float
    let poleYawVelocity: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let shouldQueueRumble: Bool
    let rumbleDistance: UInt16
    let shouldResetRumble: Bool
    let shouldPlayWhoa: Bool
    let shouldPlayClimbingSound: Bool
    let shouldPlayHangingStep: Bool
    let shouldAddTreeLeafParticles: Bool
    let shouldSyncGraphics: Bool
}

/// Value counterpart of the pole, ceiling-net, and hanging action callers in
/// `mario_actions_automatic.c`. Collision/object lookup, camera updates,
/// animation/audio installation, and effect delivery remain owner-thread
/// responsibilities.
enum SM64MarioPoleHangingAction {
    private static let idleOnPole: UInt16 = 0x0D
    private static let grabPoleShort: UInt16 = 0x06
    private static let grabPoleSwingPart1: UInt16 = 0x07
    private static let grabPoleSwingPart2: UInt16 = 0x08
    private static let climbUpPole: UInt16 = 0x05
    private static let startHandstand: UInt16 = 0x0B
    private static let handstandIdle: UInt16 = 0x09
    private static let returnFromHandstand: UInt16 = 0x0C
    private static let hangOnCeiling: UInt16 = 0x35
    private static let handstandLeft: UInt16 = 0xC6
    private static let handstandRight: UInt16 = 0xC7
    private static let moveOnWireNetLeft: UInt16 = 0x5C
    private static let moveOnWireNetRight: UInt16 = 0x5D

    static func update(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult? {
        guard input.stickX.isFinite, input.stickY.isFinite,
              input.polePosition.isFinite, input.poleTop.isFinite,
              input.ceilNormalY.isFinite, input.forwardVelocity.isFinite,
              input.velocity.x.isFinite, input.velocity.y.isFinite,
              input.velocity.z.isFinite else { return nil }
        switch input.variant {
        case .holdingPole: return holdingPole(input)
        case .climbingPole: return climbingPole(input)
        case .grabPoleSlow: return grabPoleSlow(input)
        case .grabPoleFast: return grabPoleFast(input)
        case .topOfPoleTransition: return topOfPoleTransition(input)
        case .topOfPole: return topOfPole(input)
        case .startHanging: return startHanging(input)
        case .hanging: return hanging(input)
        case .hangMoving: return hangMoving(input)
        }
    }

    private static func holdingPole(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        if input.input.contains(.zPressed) || input.health < 0x100 {
            return transition(input, intent: .softBonk, action: SM64MarioActionID.softBonk,
                              forwardVelocity: -2, leaves: true)
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: .wallKickAir, action: SM64MarioActionID.wallKickAir,
                faceYaw: input.faceYaw &+ Int16(bitPattern: 0x8000), leaves: true
            )
        }
        var polePosition = input.polePosition
        var poleYawVelocity: Int16 = 0
        var faceYaw = input.faceYaw
        var playClimbSound = false
        var resetRumble = false
        if input.stickY > 16 {
            if polePosition < input.poleTop - 0.4 {
                return transition(
                    input, intent: .climbingPole, action: SM64MarioActionID.climbingPole
                )
            }
            if !input.poleIsGiant && input.stickY > 50 {
                return transition(
                    input, intent: .topOfPoleTransition,
                    action: SM64MarioActionID.topOfPoleTransition
                )
            }
        }
        if input.stickY < -16 {
            poleYawVelocity = Int16(truncatingIfNeeded: Int32(input.poleYawVelocity)
                - Int32(input.stickY * 2))
            poleYawVelocity = min(poleYawVelocity, 0x1000)
            faceYaw = faceYaw &+ poleYawVelocity
            polePosition -= Float(poleYawVelocity) / 0x100
            playClimbSound = true
            resetRumble = true
        } else {
            faceYaw = faceYaw &- Int16(truncatingIfNeeded: Int32(input.stickX * 16))
        }
        let placed = placementResult(input, faceYaw: faceYaw, polePosition: polePosition)
        if placed != nil { return placed! }
        return result(
            input, intent: .continueAction, action: nil, animationID: Self.idleOnPole,
            faceYaw: faceYaw, polePosition: polePosition,
            poleYawVelocity: poleYawVelocity, shouldResetRumble: resetRumble,
            shouldPlayClimbingSound: playClimbSound, shouldSyncGraphics: true
        )
    }

    private static func climbingPole(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        if input.health < 0x100 {
            return transition(input, intent: .softBonk, action: SM64MarioActionID.softBonk,
                              forwardVelocity: -2, leaves: true)
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: .wallKickAir, action: SM64MarioActionID.wallKickAir,
                faceYaw: input.faceYaw &+ Int16(bitPattern: 0x8000), leaves: true
            )
        }
        if input.stickY < 8 {
            return transition(input, intent: .holdingPole, action: SM64MarioActionID.holdingPole)
        }
        let polePosition = input.polePosition + input.stickY / 8
        let faceYaw = Int16(truncatingIfNeeded: Int32(input.cameraYaw)
            - SM64DeterministicPrimitives.approachS32(
                current: Int32(Int16(truncatingIfNeeded: Int32(input.cameraYaw) - Int32(input.faceYaw))),
                target: 0, increment: 0x400, decrement: 0x400
            ))
        if let placed = placementResult(input, faceYaw: faceYaw, polePosition: polePosition) {
            return placed
        }
        return result(
            input, intent: .continueAction, action: nil, animationID: Self.climbUpPole,
            animationAcceleration: Int32(input.stickY / 4 * 0x10000), faceYaw: faceYaw,
            polePosition: polePosition, shouldPlayClimbingSound: true,
            shouldAddTreeLeafParticles: true, shouldSyncGraphics: true
        )
    }

    private static func grabPoleSlow(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        if let placed = placementResult(input, faceYaw: input.faceYaw,
                                        polePosition: input.polePosition) {
            return placed
        }
        return result(
            input,
            intent: input.animationAtEnd ? .holdingPole : .continueAction,
            action: input.animationAtEnd ? SM64MarioActionID.holdingPole : nil,
            animationID: Self.grabPoleShort,
            shouldPlayWhoa: !input.marioSoundPlayed,
            shouldAddTreeLeafParticles: true, shouldSyncGraphics: true
        )
    }

    private static func grabPoleFast(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        let faceYaw = input.faceYaw &+ input.poleYawVelocity
        let poleYawVelocity = Int16(truncatingIfNeeded: Int32(input.poleYawVelocity) * 8 / 10)
        if let placed = placementResult(input, faceYaw: faceYaw,
                                        polePosition: input.polePosition) {
            return placed
        }
        let swingPart1 = poleYawVelocity > 0x800
        return result(
            input,
            intent: !swingPart1 && input.animationAtEnd ? .holdingPole : .continueAction,
            action: !swingPart1 && input.animationAtEnd ? SM64MarioActionID.holdingPole : nil,
            animationID: swingPart1 ? Self.grabPoleSwingPart1 : Self.grabPoleSwingPart2,
            faceYaw: faceYaw,
            poleYawVelocity: !swingPart1 && input.animationAtEnd ? 0 : poleYawVelocity,
            shouldPlayWhoa: !input.marioSoundPlayed,
            shouldAddTreeLeafParticles: true, shouldSyncGraphics: true
        )
    }

    private static func topOfPoleTransition(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        let returning = input.actionArgument != 0
        let animation = returning ? Self.returnFromHandstand : Self.startHandstand
        let done = returning ? input.animationFrame == 0 : input.animationAtEnd
        return result(
            input,
            intent: done ? (returning ? .holdingPole : .topOfPole) : .continueAction,
            action: done ? (returning ? SM64MarioActionID.holdingPole
                : SM64MarioActionID.topOfPole) : nil,
            animationID: animation, poleYawVelocity: 0,
            shouldSyncGraphics: true
        )
    }

    private static func topOfPole(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        if input.input.contains(.aPressed) {
            return transition(input, intent: .topOfPoleJump,
                              action: SM64MarioActionID.topOfPoleJump)
        }
        if input.stickY < -16 {
            return transition(input, intent: .topOfPoleTransition,
                              action: SM64MarioActionID.topOfPoleTransition,
                              argument: 1)
        }
        let faceYaw = input.faceYaw &-
            Int16(truncatingIfNeeded: Int32(input.stickX * 16))
        return result(input, intent: .continueAction, action: nil,
                      animationID: Self.handstandIdle, faceYaw: faceYaw,
                      shouldSyncGraphics: true)
    }

    private static func startHanging(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        let timer = input.actionTimer &+ 1
        if input.input.contains(.nonzeroAnalog) && timer >= 31 {
            return transition(input, intent: .hanging, action: SM64MarioActionID.hanging,
                              actionTimer: 0)
        }
        if !input.input.contains(.aDown) {
            return transition(input, intent: .freefall, action: SM64MarioActionID.freefall)
        }
        if input.input.contains(.zPressed) {
            return transition(input, intent: .groundPound, action: SM64MarioActionID.groundPound)
        }
        if !input.ceilingHangable {
            return transition(input, intent: .freefall, action: SM64MarioActionID.freefall)
        }
        return result(
            input, intent: input.animationAtEnd ? .hanging : .continueAction,
            action: input.animationAtEnd ? SM64MarioActionID.hanging : nil,
            actionTimer: timer, animationID: Self.hangOnCeiling,
            shouldQueueRumble: input.actionTimer == 0, rumbleDistance: 80,
            shouldPlayHangingStep: !input.marioSoundPlayed,
            shouldSyncGraphics: true
        )
    }

    private static func hanging(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        if input.input.contains(.nonzeroAnalog) {
            return transition(input, intent: .hangMoving, action: SM64MarioActionID.hangMoving,
                              argument: input.actionArgument)
        }
        if !input.input.contains(.aDown) || !input.ceilingHangable {
            return transition(input, intent: .freefall, action: SM64MarioActionID.freefall)
        }
        if input.input.contains(.zPressed) {
            return transition(input, intent: .groundPound, action: SM64MarioActionID.groundPound)
        }
        return result(
            input, intent: .continueAction, action: nil,
            animationID: input.actionArgument & 1 != 0 ? Self.handstandLeft : Self.handstandRight,
            forwardVelocity: 0, velocity: .zero, shouldSyncGraphics: true
        )
    }

    private static func hangMoving(
        _ input: SM64MarioPoleHangingActionInput
    ) -> SM64MarioPoleHangingActionResult {
        if !input.input.contains(.aDown) || !input.ceilingHangable {
            return transition(input, intent: .freefall, action: SM64MarioActionID.freefall)
        }
        if input.input.contains(.zPressed) {
            return transition(input, intent: .groundPound, action: SM64MarioActionID.groundPound)
        }
        var actionArgument = input.actionArgument
        if input.animationAtEnd {
            actionArgument ^= 1
            if input.input.contains(.unknown5) {
                return transition(input, intent: .hanging, action: SM64MarioActionID.hanging,
                                  argument: actionArgument)
            }
        }
        let forwardVelocity = min(input.forwardVelocity + 1, 4)
        let yawDelta = Int32(Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)))
        let faceYaw = Int16(truncatingIfNeeded: Int32(input.intendedYaw)
            - SM64DeterministicPrimitives.approachS32(
                current: yawDelta, target: 0, increment: 0x800, decrement: 0x800
            ))
        let velocity = SM64ObjectVector3(
            x: forwardVelocity * SM64CanonicalTrig.sins(faceYaw), y: 0,
            z: forwardVelocity * SM64CanonicalTrig.coss(faceYaw)
        )
        if input.hangStep == .leftCeiling {
            return transition(input, intent: .freefall, action: SM64MarioActionID.freefall,
                              argument: 0, faceYaw: faceYaw,
                              forwardVelocity: forwardVelocity, velocity: velocity)
        }
        return result(
            input, intent: .continueAction, action: nil, actionArgument: actionArgument,
            animationID: actionArgument & 1 != 0 ? Self.moveOnWireNetRight : Self.moveOnWireNetLeft,
            faceYaw: faceYaw, forwardVelocity: forwardVelocity, velocity: velocity,
            shouldQueueRumble: input.animationFrame == 12, rumbleDistance: 30,
            shouldPlayHangingStep: input.animationFrame == 12,
            shouldSyncGraphics: true
        )
    }

    private static func placementResult(
        _ input: SM64MarioPoleHangingActionInput,
        faceYaw: Int16,
        polePosition: Float
    ) -> SM64MarioPoleHangingActionResult? {
        switch input.polePlacement {
        case .none: return nil
        case .touchedFloor:
            return transition(input, intent: .idle, action: SM64MarioActionID.idle,
                              faceYaw: faceYaw, polePosition: polePosition)
        case .fellOff:
            return transition(input, intent: .freefall, action: SM64MarioActionID.freefall,
                              faceYaw: faceYaw, polePosition: polePosition)
        case .softBonk:
            return transition(input, intent: .softBonk, action: SM64MarioActionID.softBonk,
                              faceYaw: faceYaw, polePosition: polePosition,
                              forwardVelocity: -2)
        }
    }

    private static func transition(
        _ input: SM64MarioPoleHangingActionInput,
        intent: SM64MarioPoleHangingIntent,
        action: UInt32?,
        argument: UInt32 = 0,
        actionTimer: UInt16? = nil,
        animationID: UInt16 = 0,
        animationAcceleration: Int32 = 0,
        faceYaw: Int16? = nil,
        polePosition: Float? = nil,
        poleYawVelocity: Int16? = nil,
        forwardVelocity: Float? = nil,
        velocity: SM64ObjectVector3? = nil,
        leaves: Bool = false
    ) -> SM64MarioPoleHangingActionResult {
        result(
            input, intent: intent, action: action, actionArgument: argument,
            actionTimer: actionTimer, animationID: animationID,
            animationAcceleration: animationAcceleration, faceYaw: faceYaw,
            polePosition: polePosition, poleYawVelocity: poleYawVelocity,
            forwardVelocity: forwardVelocity, velocity: velocity,
            shouldAddTreeLeafParticles: leaves
        )
    }

    private static func result(
        _ input: SM64MarioPoleHangingActionInput,
        intent: SM64MarioPoleHangingIntent,
        action: UInt32?,
        actionArgument: UInt32 = 0,
        actionTimer: UInt16? = nil,
        animationID: UInt16 = 0,
        animationAcceleration: Int32 = 0,
        faceYaw: Int16? = nil,
        polePosition: Float? = nil,
        poleYawVelocity: Int16? = nil,
        forwardVelocity: Float? = nil,
        velocity: SM64ObjectVector3? = nil,
        shouldQueueRumble: Bool = false,
        rumbleDistance: UInt16 = 0,
        shouldResetRumble: Bool = false,
        shouldPlayWhoa: Bool = false,
        shouldPlayClimbingSound: Bool = false,
        shouldPlayHangingStep: Bool = false,
        shouldAddTreeLeafParticles: Bool = false,
        shouldSyncGraphics: Bool = false
    ) -> SM64MarioPoleHangingActionResult {
        SM64MarioPoleHangingActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, actionTimer: actionTimer ?? input.actionTimer,
            animationID: animationID, animationAcceleration: animationAcceleration,
            faceYaw: faceYaw ?? input.faceYaw, polePosition: polePosition ?? input.polePosition,
            poleYawVelocity: poleYawVelocity ?? input.poleYawVelocity,
            forwardVelocity: forwardVelocity ?? input.forwardVelocity,
            velocity: velocity ?? input.velocity, shouldQueueRumble: shouldQueueRumble,
            rumbleDistance: rumbleDistance, shouldResetRumble: shouldResetRumble,
            shouldPlayWhoa: shouldPlayWhoa, shouldPlayClimbingSound: shouldPlayClimbingSound,
            shouldPlayHangingStep: shouldPlayHangingStep,
            shouldAddTreeLeafParticles: shouldAddTreeLeafParticles,
            shouldSyncGraphics: shouldSyncGraphics
        )
    }
}
