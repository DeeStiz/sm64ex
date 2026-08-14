import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hashU8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func hashU16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hashU32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hashFloat(_ h: UInt64, _ v: Float) -> UInt64 { hashU32(h, v.bitPattern) }

private func hashResult(_ h: UInt64, _ result: SM64MarioMovePunchActionResult) -> UInt64 {
    var x = hashU8(h, result.intent.rawValue)
    x = hashU32(x, result.action ?? UInt32.max)
    x = hashU32(x, result.actionArgument)
    x = hashU16(x, result.actionState)
    x = hashU16(x, UInt16(bitPattern: result.faceYaw))
    x = hashFloat(x, result.forwardVelocity)
    x = hashFloat(x, result.velocity.x)
    x = hashFloat(x, result.velocity.y)
    x = hashFloat(x, result.velocity.z)
    if let punch = result.punch {
        x = hashU8(x, 1)
        x = hashU32(x, punch.actionArgument)
        x = hashU16(x, punch.animationID)
        x = hashU32(x, punch.transitionAction ?? UInt32.max)
        x = hashU32(x, punch.flags)
        x = hashU8(x, punch.punchState ?? UInt8.max)
        x = hashU8(x, punch.sound.rawValue)
    } else {
        x = hashU8(x, 0)
    }
    x = hashU8(x, result.slope == nil ? 0 : 1)
    if let slope = result.slope {
        x = hashFloat(x, slope.forwardVelocity)
        x = hashFloat(x, slope.velocity.x)
        x = hashFloat(x, slope.velocity.z)
    }
    x = hashU8(x, result.groundStep?.result.rawValue ?? UInt8.max)
    x = hashU8(x, result.particleDust ? 1 : 0)
    return x
}

private func baseInput(
    input: SM64MarioInputFlags = [.bPressed],
    actionState: UInt16 = 0,
    actionArgument: UInt32 = 0,
    animationFrame: Int16 = 2,
    animationAtEnd: Bool = false,
    animationPastEnd: Bool = false,
    floorNormalX: Float = 0,
    floorNormalY: Float = 1,
    floorNormalZ: Float = 0,
    floorClass: SM64MarioFloorClass = .defaultClass,
    forwardVelocity: Float = 12
) -> SM64MarioMovePunchActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: nil
    ), count: 4)
    return SM64MarioMovePunchActionInput(
        input: input,
        terrainIsSlide: false,
        facingDownhill: false,
        actionState: actionState,
        actionArgument: actionArgument,
        animationFrame: animationFrame,
        animationAtEnd: animationAtEnd,
        animationPastEnd: animationPastEnd,
        floorClass: floorClass,
        floorNormalX: floorNormalX,
        floorNormalY: floorNormalY,
        floorNormalZ: floorNormalZ,
        floorAngle: 0,
        faceYaw: 0,
        forwardVelocity: forwardVelocity,
        groundStep: SM64MarioGroundStepInput(
            position: .zero,
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor,
            faceYaw: 0,
            nativeStepScale: 1,
            ridingShell: false,
            terrainSoundAddend: 0,
            quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioMovePunchSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let first = SM64MarioMovePunchAction.update(baseInput())!
        precondition(first.intent == .continueGround)
        precondition(first.action == nil)
        precondition(first.actionState == 1)
        precondition(first.punch?.animationID == SM64MarioPunchAnimationID.firstPunch)
        precondition(first.particleDust)
        fingerprint = hashResult(fingerprint, first)

        let fastEnd = SM64MarioMovePunchAction.update(baseInput(
            actionArgument: 2, animationFrame: 3, animationAtEnd: true
        ))!
        precondition(fastEnd.action == SM64MarioActionID.walking)
        precondition(fastEnd.actionState == 0)
        fingerprint = hashResult(fingerprint, fastEnd)

        let slide = SM64MarioMovePunchAction.update(baseInput(
            input: [.aboveSlide], forwardVelocity: -2
        ))!
        precondition(slide.intent == .beginSliding)
        precondition(slide.action == SM64MarioActionID.beginSliding)
        fingerprint = hashResult(fingerprint, slide)

        let kick = SM64MarioMovePunchAction.update(baseInput(
            input: [.aDown], actionState: 0
        ))!
        precondition(kick.intent == .jumpKick)
        precondition(kick.action == SM64MarioActionID.jumpKick)
        precondition(kick.velocity.y == 20)
        fingerprint = hashResult(fingerprint, kick)

        let negative = SM64MarioMovePunchAction.update(baseInput(
            floorNormalX: 0.6, floorNormalY: 0.8, forwardVelocity: -4
        ))!
        precondition(negative.forwardVelocity > 1 && negative.forwardVelocity < 2 && negative.slope != nil)
        fingerprint = hashResult(fingerprint, negative)

        let leftGroundInput = baseInput()
        let leftGround = SM64MarioMovePunchAction.update(SM64MarioMovePunchActionInput(
            input: leftGroundInput.input,
            terrainIsSlide: leftGroundInput.terrainIsSlide,
            facingDownhill: leftGroundInput.facingDownhill,
            actionState: leftGroundInput.actionState,
            actionArgument: leftGroundInput.actionArgument,
            animationFrame: leftGroundInput.animationFrame,
            animationAtEnd: leftGroundInput.animationAtEnd,
            animationPastEnd: leftGroundInput.animationPastEnd,
            floorClass: leftGroundInput.floorClass,
            floorNormalX: leftGroundInput.floorNormalX,
            floorNormalY: leftGroundInput.floorNormalY,
            floorNormalZ: leftGroundInput.floorNormalZ,
            floorAngle: leftGroundInput.floorAngle,
            faceYaw: leftGroundInput.faceYaw,
            forwardVelocity: leftGroundInput.forwardVelocity,
            groundStep: SM64MarioGroundStepInput(
                position: SM64ObjectVector3(x: 0, y: 200, z: 0),
                velocity: SM64ObjectVector3(x: 0, y: 0, z: 12),
                floor: leftGroundInput.groundStep.floor,
                faceYaw: 0,
                nativeStepScale: 1,
                ridingShell: false,
                terrainSoundAddend: 0,
                quarterProbes: Array(repeating: SM64MarioGroundQuarterProbe(
                    floor: leftGroundInput.groundStep.floor,
                    ceilingHeight: 1000, waterLevel: 0, upperWall: nil
                ), count: 4)
            )
        ))!
        precondition(leftGround.intent == .freefall)
        precondition(leftGround.action == SM64MarioActionID.freefall)
        fingerprint = hashResult(fingerprint, leftGround)

        print(String(format: "marioMovePunchFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario move-punch smoke passed")
    }
}
