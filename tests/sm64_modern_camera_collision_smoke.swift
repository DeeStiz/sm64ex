import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h64(_ h: UInt64, _ v: UInt64) -> UInt64 { var x = h; for i in 0..<8 { x ^= (v >> UInt64(i * 8)) & 0xff; x &*= fnvPrime }; return x }

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

private func hash(_ h: UInt64, _ result: SM64CameraHeightApproachResult) -> UInt64 {
    let x = h32(h, result.y.bitPattern); return h8(x, result.moving ? 1 : 0)
}

private func hash(_ h: UInt64, _ result: SM64CameraWallResolution) -> UInt64 {
    var x = h32(h, result.position.x.bitPattern)
    x = h32(x, result.position.y.bitPattern); x = h32(x, result.position.z.bitPattern)
    x = h64(x, UInt64(result.collisionCount))
    for id in result.wallIDs { x = h64(x, UInt64(id)) }
    return h8(x, result.collided ? 1 : 0)
}

@main
enum SM64ModernCameraCollisionSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        let rising = SM64CameraCollision.approachHeight(
            current: 10, goal: 20, increment: 3, smoothMovement: true
        )!
        precondition(rising.y == 13 && rising.moving)
        fingerprint = hash(fingerprint, rising)
        let descending = SM64CameraCollision.approachHeight(
            current: 20, goal: 10, increment: 30, smoothMovement: true
        )!
        precondition(descending.y == 10 && !descending.moving)
        fingerprint = hash(fingerprint, descending)
        let snapped = SM64CameraCollision.approachHeight(
            current: 10, goal: 20, increment: 3, smoothMovement: false
        )!
        precondition(snapped.y == 20 && !snapped.moving)
        fingerprint = hash(fingerprint, snapped)

        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [wall(id: 10)])
        let collision = SM64CameraCollision.resolveWalls(
            position: .init(x: -10, y: 0, z: 0), offsetY: 0, radius: 20,
            world: world
        )!
        precondition(collision.position == .init(x: 20, y: 0, z: 0))
        precondition(collision.collisionCount == 1 && collision.wallIDs == [10]
            && collision.collided)
        fingerprint = hash(fingerprint, collision)
        let miss = SM64CameraCollision.resolveWalls(
            position: .init(x: 500, y: 0, z: 0), offsetY: 0, radius: 20,
            world: world
        )!
        precondition(miss.collisionCount == 0 && !miss.collided)
        fingerprint = hash(fingerprint, miss)

        precondition(SM64CameraCollision.approachHeight(
            current: .nan, goal: 0, increment: 1, smoothMovement: true
        ) == nil)
        print(String(format: "cameraCollisionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera collision smoke passed")
    }
}
