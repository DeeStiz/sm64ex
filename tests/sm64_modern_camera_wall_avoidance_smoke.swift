import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func wall(
    id: UInt32, zExtent: Int16 = 1_000, yExtent: Int16 = 100,
    type: Int16 = 0
) -> SM64Surface {
    SM64Surface(
        id: id, type: type, flags: SM64SurfaceCollisionWorld.xProjectionFlag,
        lowerY: -yExtent, upperY: yExtent,
        vertex1: .init(x: 0, y: -yExtent, z: -zExtent),
        vertex2: .init(x: 0, y: yExtent, z: -zExtent),
        vertex3: .init(x: 0, y: yExtent, z: zExtent),
        normal: .init(x: 1, y: 0, z: 0), originOffset: 0
    )
}

private func hashOptionalID(_ h: UInt64, _ value: UInt32?) -> UInt64 {
    h32(h, value ?? UInt32.max)
}

private func hash(_ h: UInt64, _ value: SM64CameraWallAvoidanceResult) -> UInt64 {
    var x = hi16(h, value.status)
    x = hi16(x, value.avoidYaw)
    x = h16(x, value.statusFlags)
    x = hi16(x, value.checkedSteps)
    x = hf(x, value.coarseRadius)
    x = hf(x, value.fineRadius)
    x = hashOptionalID(x, value.lastCoarseWallID)
    return hashOptionalID(x, value.lastFineWallID)
}

@main
enum SM64ModernCameraWallAvoidanceSmoke {
    static func main() throws {
        let tallWall = wall(id: 10)
        let shortWall = wall(id: 11, zExtent: 10, yExtent: 70)
        precondition(SM64CameraWallAvoidance.calculateAvoidYaw(
            yawFromMario: 0, wallYaw: 0x4000
        ) == -0x4000)
        precondition(SM64CameraWallAvoidance.isBehindSurface(
            .init(x: 100, y: 0, z: 0), surface: tallWall
        ))
        precondition(!SM64CameraWallAvoidance.isBehindSurface(
            .init(x: -100, y: 0, z: 0), surface: tallWall
        ))
        precondition(!SM64CameraWallAvoidance.isRangeBehindSurface(
            from: .init(x: -100, y: 0, z: 0),
            to: .init(x: -100, y: 0, z: 700),
            surface: tallWall, range: 0x400
        ))
        precondition(!SM64CameraWallAvoidance.isSurfaceWithinBoundingBox(
            tallWall, xMax: -1, yMax: 150, zMax: -1
        ))
        precondition(SM64CameraWallAvoidance.isSurfaceWithinBoundingBox(
            shortWall, xMax: -1, yMax: 150, zMax: -1
        ))

        let emptyWorld = try SM64SurfaceCollisionWorld(checkingForCamera: true)
        let clear = SM64CameraWallAvoidance.rotate(.init(
            marioPosition: .init(x: -100, y: 20, z: -200),
            cameraPosition: .init(x: 100, y: 20, z: 200),
            avoidYaw: 0x1234, yawRange: 0x400,
            statusFlags: 0x1234, world: emptyWorld
        ))!
        precondition(clear.status == 0 && clear.avoidYaw == 0x1234
            && clear.statusFlags == 0x1214 && clear.checkedSteps == 8
            && clear.coarseRadius == 250 && clear.fineRadius == 100
            && clear.lastCoarseWallID == nil && clear.lastFineWallID == nil)

        let nearWorld = try SM64SurfaceCollisionWorld(
            staticSurfaces: [tallWall], checkingForCamera: true
        )
        let near = SM64CameraWallAvoidance.rotate(.init(
            marioPosition: .init(x: -100, y: -100, z: 0),
            cameraPosition: .init(x: -100, y: -100, z: -700),
            avoidYaw: 0x1234, yawRange: 0x400,
            statusFlags: 0, world: nearWorld
        ))!
        precondition(near.status == 1 && near.statusFlags
            & SM64CameraWallAvoidance.nearWallFlag != 0
            && near.avoidYaw == -0x8000 && near.checkedSteps == 8
            && near.lastCoarseWallID == 10 && near.lastFineWallID == 10
            && near.coarseRadius == 250 && near.fineRadius == 200)

        var fingerprint = hi16(fnvOffset,
            SM64CameraWallAvoidance.calculateAvoidYaw(
                yawFromMario: 0, wallYaw: 0x4000
            ))
        fingerprint = hash(fingerprint, clear)
        fingerprint = hash(fingerprint, near)
        print(String(format: "cameraWallAvoidanceFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera wall-avoidance smoke passed")
    }
}
