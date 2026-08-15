import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioBurningGroundActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.burnTimer)
    x = h16(x, r.health)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h16(x, r.animationID ?? UInt16.max)
    x = h32(x, UInt32(bitPattern: r.animationAcceleration ?? Int32.min))
    x = h8(x, r.particleFire ? 1 : 0)
    x = h8(x, r.eyeStateDead ? 1 : 0)
    x = h8(x, r.shouldResetRumble ? 1 : 0)
    x = h8(x, r.shouldPlayStepSound ? 1 : 0)
    x = h8(x, r.sound?.rawValue ?? UInt8.max)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    flags: SM64MarioInputFlags = [],
    burnTimer: UInt16 = 10,
    waterLevel: Float = 0,
    floorHeight: Float = 0,
    forwardVelocity: Float = 20,
    intendedMagnitude: Float = 0,
    intendedYaw: Int16 = 0,
    faceYaw: Int16 = 0,
    health: UInt16 = 0x1000,
    positionY: Float = 0
) -> SM64MarioBurningGroundActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: waterLevel, upperWall: nil
    ), count: 4)
    return SM64MarioBurningGroundActionInput(
        input: flags, burnTimer: burnTimer, waterLevel: waterLevel,
        floorHeight: floorHeight, forwardVelocity: forwardVelocity,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        faceYaw: faceYaw, health: health,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        ), slope: nil
    )
}

@main
enum SM64ModernMarioBurningGroundSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let jump = SM64MarioBurningGroundAction.update(input(flags: [.aPressed]))!
        precondition(jump.intent == .burningJump && jump.action == SM64MarioActionID.burningJump)
        precondition(jump.burnTimer == 10 && jump.health == 0x1000)
        fingerprint = hash(fingerprint, jump)

        let expired = SM64MarioBurningGroundAction.update(input(burnTimer: 160))!
        precondition(expired.intent == .expired && expired.action == SM64MarioActionID.walking)
        precondition(expired.burnTimer == 162)
        fingerprint = hash(fingerprint, expired)

        let water = SM64MarioBurningGroundAction.update(input(
            burnTimer: 10, waterLevel: 60, floorHeight: 0
        ))!
        precondition(water.intent == .extinguished && water.sound == .flameOut)
        precondition(water.action == SM64MarioActionID.walking)
        fingerprint = hash(fingerprint, water)

        let active = SM64MarioBurningGroundAction.update(input())!
        precondition(active.intent == .continueGround && active.action == nil)
        precondition(active.forwardVelocity == 24)
        precondition(active.animationID == 0x72 && active.animationAcceleration == 0xC0000)
        precondition(active.particleFire && active.eyeStateDead && active.shouldResetRumble)
        precondition(active.sound == .lavaBurn && active.groundStep?.result == SM64MarioGroundStepOutcome.none)
        fingerprint = hash(fingerprint, active)

        let fall = SM64MarioBurningGroundAction.update(input(positionY: 200))!
        precondition(fall.intent == .burningFall && fall.action == SM64MarioActionID.burningFall)
        fingerprint = hash(fingerprint, fall)

        let death = SM64MarioBurningGroundAction.update(input(health: 0x105))!
        precondition(death.intent == .death && death.action == SM64MarioActionID.standingDeath)
        precondition(death.health == 0xFB)
        fingerprint = hash(fingerprint, death)

        precondition(SM64MarioBurningGroundAction.update(input(forwardVelocity: .infinity)) == nil)

        print(String(format: "marioBurningGroundFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario burning-ground smoke passed")
    }
}
