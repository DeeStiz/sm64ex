import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ r: SM64MarioFinishTurningActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue); x = h32(x, r.action ?? UInt32.max); x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = hf(x, r.forwardVelocity)
    x = hf(x, r.velocity.x); x = hf(x, r.velocity.y); x = hf(x, r.velocity.z)
    x = h16(x, r.animationID ?? UInt16.max); x = h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
    x = h8(x, r.slope == nil ? 0 : 1)
    if let slope = r.slope { x = hf(x, slope.forwardVelocity); x = hf(x, slope.velocity.x); x = hf(x, slope.velocity.z) }
    return h16(x, UInt16(bitPattern: r.graphicsYawDelta))
}

private func input(
    flags: SM64MarioInputFlags = [],
    intendedMagnitude: Float = 20,
    intendedYaw: Int16 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 12,
    animationAtEnd: Bool = false,
    positionY: Float = 0
) -> SM64MarioFinishTurningActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: nil
    ), count: 4)
    return SM64MarioFinishTurningActionInput(
        input: flags, intendedMagnitude: intendedMagnitude, quicksandDepth: 0,
        floorNormalY: 1, floorIsSlow: false, responsiveCheat: false,
        cheatsEnabled: false, intendedYaw: intendedYaw, faceYaw: faceYaw,
        forwardVelocity: forwardVelocity, animationAtEnd: animationAtEnd,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        ),
        slope: SM64MarioSlopeInput(
            floorClass: .defaultClass, terrainIsSlide: false,
            floorNormalX: 0, floorNormalY: 1, floorNormalZ: 0,
            floorAngle: 0, faceYaw: faceYaw,
            forwardVelocity: forwardVelocity, action: SM64MarioActionID.finishTurningAround
        )
    )
}

@main
enum SM64ModernMarioFinishTurningSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let slide = SM64MarioFinishTurningAction.update(input(flags: [.aboveSlide]))!
        precondition(slide.intent == .beginSliding && slide.action == SM64MarioActionID.beginSliding)
        fingerprint = hash(fingerprint, slide)

        let sideFlip = SM64MarioFinishTurningAction.update(input(flags: [.aPressed]))!
        precondition(sideFlip.intent == .sideFlip && sideFlip.action == SM64MarioActionID.sideFlip)
        fingerprint = hash(fingerprint, sideFlip)

        let walking = SM64MarioFinishTurningAction.update(input())!
        precondition(walking.intent == .continueGround && walking.groundStep?.result == SM64MarioGroundStepOutcome.none)
        precondition(walking.forwardVelocity > 12 && walking.animationID == 0xBD)
        precondition(walking.graphicsYawDelta == Int16(bitPattern: 0x8000))
        fingerprint = hash(fingerprint, walking)

        let endWalking = SM64MarioFinishTurningAction.update(input(animationAtEnd: true))!
        precondition(endWalking.intent == .walking && endWalking.action == SM64MarioActionID.walking)
        fingerprint = hash(fingerprint, endWalking)

        let freefall = SM64MarioFinishTurningAction.update(input(positionY: 200))!
        precondition(freefall.intent == .freefall && freefall.action == SM64MarioActionID.freefall)
        fingerprint = hash(fingerprint, freefall)

        print(String(format: "marioFinishTurningFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario finish-turning smoke passed")
    }
}
