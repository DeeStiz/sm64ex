import Foundation

struct SM64WhompCollisionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let forwardVelocity: Float
    let wallHitboxRadius: Float
    let previousMoveFlags: UInt32
    let world: SM64SurfaceCollisionWorld
}

struct SM64WhompCollisionResult: Equatable, Sendable {
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

/// The Whomp behavior uses the same C floor/wall prepass and scalar movement
/// contract as the other standard actors, but its source physics constants are
/// explicit here: SET_OBJ_PHYSICS(0, -400, -50, 0, 0, 200) means gravity -4,
/// bounciness -0.5, drag 0, and buoyancy 2 in the value domain.
typealias SM64WhompMovementInput = SM64SLWalkingPenguinMovementInput
typealias SM64WhompMovementResult = SM64SLWalkingPenguinMovementResult

enum SM64WhompCollision {
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let inAir: UInt32 = 1 << 7
    static let hitWall: UInt32 = 1 << 9
    static let hitEdge: UInt32 = 1 << 10
    static let aboveLava: UInt32 = 1 << 11
    static let aboveDeathBarrier: UInt32 = 1 << 14

    static let gravity: Float = -4
    static let bounciness: Float = -0.5
    static let dragStrength: Float = 0
    static let buoyancy: Float = 2

    static func resolve(_ input: SM64WhompCollisionInput) -> SM64WhompCollisionResult? {
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
        return SM64WhompCollisionResult(
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

    static func move(_ input: SM64WhompMovementInput) -> SM64WhompMovementResult? {
        SM64SLWalkingPenguinMovement.resolve(input)
    }
}
