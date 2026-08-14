import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashMutation(_ initial: UInt64, _ mutation: SM64MarioActionMutation) -> UInt64 {
    var hash = hashU32(initial, mutation.requestedAction)
    hash = hashU32(hash, mutation.action)
    hash = hashU32(hash, mutation.previousAction)
    hash = hashU32(hash, mutation.actionArgument)
    hash = hashU16(hash, mutation.actionState)
    hash = hashU16(hash, mutation.actionTimer)
    hash = hashU32(hash, mutation.flags)
    hash = hashFloat(hash, mutation.velocity.x)
    hash = hashFloat(hash, mutation.velocity.y)
    hash = hashFloat(hash, mutation.velocity.z)
    hash = hashFloat(hash, mutation.forwardVelocity)
    hash = hashU32(hash, UInt32(bitPattern: mutation.faceAngle.pitch))
    hash = hashU32(hash, UInt32(bitPattern: mutation.faceAngle.yaw))
    hash = hashU32(hash, UInt32(bitPattern: mutation.faceAngle.roll))
    hash = hashU8(hash, mutation.wallKickTimer)
    hash = hashFloat(hash, mutation.peakHeight)
    hash = hashU8(hash, mutation.droppedHeldObject ? 1 : 0)
    hash = hashU8(hash, mutation.droppedRiddenObject ? 1 : 0)
    return hashU8(hash, mutation.hurtCounter)
}

private func seededState() -> SM64MarioState {
    var state = SM64MarioState()
    state.action = SM64MarioActionID.idle
    state.flags = SM64MarioActionBits.actionSoundPlayed
        | SM64MarioActionBits.marioSoundPlayed
        | SM64MarioActionBits.unknown18
    state.intendedMagnitude = 6
    state.intendedYaw = 0x3000
    state.faceAngle = SM64ObjectAngles(pitch: 0x111, yaw: 0x2000, roll: -0x222)
    state.position = SM64ObjectVector3(x: 1, y: 37, z: -4)
    state.forwardVelocity = 2
    state.velocity = SM64ObjectVector3(x: 3, y: 4, z: 5)
    state.quicksandDepth = 0
    state.squishTimer = 0
    return state
}

@main
enum SM64ModernMarioActionSmoke {
    static func main() {
        var fingerprint = fnvOffset

        var walking = seededState()
        fingerprint = hashMutation(
            fingerprint,
            walking.setAction(SM64MarioActionID.walking, floorClass: 0)
        )
        precondition(walking.action == SM64MarioActionID.walking && walking.forwardVelocity == 6)

        var sliding = seededState()
        fingerprint = hashMutation(
            fingerprint,
            sliding.setAction(SM64MarioActionID.beginSliding, facingDownhill: false)
        )
        precondition(sliding.action == SM64MarioActionID.stomachSlide)

        var doubleJump = seededState()
        doubleJump.forwardVelocity = 20
        fingerprint = hashMutation(
            fingerprint,
            doubleJump.setAction(SM64MarioActionID.doubleJump)
        )
        precondition(doubleJump.velocity.y == 57 && doubleJump.forwardVelocity == 16)
        precondition(doubleJump.velocity.x == 3 && doubleJump.velocity.z == 5, "direct C velocity writes")

        var dive = seededState()
        dive.forwardVelocity = 40
        fingerprint = hashMutation(fingerprint, dive.setAction(SM64MarioActionID.dive))
        precondition(dive.forwardVelocity == 48 && dive.velocity.x != 3, "dive uses mario_set_forward_vel")

        var quicksand = seededState()
        quicksand.squishTimer = 1
        fingerprint = hashMutation(
            fingerprint,
            quicksand.setAction(SM64MarioActionID.doubleJump)
        )
        precondition(quicksand.action == SM64MarioActionID.jump && quicksand.velocity.y == 21.25)

        var submerged = seededState()
        fingerprint = hashMutation(
            fingerprint,
            submerged.setAction(SM64MarioActionID.metalWaterJump)
        )
        precondition(submerged.velocity.y == 32)

        var cutscene = seededState()
        fingerprint = hashMutation(
            fingerprint,
            cutscene.setAction(SM64MarioActionID.fallAfterStarGrab)
        )
        precondition(cutscene.forwardVelocity == 0 && cutscene.velocity.x == 0)

        var dropped = seededState()
        dropped.heldObjectID = SM64ObjectID(slot: 4, generation: 1)
        dropped.riddenObjectID = SM64ObjectID(slot: 5, generation: 1)
        let dropMutation = dropped.dropAndSetAction(SM64MarioActionID.idle)
        fingerprint = hashMutation(fingerprint, dropMutation)
        precondition(dropMutation.droppedHeldObject && dropMutation.droppedRiddenObject)
        precondition(dropped.heldObjectID == nil && dropped.riddenObjectID == nil)

        var hurt = seededState()
        let hurtMutation = hurt.hurtAndSetAction(
            SM64MarioActionID.jumpKick,
            hurtCounter: 4
        )
        fingerprint = hashMutation(fingerprint, hurtMutation)
        precondition(hurt.hurtCounter == 4 && hurt.velocity.y == 20)

        print(String(format: "marioActionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario action smoke passed")
    }
}
