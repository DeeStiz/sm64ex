import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashResult(_ initial: UInt64, _ result: SM64MarioLandingJumpResult) -> UInt64 {
    var hash = hashU32(initial, result.action)
    hash = hashU32(hash, result.actionArgument)
    hash = hashU8(hash, result.didResetDoubleJumpTimer ? 1 : 0)
    hash = hashU8(hash, result.shouldRunSteepJumpPhysics ? 1 : 0)
    return hashU8(hash, result.shouldDropHeldObject ? 1 : 0)
}

private func input(
    quicksand: Float = 0,
    held: Bool = false,
    steep: Bool = false,
    timer: UInt8 = 1,
    squish: UInt8 = 0,
    previous: UInt32 = SM64MarioActionID.idle,
    wing: Bool = false,
    forward: Float = 10
) -> SM64MarioLandingJumpInput {
    SM64MarioLandingJumpInput(
        quicksandDepth: quicksand,
        heldObjectPresent: held,
        floorIsSteep: steep,
        doubleJumpTimer: timer,
        squishTimer: squish,
        previousAction: previous,
        wingCap: wing,
        forwardVelocity: forward
    )
}

@main
enum SM64ModernMarioLandingJumpSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let quicksand = SM64MarioLandingJump.update(input(quicksand: 11))!
        precondition(quicksand.action == SM64MarioActionID.quicksandJumpLand && !quicksand.shouldDropHeldObject)
        fingerprint = hashResult(fingerprint, quicksand)

        let heldQuicksand = SM64MarioLandingJump.update(input(quicksand: 12, held: true))!
        precondition(heldQuicksand.action == SM64MarioActionID.holdQuicksandJumpLand)
        fingerprint = hashResult(fingerprint, heldQuicksand)

        let steep = SM64MarioLandingJump.update(input(steep: true))!
        precondition(steep.action == SM64MarioActionID.steepJump
            && steep.shouldRunSteepJumpPhysics && steep.shouldDropHeldObject)
        fingerprint = hashResult(fingerprint, steep)

        let timerOverride = SM64MarioLandingJump.update(input(timer: 0))!
        precondition(timerOverride.action == SM64MarioActionID.jump)
        fingerprint = hashResult(fingerprint, timerOverride)

        let squishOverride = SM64MarioLandingJump.update(input(squish: 1))!
        precondition(squishOverride.action == SM64MarioActionID.jump)
        fingerprint = hashResult(fingerprint, squishOverride)

        for previous in [
            SM64MarioActionID.jumpLand,
            SM64MarioActionID.freefallLand,
            SM64MarioActionID.sideFlipLandStop
        ] {
            let doubleJump = SM64MarioLandingJump.update(input(previous: previous))!
            precondition(doubleJump.action == SM64MarioActionID.doubleJump)
            fingerprint = hashResult(fingerprint, doubleJump)
        }

        let flying = SM64MarioLandingJump.update(input(
            previous: SM64MarioActionID.doubleJumpLand, wing: true
        ))!
        precondition(flying.action == SM64MarioActionID.flyingTripleJump)
        fingerprint = hashResult(fingerprint, flying)

        let triple = SM64MarioLandingJump.update(input(
            previous: SM64MarioActionID.doubleJumpLand, forward: 20.1
        ))!
        precondition(triple.action == SM64MarioActionID.tripleJump)
        fingerprint = hashResult(fingerprint, triple)

        let normal = SM64MarioLandingJump.update(input(
            previous: SM64MarioActionID.doubleJumpLand, forward: 20
        ))!
        precondition(normal.action == SM64MarioActionID.jump)
        fingerprint = hashResult(fingerprint, normal)

        let fallback = SM64MarioLandingJump.update(input(previous: SM64MarioActionID.idle))!
        precondition(fallback.action == SM64MarioActionID.jump && fallback.didResetDoubleJumpTimer)
        fingerprint = hashResult(fingerprint, fallback)

        precondition(SM64MarioLandingJump.update(input(quicksand: .infinity)) == nil)
        print(String(format: "marioLandingJumpFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario landing-jump smoke passed")
    }
}
