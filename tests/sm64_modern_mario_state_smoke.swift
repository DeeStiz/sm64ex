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

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 { hash ^= (value >> UInt64(byte * 8)) & 0xff; hash &*= fnvPrime }
    return hash
}

private func hashState(_ initial: UInt64, _ state: SM64MarioState) -> UInt64 {
    var hash = initial
    hash = hashU16(hash, state.unknown00)
    hash = hashU16(hash, state.input.rawValue)
    hash = hashU32(hash, state.flags)
    hash = hashU32(hash, state.particleFlags)
    hash = hashU32(hash, state.action)
    hash = hashU32(hash, state.previousAction)
    hash = hashU32(hash, state.terrainSoundAddend)
    hash = hashU16(hash, state.actionState)
    hash = hashU16(hash, state.actionTimer)
    hash = hashU32(hash, state.actionArgument)
    hash = hashU32(hash, state.intendedMagnitude.bitPattern)
    hash = hashU16(hash, UInt16(bitPattern: state.intendedYaw))
    hash = hashU16(hash, UInt16(bitPattern: state.invincibilityTimer))
    hash = hashU8(hash, state.framesSinceA)
    hash = hashU8(hash, state.framesSinceB)
    hash = hashU8(hash, state.wallKickTimer)
    hash = hashU8(hash, state.doubleJumpTimer)
    for angle in [state.faceAngle.pitch, state.faceAngle.yaw, state.faceAngle.roll,
                  state.angleVelocity.pitch, state.angleVelocity.yaw, state.angleVelocity.roll] {
        hash = hashU32(hash, UInt32(bitPattern: angle))
    }
    hash = hashU16(hash, UInt16(bitPattern: state.slideYaw))
    hash = hashU16(hash, UInt16(bitPattern: state.twirlYaw))
    for value in [state.position.x, state.position.y, state.position.z,
                  state.velocity.x, state.velocity.y, state.velocity.z,
                  state.forwardVelocity, state.slideVelocityX, state.slideVelocityZ,
                  state.ceilingHeight, state.floorHeight, state.waterLevel,
                  state.peakHeight, state.quicksandDepth, state.unknownC4] {
        hash = hashU32(hash, value.bitPattern)
    }
    hash = hashU32(hash, state.floorSurfaceID ?? UInt32.max)
    hash = hashU32(hash, state.marioObjectID?.traceSubject ?? 0)
    hash = hashU32(hash, state.collidedObjectInteractionTypes)
    hash = hashU16(hash, UInt16(bitPattern: state.coinCount))
    hash = hashU16(hash, UInt16(bitPattern: state.starCount))
    hash = hashU8(hash, UInt8(bitPattern: state.keyCount))
    hash = hashU8(hash, UInt8(bitPattern: state.lives))
    hash = hashU16(hash, UInt16(bitPattern: state.health))
    hash = hashU16(hash, UInt16(bitPattern: state.unknownB0))
    hash = hashU8(hash, state.hurtCounter)
    hash = hashU8(hash, state.healCounter)
    hash = hashU8(hash, state.squishTimer)
    hash = hashU8(hash, state.fadeWarpOpacity)
    hash = hashU16(hash, state.capTimer)
    return hashU16(hash, UInt16(bitPattern: state.previousStarsForDialog))
}

private func floor(y: Int16) -> SM64Surface {
    SM64Surface(
        id: 7,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: -Float(y)
    )
}

@main
enum SM64ModernMarioStateSmoke {
    static func main() throws {
        let surface = floor(y: 0)
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [surface])
        let floorResult = world.findFloor(x: 0, y: 100, z: 0)
        let marioID = SM64ObjectID(slot: 0, generation: 1)
        let swimming = SM64MarioState.initialized(
            save: SM64MarioSaveState(flags: [.capOnGround], totalStars: 42),
            spawn: SM64MarioSpawnInput(
                position: SM64ObjectVector3(x: 10, y: -40, z: 20),
                faceAngle: SM64ObjectAngles(pitch: 0, yaw: 0x1234, roll: 0),
                waterLevel: 100
            ),
            floor: floorResult,
            marioObjectID: marioID
        )
        precondition(swimming.position.y == 0, "spawn clamps to floor")
        precondition(swimming.action == SM64MarioAction.waterIdle, "water spawn action")
        precondition(swimming.flags == 0, "lost cap stays absent")
        precondition(swimming.framesSinceA == .max && swimming.framesSinceB == .max, "initial edge timers")
        precondition(swimming.health == 0x880 && swimming.lives == 4, "save defaults")

        let grounded = SM64MarioState.initialized(
            save: SM64MarioSaveState(totalStars: 7),
            spawn: SM64MarioSpawnInput(
                position: SM64ObjectVector3(x: -10, y: 80, z: 30),
                faceAngle: SM64ObjectAngles(pitch: 0, yaw: -0x2222, roll: 0),
                waterLevel: -11_000
            ),
            floor: floorResult
        )
        precondition(grounded.action == SM64MarioAction.idle, "ground spawn action")
        precondition(grounded.flags == (SM64MarioCapFlags.normal.rawValue | SM64MarioCapFlags.onHead.rawValue), "normal cap")
        precondition(grounded.starCount == 7 && grounded.previousStarsForDialog == 7, "star persistence")

        var fingerprint = fnvOffset
        fingerprint = hashState(fingerprint, swimming)
        fingerprint = hashState(fingerprint, grounded)
        print(String(format: "marioStateFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario state smoke passed")
    }
}
