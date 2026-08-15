import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioSwimmingActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h8(x, r.actionState)
    x = h16(x, UInt16(bitPattern: r.swimStrength))
    x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h16(x, UInt16(bitPattern: r.facePitch))
    x = h16(x, UInt16(bitPattern: r.faceRoll))
    x = h16(x, UInt16(bitPattern: r.angleVelocityY))
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldPlaySwimmingSound ? 1 : 0)
    x = h8(x, r.shouldPlayFastSwimmingSound ? 1 : 0)
    x = h8(x, r.shouldPlaySwimmingNoise ? 1 : 0)
    x = h8(x, r.shouldResetFloatGlobals ? 1 : 0)
    return h8(x, r.shouldPlayWaterStep ? 1 : 0)
}

private func input(
    _ variant: SM64MarioSwimmingVariant,
    flags: SM64MarioInputFlags = [],
    actionArgument: UInt32 = 0,
    actionTimer: UInt16 = 0,
    actionState: UInt8 = 0,
    swimStrength: Int16 = 160,
    stickX: Float = 0,
    stickY: Float = 0,
    faceYaw: Int16 = 0,
    facePitch: Int16 = 0,
    faceRoll: Int16 = 0,
    angleVelocityY: Int16 = 0,
    forwardVelocity: Float = 10,
    buoyancy: Float = 1.25,
    floorPitch: Int16? = nil,
    waterStep: SM64MarioWaterStepOutcome = .none,
    metalCap: Bool = false,
    dropObjectRequested: Bool = false,
    waterJumpReady: Bool = false
) -> SM64MarioSwimmingActionInput {
    SM64MarioSwimmingActionInput(
        variant: variant, input: flags, actionArgument: actionArgument,
        actionTimer: actionTimer, actionState: actionState,
        swimStrength: swimStrength, stickX: stickX, stickY: stickY,
        faceYaw: faceYaw, facePitch: facePitch, faceRoll: faceRoll,
        angleVelocityY: angleVelocityY, forwardVelocity: forwardVelocity,
        buoyancy: buoyancy, floorPitch: floorPitch, waterStep: waterStep,
        metalCap: metalCap, dropObjectRequested: dropObjectRequested,
        waterJumpReady: waterJumpReady
    )
}

@main
enum SM64ModernMarioSwimmingSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let breast = SM64MarioSwimmingAction.update(input(.breaststroke))!
        precondition(breast.actionTimer == 1 && breast.animationID == 0xAA)
        precondition(breast.swimStrength == 160 && breast.shouldPlaySwimmingSound)
        precondition(breast.forwardVelocity > 10 && breast.shouldResetFloatGlobals)
        fingerprint = hash(fingerprint, breast)

        let punch = SM64MarioSwimmingAction.update(input(
            .breaststroke, flags: [.bPressed]
        ))!
        precondition(punch.intent == .waterPunch && punch.action == SM64MarioActionID.waterPunch)
        fingerprint = hash(fingerprint, punch)

        let waterJump = SM64MarioSwimmingAction.update(input(
            .breaststroke, waterJumpReady: true
        ))!
        precondition(waterJump.intent == .waterJump && waterJump.action == SM64MarioActionID.waterJump)
        fingerprint = hash(fingerprint, waterJump)

        let endStroke = SM64MarioSwimmingAction.update(input(
            .swimmingEnd, flags: [.aDown], actionTimer: 7, swimStrength: 160
        ))!
        precondition(endStroke.intent == .breaststroke && endStroke.actionArgument == 1)
        precondition(endStroke.swimStrength == 170)
        fingerprint = hash(fingerprint, endStroke)

        let flutter = SM64MarioSwimmingAction.update(input(
            .flutterKick, actionTimer: 0, swimStrength: 160
        ))!
        precondition(flutter.intent == .swimmingEnd && flutter.action == SM64MarioActionID.swimmingEnd)
        precondition(flutter.swimStrength == 170)
        fingerprint = hash(fingerprint, flutter)

        let holdDrop = SM64MarioSwimmingAction.update(input(
            .holdBreaststroke, dropObjectRequested: true
        ))!
        precondition(holdDrop.intent == .holdWaterIdle && holdDrop.action == SM64MarioActionID.waterIdle)
        precondition(holdDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, holdDrop)

        let holdJump = SM64MarioSwimmingAction.update(input(
            .holdBreaststroke, waterJumpReady: true
        ))!
        precondition(holdJump.intent == .holdWaterJump && holdJump.action == SM64MarioActionID.holdWaterJump)
        fingerprint = hash(fingerprint, holdJump)

        let holdFlutter = SM64MarioSwimmingAction.update(input(
            .holdFlutterKick, flags: [.aDown], forwardVelocity: 10
        ))!
        precondition(holdFlutter.animationID == 0xA1 && holdFlutter.shouldPlaySwimmingNoise)
        fingerprint = hash(fingerprint, holdFlutter)

        let wall = SM64MarioSwimmingAction.update(input(
            .breaststroke, facePitch: 0x1000, waterStep: .hitWall
        ))!
        precondition(wall.facePitch == 0x1000)
        fingerprint = hash(fingerprint, wall)

        let ceiling = SM64MarioSwimmingAction.update(input(
            .breaststroke, facePitch: -0x2000, waterStep: .hitCeiling
        ))!
        precondition(ceiling.facePitch == -0x2000)
        fingerprint = hash(fingerprint, ceiling)

        precondition(SM64MarioSwimmingAction.update(input(
            .breaststroke, forwardVelocity: .infinity
        )) == nil)

        print(String(format: "marioSwimmingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario swimming smoke passed")
    }
}
