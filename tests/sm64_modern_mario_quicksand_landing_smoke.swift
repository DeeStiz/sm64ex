import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioQuicksandLandingActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h16(x, r.animationID)
    x = h8(x, r.shouldPlayJumpSound ? 1 : 0)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioQuicksandLandingVariant,
    actionTimer: UInt16 = 0,
    quicksandDepth: Float = 8,
    forwardVelocity: Float = 10,
    positionY: Float = 0
) -> SM64MarioQuicksandLandingActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: nil
    ), count: 4)
    return SM64MarioQuicksandLandingActionInput(
        variant: variant, actionTimer: actionTimer,
        quicksandDepth: quicksandDepth, floorClass: .defaultClass,
        terrainIsSlide: false, floorNormalX: 0, floorNormalY: 1,
        floorNormalZ: 0, floorAngle: 0, faceYaw: 0,
        forwardVelocity: forwardVelocity,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: 0, nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioQuicksandLandingSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let lightJump = SM64MarioQuicksandLandingAction.update(input(.light))!
        precondition(lightJump.intent == .continueGround && lightJump.animationID == 0x4D)
        precondition(lightJump.shouldPlayJumpSound && lightJump.actionTimer == 1)
        fingerprint = hash(fingerprint, lightJump)

        let lightLand = SM64MarioQuicksandLandingAction.update(input(
            .light, actionTimer: 6, quicksandDepth: 2
        ))!
        precondition(lightLand.animationID == 0x4E && !lightLand.shouldPlayJumpSound)
        fingerprint = hash(fingerprint, lightLand)

        let lightEnd = SM64MarioQuicksandLandingAction.update(input(
            .light, actionTimer: 12, quicksandDepth: 2
        ))!
        precondition(lightEnd.intent == .endLanding && lightEnd.action == SM64MarioActionID.jumpLandStop)
        fingerprint = hash(fingerprint, lightEnd)

        let heldJump = SM64MarioQuicksandLandingAction.update(input(.held))!
        precondition(heldJump.animationID == 0x41 && heldJump.shouldPlayJumpSound)
        fingerprint = hash(fingerprint, heldJump)

        let heldEnd = SM64MarioQuicksandLandingAction.update(input(
            .held, actionTimer: 12
        ))!
        precondition(heldEnd.intent == .endLanding && heldEnd.action == SM64MarioActionID.holdJumpLandStop)
        fingerprint = hash(fingerprint, heldEnd)

        let fall = SM64MarioQuicksandLandingAction.update(input(.light, positionY: 200))!
        precondition(fall.intent == .freefall && fall.action == SM64MarioActionID.freefall)
        fingerprint = hash(fingerprint, fall)

        precondition(SM64MarioQuicksandLandingAction.update(input(.light, quicksandDepth: .infinity)) == nil)

        print(String(format: "marioQuicksandLandingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario quicksand-landing smoke passed")
    }
}
