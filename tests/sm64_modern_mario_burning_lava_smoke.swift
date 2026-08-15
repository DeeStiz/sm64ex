import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioBurningLavaActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h16(x, r.burnTimer)
    x = h16(x, r.health)
    x = h8(x, r.hurtCounter)
    x = h8(x, r.actionState)
    x = h8(x, r.sound.rawValue)
    x = h8(x, r.shouldPlayLandingSound ? 1 : 0)
    x = h8(x, r.shouldPlayOnFireSound ? 1 : 0)
    x = h8(x, r.shouldPlayMovingLavaBurn ? 1 : 0)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.shouldResetRumble ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldParticleFire ? 1 : 0)
    x = h8(x, r.shouldSetEyesDead ? 1 : 0)
    x = h8(x, r.shouldReflectBonk ? 1 : 0)
    return h8(x, r.shouldTriggerDeathWarp ? 1 : 0)
}

private func input(
    _ variant: SM64MarioBurningLavaVariant,
    flags: SM64MarioInputFlags = [],
    actionArgument: UInt32 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 20,
    velocityY: Float = -10,
    intendedMagnitude: Float = 0,
    intendedYaw: Int16 = 0,
    wallAngle: Int16? = nil,
    airStep: SM64MarioCommonAirStepOutcome = .none,
    burnTimer: UInt16 = 10,
    health: UInt16 = 0x880,
    hurtCounter: UInt8 = 0,
    actionState: UInt8 = 0,
    floorIsBurning: Bool = false,
    metalCap: Bool = false,
    capOnHead: Bool = true,
    terrainIsSnow: Bool = false,
    marioSoundPlayed: Bool = false
) -> SM64MarioBurningLavaActionInput {
    SM64MarioBurningLavaActionInput(
        variant: variant, input: flags, actionArgument: actionArgument,
        faceYaw: faceYaw, forwardVelocity: forwardVelocity, velocityY: velocityY,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        wallAngle: wallAngle, airStep: airStep, burnTimer: burnTimer,
        health: health, hurtCounter: hurtCounter, actionState: actionState,
        floorIsBurning: floorIsBurning, metalCap: metalCap,
        capOnHead: capOnHead, terrainIsSnow: terrainIsSnow,
        marioSoundPlayed: marioSoundPlayed
    )
}

@main
enum SM64ModernMarioBurningLavaSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let jump = SM64MarioBurningLavaAction.update(input(.burningJump))!
        precondition(jump.animationID == 0x4D && jump.burnTimer == 13)
        precondition(jump.health == 0x876 && jump.shouldParticleFire && jump.shouldResetRumble)
        fingerprint = hash(fingerprint, jump)

        let jumpLand = SM64MarioBurningLavaAction.update(input(
            .burningJump, actionArgument: 1, airStep: .landed, health: 0x100
        ))!
        precondition(jumpLand.animationID == 0x29 && jumpLand.action == SM64MarioActionID.burningGround)
        precondition(jumpLand.health == 0xFF && jumpLand.shouldPlayLandingSound)
        fingerprint = hash(fingerprint, jumpLand)

        let fall = SM64MarioBurningLavaAction.update(input(
            .burningFall, velocityY: -20
        ))!
        precondition(fall.animationID == 0x56 && !fall.shouldPlayMovingLavaBurn)
        fingerprint = hash(fingerprint, fall)

        let bounce = SM64MarioBurningLavaAction.update(input(
            .lavaBoost, velocityY: -20, airStep: .landed, actionState: 0,
            marioSoundPlayed: true
        ))!
        precondition(bounce.intent == .lavaBounce && bounce.velocity.y == 8)
        precondition(abs(bounce.forwardVelocity - 9.825) < 0.0001 && bounce.actionState == 1)
        fingerprint = hash(fingerprint, bounce)

        let land = SM64MarioBurningLavaAction.update(input(
            .lavaBoost, velocityY: -20, airStep: .landed, actionState: 2,
            marioSoundPlayed: true
        ))!
        precondition(land.intent == .lavaBoostLand && land.action == SM64MarioActionID.lavaBoostLand)
        fingerprint = hash(fingerprint, land)

        let burningFloor = SM64MarioBurningLavaAction.update(input(
            .lavaBoost, velocityY: -20, airStep: .landed, floorIsBurning: true,
            capOnHead: true, marioSoundPlayed: true
        ))!
        precondition(burningFloor.velocity.y == 84 && burningFloor.hurtCounter == 12)
        precondition(burningFloor.shouldQueueRumble && burningFloor.shouldPlayOnFireSound)
        fingerprint = hash(fingerprint, burningFloor)

        let wall = SM64MarioBurningLavaAction.update(input(
            .lavaBoost, faceYaw: 0x1000, wallAngle: 0x4000,
            airStep: .hitWall, marioSoundPlayed: true
        ))!
        precondition(wall.intent == .reflectedWall && wall.faceYaw == -0x1000)
        precondition(wall.shouldReflectBonk)
        fingerprint = hash(fingerprint, wall)

        let lavaWall = SM64MarioBurningLavaAction.update(input(
            .lavaBoost, forwardVelocity: 8, wallAngle: -0x4000,
            airStep: .hitLavaWall, metalCap: false, capOnHead: false,
            marioSoundPlayed: true
        ))!
        precondition(lavaWall.intent == .lavaWallRestart && lavaWall.action == SM64MarioActionID.lavaBoost)
        precondition(lavaWall.actionArgument == 1 && lavaWall.forwardVelocity == 24)
        precondition(lavaWall.hurtCounter == 18 && lavaWall.shouldDropHeldObject)
        fingerprint = hash(fingerprint, lavaWall)

        let death = SM64MarioBurningLavaAction.update(input(
            .lavaBoost, health: 0xFF, marioSoundPlayed: true
        ))!
        precondition(death.intent == .deathWarp && death.shouldTriggerDeathWarp && death.shouldSetEyesDead)
        fingerprint = hash(fingerprint, death)

        precondition(SM64MarioBurningLavaAction.update(input(
            .lavaBoost, forwardVelocity: .infinity
        )) == nil)

        print(String(format: "marioBurningLavaFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario burning-lava smoke passed")
    }
}
