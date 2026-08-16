import Foundation

struct SM64KingBobombCollisionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let forwardVelocity: Float
    let wallHitboxRadius: Float
    let previousMoveFlags: UInt32
    let world: SM64SurfaceCollisionWorld
}

struct SM64KingBobombCollisionResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floorHeight: Float
    let floorSurfaceID: UInt32?
    let floorType: Int16
    let floorRoom: Int8
    let floorNormalY: Float
    let wallSurfaceIDs: [UInt32]
    let moveFlags: UInt32
    let hitWall: Bool
    let steepFloor: Bool
}

struct SM64KingBobombMovementInput: Equatable, Sendable {
    let startPosition: SM64ObjectVector3
    let candidatePosition: SM64ObjectVector3
    let velocityY: Float
    let forwardVelocity: Float
    let moveYaw: Int16
    let floorHeight: Float
    let floorRoom: Int8
    let objectRoom: Int8
    let moveFlags: UInt32
    let gravity: Float
    let bounciness: Float
    let dragStrength: Float
    let buoyancy: Float
    let nativeStepScale: Float
    let intendedFloorHeight: Float
    let intendedFloorNormalY: Float
    let intendedFloorRoom: Int8
    let intendedFloorExists: Bool
    let waterLevel: Float
}

struct SM64KingBobombMovementResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let moveFlags: UInt32
    let hitEdge: Bool
    let landed: Bool
    let onGround: Bool
}

/// Collision and standard movement counterpart for `king_bobomb_move`.
/// Queries stay in the immutable surface world; the owner bridge later
/// applies these copied results to the mutable object record before the value
/// action function runs.
enum SM64KingBobombCollision {
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let leftGround: UInt32 = 1 << 2
    static let enteredWater: UInt32 = 1 << 3
    static let atWaterSurface: UInt32 = 1 << 4
    static let underwaterOffGround: UInt32 = 1 << 5
    static let underwaterOnGround: UInt32 = 1 << 6
    static let inAir: UInt32 = 1 << 7
    static let hitWall: UInt32 = 1 << 9
    static let hitEdge: UInt32 = 1 << 10
    static let aboveLava: UInt32 = 1 << 11
    static let bounce: UInt32 = 1 << 13
    static let aboveDeathBarrier: UInt32 = 1 << 14

    private static let maskClearedByPrepass: UInt32 =
        hitWall | aboveLava | aboveDeathBarrier | inAir

    static func resolve(
        _ input: SM64KingBobombCollisionInput
    ) -> SM64KingBobombCollisionResult? {
        guard input.position.x.isFinite,
              input.position.y.isFinite,
              input.position.z.isFinite,
              input.forwardVelocity.isFinite,
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

        let floor = input.world.findFloor(x: position.x, y: position.y, z: position.z)
        var moveFlags = input.previousMoveFlags & ~Self.maskClearedByPrepass
        var hitWall = false

        if let wallID = wall.surfaceIDs.last,
           let wallSurface = input.world.surface(withID: wallID) {
            let wallYaw = SM64CanonicalTrig.atan2s(
                y: wallSurface.normal.z,
                x: wallSurface.normal.x
            )
            hitWall = absoluteAngleDifference(wallYaw, input.moveYaw) > 0x4000
        }

        let floorType = floor.type ?? 0
        if floorType == 0x0001 {
            moveFlags |= Self.aboveLava
        } else if floorType == 0x000A {
            moveFlags |= Self.aboveDeathBarrier
        }
        if position.y > floor.height {
            moveFlags |= Self.inAir
        }

        // `cur_obj_update_floor_and_walls` also treats a steep upward floor as
        // a wall. The source uses the 60-degree prepass threshold.
        var steepFloor = false
        if input.forwardVelocity != 0 {
            let velocityX = SM64CanonicalTrig.sins(input.moveYaw) * input.forwardVelocity
            let velocityZ = SM64CanonicalTrig.coss(input.moveYaw) * input.forwardVelocity
            let intendedFloor = input.world.findFloor(
                x: position.x + velocityX,
                y: position.y,
                z: position.z + velocityZ
            )
            let steepNormalY = SM64CanonicalTrig.coss(
                Int16(truncatingIfNeeded: 60 * (0x1_0000 / 360))
            )
            steepFloor = (intendedFloor.normalY ?? 0) < steepNormalY
                && intendedFloor.height - floor.height > 0
                && intendedFloor.height > position.y
        }
        if hitWall || steepFloor { moveFlags |= Self.hitWall }

        return SM64KingBobombCollisionResult(
            position: position,
            floorHeight: floor.height,
            floorSurfaceID: floor.surfaceID,
            floorType: floorType,
            floorRoom: floor.surfaceID.flatMap { input.world.surface(withID: $0)?.room } ?? 0,
            floorNormalY: floor.normalY ?? 0,
            wallSurfaceIDs: wall.surfaceIDs,
            moveFlags: moveFlags,
            hitWall: hitWall,
            steepFloor: steepFloor
        )
    }

    /// Value counterpart of `cur_obj_move_standard(-78)`. The scalar kernel
    /// is shared with the already-qualified C-order movement implementation,
    /// but the King Bob-omb façade keeps its bounciness/rooms/water contract
    /// explicit for the later owner bridge.
    static func move(
        _ input: SM64KingBobombMovementInput
    ) -> SM64KingBobombMovementResult? {
        guard let result = SM64SLWalkingPenguinMovement.resolve(
            SM64SLWalkingPenguinMovementInput(
                startPosition: input.startPosition,
                candidatePosition: input.candidatePosition,
                velocityY: input.velocityY,
                forwardVelocity: input.forwardVelocity,
                moveYaw: input.moveYaw,
                floorHeight: input.floorHeight,
                floorRoom: input.floorRoom,
                objectRoom: input.objectRoom,
                moveFlags: input.moveFlags,
                gravity: input.gravity,
                bounciness: input.bounciness,
                dragStrength: input.dragStrength,
                buoyancy: input.buoyancy,
                nativeStepScale: input.nativeStepScale,
                intendedFloorHeight: input.intendedFloorHeight,
                intendedFloorNormalY: input.intendedFloorNormalY,
                intendedFloorRoom: input.intendedFloorRoom,
                intendedFloorExists: input.intendedFloorExists,
                waterLevel: input.waterLevel,
                activeFarAway: false
            )
        ) else {
            return nil
        }
        return SM64KingBobombMovementResult(
            position: result.position,
            velocity: result.velocity,
            forwardVelocity: result.forwardVelocity,
            moveFlags: result.moveFlags,
            hitEdge: result.hitEdge,
            landed: result.moveFlags & Self.landed != 0,
            onGround: result.moveFlags & Self.onGround != 0
        )
    }

    private static func absoluteAngleDifference(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        var difference = Int32(lhs) - Int32(rhs)
        if difference == -0x8000 { difference = -0x7FFF }
        return abs(difference)
    }
}
