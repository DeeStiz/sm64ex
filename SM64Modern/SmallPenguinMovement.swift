import Foundation

// The small penguin uses the same C helpers as the Snowman Land walking
// penguin: `cur_obj_update_floor_and_walls()` followed by
// `cur_obj_move_standard(-78)`.  Keep the façade names local to this route so
// the owner bridge cannot accidentally mix a different actor's movement
// constants while still sharing the already-qualified value implementation.
typealias SM64SmallPenguinCollisionInput = SM64SLWalkingPenguinCollisionInput
typealias SM64SmallPenguinCollisionResult = SM64SLWalkingPenguinCollisionResult
typealias SM64SmallPenguinMovementInput = SM64SLWalkingPenguinMovementInput
typealias SM64SmallPenguinMovementResult = SM64SLWalkingPenguinMovementResult

enum SM64SmallPenguinCollision {
    static let onGround = SM64SLWalkingPenguinCollision.onGround
    static let inAir = SM64SLWalkingPenguinCollision.inAir
    static let hitWall = SM64SLWalkingPenguinCollision.hitWall

    static func resolve(
        _ input: SM64SmallPenguinCollisionInput
    ) -> SM64SmallPenguinCollisionResult? {
        SM64SLWalkingPenguinCollision.resolve(input)
    }
}

enum SM64SmallPenguinMovement {
    static let landed = SM64SLWalkingPenguinMovement.landed
    static let onGround = SM64SLWalkingPenguinMovement.onGround
    static let inAir = SM64SLWalkingPenguinMovement.inAir
    static let enteredWater = SM64SLWalkingPenguinMovement.enteredWater
    static let atWaterSurface = SM64SLWalkingPenguinMovement.atWaterSurface
    static let underwaterOffGround = SM64SLWalkingPenguinMovement.underwaterOffGround
    static let underwaterOnGround = SM64SLWalkingPenguinMovement.underwaterOnGround

    static func resolve(
        _ input: SM64SmallPenguinMovementInput
    ) -> SM64SmallPenguinMovementResult? {
        SM64SLWalkingPenguinMovement.resolve(input)
    }
}
