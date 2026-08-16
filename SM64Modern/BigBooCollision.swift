import Foundation

struct SM64BigBooCollisionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let forwardVelocity: Float
    let wallHitboxRadius: Float
    let previousMoveFlags: UInt32
    let world: SM64SurfaceCollisionWorld
}

struct SM64BigBooCollisionResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floorHeight: Float
    let floorSurfaceID: UInt32?
    let floorType: Int16
    let floorRoom: Int8
    let floorNormalY: Float
    let wallSurfaceIDs: [UInt32]
    let moveFlags: UInt32
    let hitWall: Bool
}

typealias SM64BigBooMovementInput = SM64SLWalkingPenguinMovementInput
typealias SM64BigBooMovementResult = SM64SLWalkingPenguinMovementResult

/// Big Boo's source physics are SET_OBJ_PHYSICS(30, 0, -50, 1000, 1000,
/// 200), which resolves to a 30-unit wall probe, dynamic gravity supplied by
/// the oscillation state, bounciness -0.5, drag 10, and buoyancy 2.
enum SM64BigBooCollision {
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let inAir: UInt32 = 1 << 7
    static let hitWall: UInt32 = 1 << 9
    static let hitEdge: UInt32 = 1 << 10
    static let aboveLava: UInt32 = 1 << 11
    static let aboveDeathBarrier: UInt32 = 1 << 14

    static let wallHitboxRadius: Float = 30
    static let bounciness: Float = -0.5
    static let dragStrength: Float = 10
    static let buoyancy: Float = 2

    static func resolve(_ input: SM64BigBooCollisionInput) -> SM64BigBooCollisionResult? {
        guard let result = SM64SLWalkingPenguinCollision.resolve(
            SM64SLWalkingPenguinCollisionInput(
                position: input.position,
                moveYaw: input.moveYaw,
                wallHitboxRadius: input.wallHitboxRadius,
                previousMoveFlags: input.previousMoveFlags,
                world: input.world
            )
        ) else {
            return nil
        }
        var moveFlags = result.moveFlags
        var hitWall = moveFlags & Self.hitWall != 0
        if input.forwardVelocity != 0 {
            let velocityX = SM64CanonicalTrig.sins(input.moveYaw) * input.forwardVelocity
            let velocityZ = SM64CanonicalTrig.coss(input.moveYaw) * input.forwardVelocity
            let intendedFloor = input.world.findFloor(
                x: result.position.x + velocityX,
                y: result.position.y,
                z: result.position.z + velocityZ
            )
            let steepNormalY = SM64CanonicalTrig.coss(
                Int16(truncatingIfNeeded: 60 * (0x1_0000 / 360))
            )
            if (intendedFloor.normalY ?? 0) < steepNormalY,
               intendedFloor.height - result.floorHeight > 0,
               intendedFloor.height > result.position.y {
                moveFlags |= Self.hitWall
                hitWall = true
            }
        }
        return SM64BigBooCollisionResult(
            position: result.position,
            floorHeight: result.floorHeight,
            floorSurfaceID: result.floorSurfaceID,
            floorType: result.floorType,
            floorRoom: result.floorSurfaceID.flatMap { input.world.surface(withID: $0)?.room } ?? 0,
            floorNormalY: result.floorNormalY,
            wallSurfaceIDs: result.wallSurfaceIDs,
            moveFlags: moveFlags,
            hitWall: hitWall
        )
    }

    static func move(_ input: SM64BigBooMovementInput) -> SM64BigBooMovementResult? {
        SM64SLWalkingPenguinMovement.resolve(input)
    }
}
