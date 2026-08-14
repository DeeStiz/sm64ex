import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashF(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }

private func hashResult(_ initial: UInt64, _ result: SM64MarioGeometryInputResult) -> UInt64 {
    var hash = hashU32(initial, UInt32(result.flags.rawValue))
    hash = hashF(hash, result.position.x)
    hash = hashF(hash, result.position.y)
    hash = hashF(hash, result.floor.height)
    hash = hashF(hash, result.ceiling.height)
    hash = hashF(hash, result.waterLevel)
    hash = hashF(hash, result.poisonGasLevel)
    hash = hashU32(hash, UInt32(result.upperWall.totalCollisions))
    return hashU32(hash, UInt32(result.lowerWall.totalCollisions))
}

private func floor(id: UInt32, y: Int16, flags: Int8 = 0) -> SM64Surface {
    SM64Surface(
        id: id,
        flags: flags,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: -Float(y)
    )
}

private func ceiling(id: UInt32, y: Int16, flags: Int8 = 0) -> SM64Surface {
    SM64Surface(
        id: id,
        flags: flags,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: -1, z: 0),
        originOffset: Float(y)
    )
}

@main
enum SM64ModernMarioGeometryInputSmoke {
    static func main() throws {
        let staticCeiling = ceiling(id: 2, y: 1000)
        let regions = [
            SM64WaterRegion(value: 0, lowX: -100, lowZ: -100, highX: 100, highZ: 100, level: 50),
            SM64WaterRegion(value: 50, lowX: -100, lowZ: -100, highX: 100, highZ: 100, level: 300),
        ]
        let world = try SM64SurfaceCollisionWorld(
            staticSurfaces: [floor(id: 1, y: 0), staticCeiling],
            waterRegions: regions
        )
        let first = SM64MarioGeometryInput.update(
            position: SM64ObjectVector3(x: 0, y: 150, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: world
        )
        let dynamicWorld = try SM64SurfaceCollisionWorld(
            staticSurfaces: [floor(id: 1, y: 0), staticCeiling],
            dynamicSurfaces: [floor(id: 3, y: 40, flags: 1), ceiling(id: 4, y: 100, flags: 1)],
            waterRegions: regions
        )
        let second = SM64MarioGeometryInput.update(
            position: SM64ObjectVector3(x: 0, y: 50, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: dynamicWorld
        )
        precondition(first.flags == [.offFloor, .inPoisonGas], "floor/gas flags")
        precondition(first.floor.surfaceID == 1 && first.ceiling.surfaceID == 2, "static surfaces")
        precondition(second.flags.contains(.squished), "dynamic squish flag")
        precondition(second.ceiling.surfaceID == 4, "dynamic ceiling selection")
        var fingerprint = fnvOffset
        fingerprint = hashResult(fingerprint, first)
        fingerprint = hashResult(fingerprint, second)
        print(String(format: "marioGeometryInputFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario geometry input smoke passed")
    }
}
