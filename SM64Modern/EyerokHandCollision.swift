import Foundation

struct SM64EyerokHandCollisionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let forwardVelocity: Float
    let wallHitboxRadius: Float
    let previousMoveFlags: UInt32
    let world: SM64SurfaceCollisionWorld
}

struct SM64EyerokHandCollisionResult: Equatable, Sendable {
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

typealias SM64EyerokHandMovementInput = SM64SLWalkingPenguinMovementInput
typealias SM64EyerokHandMovementResult = SM64SLWalkingPenguinMovementResult

/// Eyerok hands run the source `cur_obj_update_floor_and_walls()` prepass,
/// then `cur_obj_move_standard(-78)`. Their C object never assigns a wall
/// radius, so the owner default is zero; callers may still supply a copied
/// radius when validating a custom collision fixture.
enum SM64EyerokHandCollision {
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let inAir: UInt32 = 1 << 7
    static let hitWall: UInt32 = 1 << 9
    static let hitEdge: UInt32 = 1 << 10
    static let aboveLava: UInt32 = 1 << 11
    static let aboveDeathBarrier: UInt32 = 1 << 14

    static let wallHitboxRadius: Float = 0
    static let gravity: Float = -4
    static let bounciness: Float = 0
    static let dragStrength: Float = 0
    static let buoyancy: Float = 0

    static func resolve(_ input: SM64EyerokHandCollisionInput) -> SM64EyerokHandCollisionResult? {
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
        return SM64EyerokHandCollisionResult(
            position: result.position,
            floorHeight: result.floorHeight,
            floorSurfaceID: result.floorSurfaceID,
            floorType: result.floorType,
            floorRoom: result.floorSurfaceID.flatMap { input.world.surface(withID: $0)?.room } ?? 0,
            floorNormalY: result.floorNormalY,
            wallSurfaceIDs: result.wallSurfaceIDs,
            moveFlags: result.moveFlags,
            hitWall: result.moveFlags & Self.hitWall != 0
        )
    }

    static func move(_ input: SM64EyerokHandMovementInput) -> SM64EyerokHandMovementResult? {
        SM64SLWalkingPenguinMovement.resolve(input)
    }
}
