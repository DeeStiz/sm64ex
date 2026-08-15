import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioShellAirActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h32(x, UInt32(r.animationID))
    x = h8(x, r.airStep.rawValue)
    x = h32(x, r.graphicsYOffset.bitPattern)
    x = h8(x, r.shouldPlayTerrainJumpSound ? 1 : 0)
    return h8(x, r.shouldPlayLavaBoost ? 1 : 0)
}

private func input(
    flags: SM64MarioInputFlags = [],
    intendedMagnitude: Float = 0,
    intendedYaw: Int16 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 20,
    velocityY: Float = -8,
    airStep: SM64MarioAirStepOutcome = .none,
    horizontalWindActive: Bool = false
) -> SM64MarioShellAirActionInput {
    SM64MarioShellAirActionInput(
        input: flags, intendedMagnitude: intendedMagnitude,
        intendedYaw: intendedYaw, faceYaw: faceYaw,
        forwardVelocity: forwardVelocity, velocityY: velocityY,
        airStep: airStep, horizontalWindActive: horizontalWindActive
    )
}

@main
enum SM64ModernMarioShellAirSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let continueAir = SM64MarioShellAirAction.update(input())!
        precondition(continueAir.intent == .continueAir)
        precondition(continueAir.animationID == 0x4A)
        precondition(abs(continueAir.forwardVelocity - 19.65) < 0.0001)
        precondition(continueAir.shouldPlayTerrainJumpSound)
        fingerprint = hash(fingerprint, continueAir)

        let controlled = SM64MarioShellAirAction.update(input(
            flags: [.nonzeroAnalog], intendedMagnitude: 32,
            intendedYaw: 0x4000, faceYaw: 0, forwardVelocity: 0
        ))!
        precondition(controlled.forwardVelocity == 0)
        precondition(abs(controlled.velocity.x - 10) < 0.001)

        let wind = SM64MarioShellAirAction.update(input(
            forwardVelocity: 20, horizontalWindActive: true
        ))!
        precondition(wind.forwardVelocity == 20)
        fingerprint = hash(fingerprint, wind)

        let landed = SM64MarioShellAirAction.update(input(airStep: .landed))!
        precondition(landed.intent == .landed)
        precondition(landed.action == SM64MarioActionID.ridingShellGround)
        precondition(landed.actionArgument == 1)
        fingerprint = hash(fingerprint, landed)

        let wall = SM64MarioShellAirAction.update(input(airStep: .hitWall))!
        precondition(wall.intent == .hitWall && wall.forwardVelocity == 0)
        precondition(wall.velocity.x == 0 && wall.velocity.z == 0)
        fingerprint = hash(fingerprint, wall)

        let lava = SM64MarioShellAirAction.update(input(airStep: .hitLavaWall))!
        precondition(lava.intent == .lavaWall && lava.action == SM64MarioActionID.lavaBoost)
        precondition(lava.shouldPlayLavaBoost)
        fingerprint = hash(fingerprint, lava)

        precondition(SM64MarioShellAirAction.update(input(forwardVelocity: .infinity)) == nil)

        print(String(format: "marioShellAirFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario shell-air smoke passed")
    }
}
