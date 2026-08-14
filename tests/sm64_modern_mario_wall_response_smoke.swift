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

private func hashResult(_ initial: UInt64, _ result: SM64MarioWallResponseResult) -> UInt64 {
    var hash = hashFloat(initial, result.velocity.x)
    hash = hashFloat(hash, result.velocity.y)
    hash = hashFloat(hash, result.velocity.z)
    hash = hashFloat(hash, result.forwardVelocity)
    hash = hashU32(hash, result.flags)
    hash = hashU16(hash, result.animationID)
    hash = hashU32(hash, UInt32(bitPattern: result.animationAcceleration))
    hash = hashU8(hash, result.sound.rawValue)
    hash = hashU8(hash, result.particleDust ? 1 : 0)
    hash = hashU16(hash, result.actionState)
    hash = hashU32(hash, result.actionArgument)
    hash = hashU32(hash, UInt32(bitPattern: result.gfxAngle.yaw))
    return hashU32(hash, UInt32(bitPattern: result.gfxAngle.roll))
}

private func input(
    start: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
    position: SM64ObjectVector3 = SM64ObjectVector3(x: 3, y: 0, z: 4),
    velocity: SM64ObjectVector3 = SM64ObjectVector3(x: 9, y: 2, z: -3),
    forward: Float = 12,
    faceYaw: Int32 = 0,
    frame: Int16 = 10,
    past1: Bool = false,
    past2: Bool = false,
    slope: Int16 = 0x1234,
    wall: SM64MarioWallResponseProbe? = nil
) -> SM64MarioWallResponseInput {
    SM64MarioWallResponseInput(
        startPosition: start,
        position: position,
        velocity: velocity,
        forwardVelocity: forward,
        faceYaw: faceYaw,
        animationFrame: frame,
        animationPastFrame1: past1,
        animationPastFrame2: past2,
        terrainSoundAddend: 0x50000,
        floorSlopePitch: slope,
        wall: wall
    )
}

@main
enum SM64ModernMarioWallResponseSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let pushing = SM64MarioWallResponse.update(input(past1: true))!
        precondition(pushing.animationID == SM64MarioWallAnimationID.pushing)
        precondition(pushing.forwardVelocity == 6 && pushing.velocity.x == 0 && pushing.velocity.z == 6)
        precondition(pushing.flags == SM64MarioWallResponse.unknown31 && pushing.sound == .step)
        fingerprint = hashResult(fingerprint, pushing)

        let wall = SM64MarioWallResponse.update(input(
            faceYaw: 0,
            frame: 10,
            wall: SM64MarioWallResponseProbe(normalX: 0, normalZ: 1)
        ))!
        precondition(wall.animationID == SM64MarioWallAnimationID.sidestepLeft)
        precondition(wall.actionState == 1 && wall.actionArgument == 0x8000)
        precondition(wall.gfxAngle.yaw == -0x8000 && wall.gfxAngle.roll == 0x1234)
        precondition(wall.sound == .movingTerrainSlide && wall.particleDust)
        fingerprint = hashResult(fingerprint, wall)

        let right = SM64MarioWallResponse.update(input(
            forward: 4,
            faceYaw: 0x4000,
            frame: 25,
            wall: SM64MarioWallResponseProbe(normalX: 0, normalZ: 1)
        ))!
        precondition(right.animationID == SM64MarioWallAnimationID.sidestepRight)
        precondition(right.sound == .none && !right.particleDust)
        fingerprint = hashResult(fingerprint, right)

        precondition(SM64MarioWallResponse.update(input(
            position: SM64ObjectVector3(x: .infinity, y: 0, z: 0)
        )) == nil)

        print(String(format: "marioWallResponseFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario wall-response smoke passed")
    }
}
