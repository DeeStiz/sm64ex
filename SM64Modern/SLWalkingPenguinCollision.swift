import Foundation

struct SM64SLWalkingPenguinCollisionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let wallHitboxRadius: Float
    let previousMoveFlags: UInt32
    let world: SM64SurfaceCollisionWorld
}

struct SM64SLWalkingPenguinCollisionResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floorHeight: Float
    let floorSurfaceID: UInt32?
    let floorType: Int16
    let floorNormalY: Float
    let wallSurfaceIDs: [UInt32]
    let moveFlags: UInt32
}

/// Object-side equivalent of the floor/wall portion of
/// cur_obj_update_floor_and_walls(). Collision queries stay in the
/// value-typed world; the owner-thread bridge applies this result to the
/// object record.
enum SM64SLWalkingPenguinCollision {
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let inAir: UInt32 = 1 << 7
    static let hitWall: UInt32 = 1 << 9
    static let aboveLava: UInt32 = 1 << 11
    static let aboveDeathBarrier: UInt32 = 1 << 14

    static func resolve(
        _ input: SM64SLWalkingPenguinCollisionInput
    ) -> SM64SLWalkingPenguinCollisionResult? {
        guard input.position.x.isFinite,
              input.position.y.isFinite,
              input.position.z.isFinite,
              input.wallHitboxRadius.isFinite,
              input.wallHitboxRadius >= 0 else {
            return nil
        }

        var position = input.position
        let wall = input.world.findWallCollisions(
            SM64WallCollisionInput(
                x: position.x,
                y: position.y,
                z: position.z,
                offsetY: 10,
                radius: input.wallHitboxRadius
            )
        )
        position.x = wall.x
        position.y = wall.y
        position.z = wall.z

        let floor = input.world.findFloor(
            x: position.x,
            y: position.y,
            z: position.z
        )
        var moveFlags = input.previousMoveFlags
        moveFlags &= ~(
            Self.hitWall
                | Self.aboveLava
                | Self.aboveDeathBarrier
                | Self.inAir
        )

        if let wallID = wall.surfaceIDs.last,
           let wallSurface = input.world.surface(withID: wallID) {
            let wallYaw = SM64CanonicalTrig.atan2s(
                y: wallSurface.normal.z,
                x: wallSurface.normal.x
            )
            if Self.absoluteAngleDifference(wallYaw, input.moveYaw) > 0x4000 {
                moveFlags |= Self.hitWall
            }
        }

        if position.y > floor.height {
            moveFlags |= Self.inAir
        }
        if floor.type == 0x0001 {
            moveFlags |= Self.aboveLava
        } else if floor.type == 0x000A {
            moveFlags |= Self.aboveDeathBarrier
        }

        return SM64SLWalkingPenguinCollisionResult(
            position: position,
            floorHeight: floor.height,
            floorSurfaceID: floor.surfaceID,
            floorType: floor.type ?? 0,
            floorNormalY: floor.normalY ?? 0,
            wallSurfaceIDs: wall.surfaceIDs,
            moveFlags: moveFlags
        )
    }

    private static func absoluteAngleDifference(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        var difference = Int32(lhs) - Int32(rhs)
        if difference == -0x8000 {
            difference = -0x7FFF
        }
        return abs(difference)
    }
}
