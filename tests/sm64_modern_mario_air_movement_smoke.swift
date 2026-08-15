import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioAirMovementActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.animationID)
    x = h8(x, r.sound.rawValue)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.shouldFlipGraphicsYaw ? 1 : 0)
    x = h8(x, r.shouldPlaySideFlipFrameSound ? 1 : 0)
    x = h8(x, r.shouldPlayHereWeGoSound ? 1 : 0)
    return h8(x, r.common?.intent.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioAirMovementVariant,
    flags: SM64MarioInputFlags = [],
    velocityY: Float = 10,
    airStep: SM64MarioCommonAirStepOutcome = .none,
    longJumpSlow: Bool = false,
    verticalWindActive: Bool = false,
    actionStateZero: Bool = false,
    animationFrame: Int16 = 0
) -> SM64MarioAirMovementActionInput {
    SM64MarioAirMovementActionInput(
        variant: variant,
        commonInput: SM64MarioCommonAirActionInput(
            landAction: SM64MarioActionID.jumpLand, animationID: 0,
            input: flags, intendedMagnitude: 0, intendedYaw: 0,
            faceYaw: 0, forwardVelocity: 20, velocityY: velocityY,
            wallAngle: nil, airStep: airStep, fallDamageOrStuck: false,
            horizontalWindActive: false
        ), longJumpSlow: longJumpSlow,
        verticalWindActive: verticalWindActive,
        actionStateZero: actionStateZero, animationFrame: animationFrame
    )
}

@main
enum SM64ModernMarioAirMovementSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let side = SM64MarioAirMovementAction.update(input(
            .sideFlip, animationFrame: 6
        ))!
        precondition(side.animationID == 0xBF && side.sound == .terrainJump)
        precondition(side.shouldFlipGraphicsYaw && side.shouldPlaySideFlipFrameSound)
        fingerprint = hash(fingerprint, side)

        let sideLedge = SM64MarioAirMovementAction.update(input(
            .sideFlip, airStep: .grabbedLedge
        ))!
        precondition(!sideLedge.shouldFlipGraphicsYaw)
        fingerprint = hash(fingerprint, sideLedge)

        let wallKick = SM64MarioAirMovementAction.update(input(
            .wallKick, flags: [.bPressed]
        ))!
        precondition(wallKick.intent == .preempt && wallKick.action == SM64MarioActionID.dive)
        fingerprint = hash(fingerprint, wallKick)

        let wallKickStep = SM64MarioAirMovementAction.update(input(
            .wallKick, airStep: .landed
        ))!
        precondition(wallKickStep.action == SM64MarioActionID.jumpLand)
        precondition(wallKickStep.animationID == 0xCB && wallKickStep.sound == .jump)
        fingerprint = hash(fingerprint, wallKickStep)

        let longFast = SM64MarioAirMovementAction.update(input(
            .longJump, airStep: .landed, verticalWindActive: true,
            actionStateZero: true
        ))!
        precondition(longFast.animationID == 0x13 && longFast.sound == .yahoo)
        precondition(longFast.shouldQueueRumble && longFast.shouldPlayHereWeGoSound)
        fingerprint = hash(fingerprint, longFast)

        let longSlow = SM64MarioAirMovementAction.update(input(
            .longJump, longJumpSlow: true
        ))!
        precondition(longSlow.animationID == 0x14)
        fingerprint = hash(fingerprint, longSlow)

        let longZ = SM64MarioAirMovementAction.update(input(
            .longJump, flags: [.zPressed]
        ))!
        precondition(longZ.intent == .commonStep)
        fingerprint = hash(fingerprint, longZ)

        print(String(format: "marioAirMovementFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario air-movement smoke passed")
    }
}
