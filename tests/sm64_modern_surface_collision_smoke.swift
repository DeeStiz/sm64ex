import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func triangle(id: UInt32, y: Int16, type: Int16 = 0, flags: Int8 = 0) -> SM64Surface {
    SM64Surface(
        id: id,
        type: type,
        flags: flags,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: -Float(y)
    )
}

private func ceiling(id: UInt32, y: Int16) -> SM64Surface {
    SM64Surface(
        id: id,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: -1, z: 0),
        originOffset: Float(y)
    )
}

private func wall(id: UInt32, x: Int16 = 0) -> SM64Surface {
    SM64Surface(
        id: id,
        flags: SM64SurfaceCollisionWorld.xProjectionFlag,
        lowerY: -100,
        upperY: 100,
        vertex1: SM64SurfaceVec3s(x: x, y: -100, z: -100),
        vertex2: SM64SurfaceVec3s(x: x, y: 100, z: -100),
        vertex3: SM64SurfaceVec3s(x: x, y: 100, z: 100),
        normal: SM64SurfaceVec3f(x: 1, y: 0, z: 0),
        originOffset: -Float(x)
    )
}

private func appendResult(_ hash: UInt64, _ result: SM64SurfaceQueryResult) -> UInt64 {
    var value = hash
    value = hashU64(value, UInt64(result.height.bitPattern))
    value = hashU64(value, result.surfaceID.map(UInt64.init) ?? UInt64.max)
    value = hashU64(value, result.type.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.max)
    value = hashU64(value, result.flags.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.max)
    value = hashU64(value, result.normalY.map { UInt64($0.bitPattern) } ?? UInt64.max)
    return value
}

@main
enum SM64ModernSurfaceCollisionSmoke {
    static func main() throws {
        let floor = triangle(id: 1, y: 0)
        let dynamicFloor = triangle(id: 2, y: 50)
        let ceil = ceiling(id: 3, y: 200)
        let cameraBoundary = triangle(id: 4, y: 10, type: SM64SurfaceCollisionWorld.cameraBoundaryType)
        let noCamera = triangle(id: 5, y: 20, flags: SM64SurfaceCollisionWorld.noCameraCollisionFlag)
        let water = SM64WaterRegion(value: 0, lowX: -50, lowZ: -50, highX: 50, highZ: 50, level: 80)
        let gas = SM64WaterRegion(value: 50, lowX: -50, lowZ: -50, highX: 50, highZ: 50, level: 90)
        let world = try SM64SurfaceCollisionWorld(
            staticSurfaces: [floor, ceil, cameraBoundary, noCamera],
            dynamicSurfaces: [dynamicFloor],
            waterRegions: [water, gas]
        )
        require(world.findFloor(x: 0, y: 100, z: 0).surfaceID == 2, "dynamic floor wins")
        require(world.findFloor(x: 0, y: -100, z: 0) == .miss, "floor miss buffer")
        require(world.findFloor(x: 0, y: 100, z: 0).height == 50, "floor height")
        require(world.findCeil(x: 0, y: 100, z: 0).surfaceID == 3, "ceiling query")
        require(world.findFloor(x: 0, y: 100, z: 0).type != SM64SurfaceCollisionWorld.cameraBoundaryType, "camera boundary excluded")
        require(world.findFloor(x: 0x2000, y: 100, z: 0) == .miss, "level boundary")
        require(world.findWaterLevel(x: 0, z: 0) == 80, "water region")
        require(world.findWaterLevel(x: 60, z: 0) == SM64SurfaceCollisionWorld.missHeight, "water miss")

        let cameraWorld = try SM64SurfaceCollisionWorld(
            staticSurfaces: [noCamera, floor],
            checkingForCamera: true
        )
        require(cameraWorld.findFloor(x: 0, y: 100, z: 0).surfaceID == 1, "camera no-collision flag")
        let wallWorld = try SM64SurfaceCollisionWorld(staticSurfaces: [wall(id: 10)])
        let wallResult = wallWorld.findWallCollisions(SM64WallCollisionInput(x: -10, y: 0, z: 0, offsetY: 0, radius: 20))
        require(wallResult.totalCollisions == 1 && wallResult.surfaceIDs == [10], "wall capture")
        require(wallResult.x == 20 && wallResult.z == 0, "wall projection push")
        let rayHit = world.findSurfaceOnRay(
            origin: SM64SurfaceVec3f(x: 0, y: 100, z: 0),
            direction: SM64SurfaceVec3f(x: 0, y: -200, z: 0)
        )
        require(rayHit?.surfaceID == 2 && rayHit?.position.y == 50 && rayHit?.distance == 50, "ray surface hit")

        var fingerprint = fnvOffset
        fingerprint = appendResult(fingerprint, world.findFloor(x: 0, y: 100, z: 0))
        fingerprint = appendResult(fingerprint, world.findFloor(x: 0, y: -100, z: 0))
        fingerprint = appendResult(fingerprint, world.findCeil(x: 0, y: 100, z: 0))
        fingerprint = hashU64(fingerprint, UInt64(world.findWaterLevel(x: 0, z: 0).bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(world.findWaterLevel(x: 60, z: 0).bitPattern))
        fingerprint = appendResult(fingerprint, cameraWorld.findFloor(x: 0, y: 100, z: 0))
        fingerprint = hashU64(fingerprint, UInt64(wallResult.x.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(wallResult.z.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(wallResult.totalCollisions))
        for id in wallResult.surfaceIDs { fingerprint = hashU64(fingerprint, UInt64(id)) }
        fingerprint = hashU64(fingerprint, UInt64(rayHit?.surfaceID ?? UInt32.max))
        if let rayHit {
            fingerprint = hashU64(fingerprint, UInt64(rayHit.position.x.bitPattern))
            fingerprint = hashU64(fingerprint, UInt64(rayHit.position.y.bitPattern))
            fingerprint = hashU64(fingerprint, UInt64(rayHit.position.z.bitPattern))
            fingerprint = hashU64(fingerprint, UInt64(rayHit.distance.bitPattern))
        }
        print(String(format: "surfaceCollisionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern surface collision smoke passed")
    }
}
