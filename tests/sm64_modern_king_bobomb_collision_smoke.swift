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

private func hashCollision(_ initial: UInt64, _ result: SM64KingBobombCollisionResult) -> UInt64 {
    var hash = hashFloat(initial, result.position.x)
    hash = hashFloat(hash, result.position.y)
    hash = hashFloat(hash, result.position.z)
    hash = hashFloat(hash, result.floorHeight)
    hash = hashU64(hash, result.floorSurfaceID.map(UInt64.init) ?? UInt64.max)
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.floorType)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.floorRoom)))
    hash = hashFloat(hash, result.floorNormalY)
    hash = hashU64(hash, UInt64(result.wallSurfaceIDs.count))
    for id in result.wallSurfaceIDs { hash = hashU64(hash, UInt64(id)) }
    hash = hashU64(hash, UInt64(result.moveFlags))
    hash = hashU64(hash, result.hitWall ? 1 : 0)
    return hashU64(hash, result.steepFloor ? 1 : 0)
}

private func hashMovement(_ initial: UInt64, _ result: SM64KingBobombMovementResult) -> UInt64 {
    var hash = hashFloat(initial, result.position.x)
    hash = hashFloat(hash, result.position.y)
    hash = hashFloat(hash, result.position.z)
    hash = hashFloat(hash, result.velocity.x)
    hash = hashFloat(hash, result.velocity.y)
    hash = hashFloat(hash, result.velocity.z)
    hash = hashFloat(hash, result.forwardVelocity)
    hash = hashU64(hash, UInt64(result.moveFlags))
    hash = hashU64(hash, result.hitEdge ? 1 : 0)
    hash = hashU64(hash, result.landed ? 1 : 0)
    return hashU64(hash, result.onGround ? 1 : 0)
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
enum SM64ModernKingBobombCollisionSmoke {
    static func main() throws {
        let floor = triangle(id: 1, y: 0)
        let wallSurface = wall(id: 10)
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor, wallSurface])

        guard let collision = SM64KingBobombCollision.resolve(
            SM64KingBobombCollisionInput(
                position: SM64ObjectVector3(x: -10, y: 0, z: 0),
                moveYaw: Int16(bitPattern: 0x9000),
                forwardVelocity: 0,
                wallHitboxRadius: 20,
                previousMoveFlags: SM64KingBobombCollision.onGround,
                world: world
            )
        ) else {
            preconditionFailure("King Bob-omb collision result missing")
        }
        require(collision.position.x == 20 && collision.position.z == 0, "wall projection")
        require(collision.floorSurfaceID == 1 && collision.floorHeight == 0, "floor selection")
        require(collision.wallSurfaceIDs == [10], "wall identity")
        require(collision.hitWall, "wall-facing move flag")
        require(collision.moveFlags & SM64KingBobombCollision.hitWall != 0, "hit wall move flag")
        require(collision.moveFlags & SM64KingBobombCollision.onGround != 0, "ground flag preserved")

        guard let movement = SM64KingBobombCollision.move(
            SM64KingBobombMovementInput(
                startPosition: SM64ObjectVector3(x: -10, y: 0, z: 0),
                candidatePosition: collision.position,
                velocityY: 0,
                forwardVelocity: 3,
                moveYaw: 0,
                floorHeight: 0,
                floorRoom: 0,
                objectRoom: -1,
                moveFlags: collision.moveFlags,
                gravity: -4,
                bounciness: -0.1,
                dragStrength: 0,
                buoyancy: 0,
                nativeStepScale: 1,
                intendedFloorHeight: 0,
                intendedFloorNormalY: 1,
                intendedFloorRoom: 0,
                intendedFloorExists: true,
                waterLevel: -11_000
            )
        ) else {
            preconditionFailure("King Bob-omb movement result missing")
        }
        require(movement.position == SM64ObjectVector3(x: 20, y: 0, z: 0), "standard movement position")
        require(movement.velocity == SM64ObjectVector3(x: 0, y: 0.4, z: 3), "gravity and ground response")
        require(movement.forwardVelocity == 3, "forward velocity preserved")
        require(movement.onGround && !movement.landed, "on-ground transition")

        var fingerprint = hashCollision(fnvOffset, collision)
        fingerprint = hashMovement(fingerprint, movement)
        print(String(format: "kingBobombCollisionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb collision smoke passed")
    }
}
