import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashCollision(
    _ initial: UInt64,
    _ result: SM64SLWalkingPenguinCollisionResult
) -> UInt64 {
    var hash = hashFloat(initial, result.position.x)
    hash = hashFloat(hash, result.position.y)
    hash = hashFloat(hash, result.position.z)
    hash = hashFloat(hash, result.floorHeight)
    hash = hashU64(hash, result.floorSurfaceID.map(UInt64.init) ?? UInt64.max)
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.floorType)))
    hash = hashFloat(hash, result.floorNormalY)
    hash = hashU64(hash, UInt64(result.wallSurfaceIDs.count))
    for id in result.wallSurfaceIDs {
        hash = hashU64(hash, UInt64(id))
    }
    return hashU64(hash, UInt64(result.moveFlags))
}

private func triangle(id: UInt32, y: Int16, type: Int16 = 0) -> SM64Surface {
    SM64Surface(
        id: id,
        type: type,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: 100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: -Float(y)
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

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSLWalkingPenguinCollisionSmoke {
    static func main() throws {
        let floor = triangle(id: 1, y: 0)
        let wallSurface = wall(id: 10)
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor, wallSurface])

        let direct = SM64SLWalkingPenguinCollision.resolve(
            SM64SLWalkingPenguinCollisionInput(
                position: SM64ObjectVector3(x: -10, y: 0, z: 0),
                moveYaw: Int16(bitPattern: 0x9000),
                wallHitboxRadius: 20,
                previousMoveFlags: SM64SLWalkingPenguinCollision.onGround,
                world: world
            )
        )
        guard let direct else {
            preconditionFailure("direct collision result missing")
        }
        require(direct.position.x == 20 && direct.position.z == 0, "wall projection")
        require(direct.floorSurfaceID == 1 && direct.floorHeight == 0, "floor selection")
        require(direct.wallSurfaceIDs == [10], "wall identity")
        require(
            direct.moveFlags
                & (SM64SLWalkingPenguinCollision.onGround | SM64SLWalkingPenguinCollision.hitWall)
                == (SM64SLWalkingPenguinCollision.onGround | SM64SLWalkingPenguinCollision.hitWall),
            "wall-facing move flags"
        )
        var fingerprint = hashCollision(fnvOffset, direct)

        let engineState = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64SLWalkingPenguinObjectBridge()
        let id = try bridge.spawnPenguin(
            in: engineState,
            position: SM64ObjectVector3(x: -10, y: 0, z: 0),
            moveYaw: Int16(bitPattern: 0x9000),
            wallHitboxRadius: 20
        )
        let tick = bridge.tick(state: engineState, collisionWorld: world)
        guard let effect = tick.effects.first,
              let collision = effect.collision,
              let record = engineState.objects.record(for: id) else {
            preconditionFailure("bridge collision result missing")
        }
        require(collision.floorSurfaceID == 1, "bridge floor identity")
        require(collision.wallSurfaceIDs == [10], "bridge wall identity")
        require(record.floorHeight == 0 && record.floorType == 0, "record floor state")
        require(record.moveFlags & SM64SLWalkingPenguinCollision.hitWall != 0, "record wall flag")
        require(record.position == collision.position, "record collision position")
        fingerprint = hashCollision(fingerprint, collision)
        fingerprint = hashFloat(fingerprint, record.position.x)
        fingerprint = hashFloat(fingerprint, record.position.y)
        fingerprint = hashFloat(fingerprint, record.position.z)
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(record.action)))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(record.timer)))

        print(String(format: "slWalkingPenguinCollisionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern SL walking penguin collision smoke passed")
    }
}
