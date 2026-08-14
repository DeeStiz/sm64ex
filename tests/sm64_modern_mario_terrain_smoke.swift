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

private func hashOptionalID(_ initial: UInt64, _ value: UInt32?) -> UInt64 {
    hashU32(initial, value ?? UInt32.max)
}

private func hashMutation(_ initial: UInt64, _ mutation: SM64MarioTerrainMutation) -> UInt64 {
    var hash = initial
    hash = hashFloat(hash, mutation.position.x)
    hash = hashFloat(hash, mutation.position.y)
    hash = hashFloat(hash, mutation.position.z)
    hash = hashOptionalID(hash, mutation.floorSurfaceID)
    hash = hashOptionalID(hash, mutation.ceilingSurfaceID)
    hash = hashOptionalID(hash, mutation.wallSurfaceID)
    hash = hashFloat(hash, mutation.floorHeight)
    hash = hashFloat(hash, mutation.ceilingHeight)
    hash = hashU16(hash, UInt16(bitPattern: mutation.floorAngle))
    hash = hashFloat(hash, mutation.waterLevel)
    hash = hashU32(hash, mutation.terrainSoundAddend)
    hash = hashU16(hash, mutation.input.rawValue)
    hash = hashU8(hash, mutation.floorChanged ? 1 : 0)
    hash = hashU8(hash, mutation.ceilingChanged ? 1 : 0)
    return hashU8(hash, mutation.waterLevelChanged ? 1 : 0)
}

private func query(
    id: UInt32?,
    height: Float,
    type: Int16 = 0,
    flags: Int8 = 0,
    normal: SM64SurfaceVec3f = SM64SurfaceVec3f(x: 0, y: 1, z: 0)
) -> SM64SurfaceQueryResult {
    guard let id else { return .miss }
    let surface = SM64Surface(
        id: id,
        type: type,
        flags: flags,
        vertex1: SM64SurfaceVec3s(x: -100, y: 0, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: 0, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: 0, z: -100),
        normal: normal,
        originOffset: -height
    )
    return SM64SurfaceQueryResult(height: height, surface: surface)
}

private func snapshot(
    position: SM64ObjectVector3,
    floor: SM64SurfaceQueryResult,
    ceiling: SM64SurfaceQueryResult,
    angle: Int16,
    sound: UInt32,
    water: Float,
    flags: SM64MarioInputFlags,
    upperWalls: [UInt32],
    lowerWalls: [UInt32]
) -> SM64MarioGeometryInputResult {
    SM64MarioGeometryInputResult(
        position: position,
        floor: floor,
        ceiling: ceiling,
        floorAngle: angle,
        floorClass: 0,
        terrainSoundAddend: sound,
        waterLevel: water,
        poisonGasLevel: 0,
        flags: flags,
        upperWall: SM64WallCollisionResult(x: position.x, y: position.y, z: position.z,
                                           totalCollisions: upperWalls.count, surfaceIDs: upperWalls),
        lowerWall: SM64WallCollisionResult(x: position.x, y: position.y, z: position.z,
                                           totalCollisions: lowerWalls.count, surfaceIDs: lowerWalls)
    )
}

@main
enum SM64ModernMarioTerrainSmoke {
    static func main() {
        var state = SM64MarioState()
        state.input = [.aDown]
        let first = snapshot(
            position: SM64ObjectVector3(x: 10, y: 20, z: 30),
            floor: query(id: 7, height: 12, type: 0x14),
            ceiling: query(id: 8, height: 160),
            angle: 0x1234,
            sound: 2 << 16,
            water: 100,
            flags: [.inWater, .aboveSlide],
            upperWalls: [9],
            lowerWalls: [11, 12]
        )
        let firstMutation = state.applyTerrainSnapshot(first)
        precondition(firstMutation.floorSurfaceID == 7 && firstMutation.ceilingSurfaceID == 8)
        precondition(firstMutation.wallSurfaceID == 12, "last lower wall")
        precondition(firstMutation.input == [.aDown, .aboveSlide, .inWater])
        precondition(state.floorHeight == 12 && state.waterLevel == 100)

        var secondState = SM64MarioState()
        secondState.floorSurfaceID = 7
        secondState.ceilingSurfaceID = 8
        secondState.waterLevel = 100
        let second = snapshot(
            position: SM64ObjectVector3(x: -4, y: 50, z: 8),
            floor: query(id: 15, height: -20, type: 0x15),
            ceiling: .miss,
            angle: -0x2222,
            sound: 7 << 16,
            water: 240,
            flags: [.offFloor, .inPoisonGas],
            upperWalls: [],
            lowerWalls: []
        )
        let secondMutation = secondState.applyTerrainSnapshot(second)
        precondition(secondMutation.floorChanged && secondMutation.ceilingChanged)
        precondition(secondMutation.waterLevelChanged && secondMutation.wallSurfaceID == nil)
        precondition(secondState.input == [.offFloor, .inPoisonGas])

        var fingerprint = fnvOffset
        fingerprint = hashMutation(fingerprint, firstMutation)
        fingerprint = hashMutation(fingerprint, secondMutation)
        print(String(format: "marioTerrainFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario terrain smoke passed")
    }
}
