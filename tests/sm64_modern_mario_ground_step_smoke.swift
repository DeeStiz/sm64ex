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

private func hashProbeResult(_ initial: UInt64, _ result: SM64MarioGroundStepResult) -> UInt64 {
    var hash = hashFloat(initial, result.position.x)
    hash = hashFloat(hash, result.position.y)
    hash = hashFloat(hash, result.position.z)
    hash = hashU32(hash, result.floor.surfaceID ?? 0)
    hash = hashFloat(hash, result.floor.height)
    hash = hashFloat(hash, result.floor.normalY)
    hash = hashU32(hash, result.wallSurfaceID ?? 0)
    hash = hashU8(hash, result.result.rawValue)
    hash = hashU8(hash, result.quarterSteps)
    return hashU32(hash, result.terrainSoundAddend)
}

private func makeFloor(_ id: UInt32, _ height: Float, _ normalY: Float = 1) -> SM64MarioGroundFloorProbe {
    SM64MarioGroundFloorProbe(surfaceID: id, height: height, normalY: normalY)
}

private func makeWall(_ id: UInt32, angle: Int16) -> SM64MarioGroundWallProbe {
    SM64MarioGroundWallProbe(
        surfaceID: id,
        normalX: SM64CanonicalTrig.coss(angle),
        normalZ: SM64CanonicalTrig.sins(angle)
    )
}

private func probes(
    floor: SM64MarioGroundFloorProbe?,
    ceiling: Float = 1_000,
    water: Float = -11_000,
    wall: SM64MarioGroundWallProbe? = nil
) -> [SM64MarioGroundQuarterProbe] {
    Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor,
        ceilingHeight: ceiling,
        waterLevel: water,
        upperWall: wall
    ), count: 4)
}

private func input(
    position: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
    velocity: SM64ObjectVector3 = SM64ObjectVector3(x: 4, y: 0, z: 0),
    floor: SM64MarioGroundFloorProbe = makeFloor(1, 0),
    faceYaw: Int32 = 0,
    ridingShell: Bool = false,
    probes: [SM64MarioGroundQuarterProbe]
) -> SM64MarioGroundStepInput {
    SM64MarioGroundStepInput(
        position: position,
        velocity: velocity,
        floor: floor,
        faceYaw: faceYaw,
        nativeStepScale: 1,
        ridingShell: ridingShell,
        terrainSoundAddend: 0x30000,
        quarterProbes: probes
    )
}

@main
enum SM64ModernMarioGroundStepSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let flat = SM64MarioGroundStep.update(input(probes: probes(floor: makeFloor(2, 0))))!
        precondition(flat.result == .none && flat.position.x == 4 && flat.position.y == 0)
        fingerprint = hashProbeResult(fingerprint, flat)

        let left = SM64MarioGroundStep.update(input(
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            probes: probes(floor: makeFloor(3, -200))
        ))!
        precondition(left.result == .leftGround && left.position.x == 1 && left.position.y == 0)
        fingerprint = hashProbeResult(fingerprint, left)

        let ceiling = SM64MarioGroundStep.update(input(
            probes: probes(floor: makeFloor(4, 0), ceiling: 150)
        ))!
        precondition(ceiling.result == .hitWall && ceiling.position.x == 0 && ceiling.quarterSteps == 1)
        fingerprint = hashProbeResult(fingerprint, ceiling)

        let wallHit = SM64MarioGroundStep.update(input(
            probes: probes(floor: makeFloor(5, 0), wall: makeWall(6, angle: 0x4000))
        ))!
        precondition(wallHit.result == .hitWall && wallHit.wallSurfaceID == 6)
        fingerprint = hashProbeResult(fingerprint, wallHit)

        let wallSlide = SM64MarioGroundStep.update(input(
            probes: probes(floor: makeFloor(7, 0), wall: makeWall(8, angle: 0))
        ))!
        precondition(wallSlide.result == .none && wallSlide.wallSurfaceID == 8)
        fingerprint = hashProbeResult(fingerprint, wallSlide)

        let shell = SM64MarioGroundStep.update(input(
            position: SM64ObjectVector3(x: 0, y: 20, z: 0),
            floor: makeFloor(9, 0),
            ridingShell: true,
            probes: probes(floor: makeFloor(10, -20), water: 30)
        ))!
        precondition(shell.result == .none && shell.position.y == 30 && shell.floor.surfaceID == nil)
        fingerprint = hashProbeResult(fingerprint, shell)

        let noFloor = SM64MarioGroundStep.update(input(
            probes: probes(floor: nil)
        ))!
        precondition(noFloor.result == .hitWall && noFloor.quarterSteps == 1)
        fingerprint = hashProbeResult(fingerprint, noFloor)

        precondition(SM64MarioGroundStep.update(input(
            probes: Array(repeating: SM64MarioGroundQuarterProbe(
                floor: makeFloor(1, 0), ceilingHeight: .infinity, waterLevel: 0, upperWall: nil
            ), count: 3)
        )) == nil)

        print(String(format: "marioGroundStepFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario ground-step smoke passed")
    }
}
