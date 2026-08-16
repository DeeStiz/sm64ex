import Foundation

struct SM64BullyCollisionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let wallHitboxRadius: Float
    let previousMoveFlags: UInt32
    let world: SM64SurfaceCollisionWorld
}

struct SM64BullyCollisionResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floorHeight: Float
    let floorSurfaceID: UInt32?
    let floorType: Int16
    let floorRoom: Int8
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let wallSurfaceIDs: [UInt32]
    let moveFlags: UInt32
    let collisionFlags: UInt32
    let hitWall: Bool
}

struct SM64BullyMovementInput: Equatable, Sendable {
    let startPosition: SM64ObjectVector3
    let candidatePosition: SM64ObjectVector3
    let velocityY: Float
    let forwardVelocity: Float
    let moveYaw: Int16
    let floorHeight: Float
    let floorRoom: Int8
    let objectRoom: Int8
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let moveFlags: UInt32
    let collisionFlags: UInt32
    let gravity: Float
    let friction: Float
    let buoyancy: Float
    let intendedFloorHeight: Float
    let intendedFloorNormalY: Float
    let intendedFloorRoom: Int8
    let intendedFloorExists: Bool
    let waterLevel: Float
}

struct SM64BullyMovementResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let moveFlags: UInt32
    let collisionFlags: UInt32
    let hitEdge: Bool
    let underwater: Bool
}

/// Value boundary for `object_step()` used by the Bully family. The owner
/// bridge supplies an immutable surface world and applies the returned scalar
/// movement to the generation-safe record after the action kernel.
enum SM64BullyCollision {
    static let grounded: UInt32 = 1 << 0
    static let hitWallFlag: UInt32 = 1 << 1
    static let underwaterFlag: UInt32 = 1 << 2
    static let noYVelocity: UInt32 = 1 << 3
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let inAir: UInt32 = 1 << 7
    static let hitWall: UInt32 = 1 << 9
    static let hitEdge: UInt32 = 1 << 10
    static let aboveLava: UInt32 = 1 << 11
    static let aboveDeathBarrier: UInt32 = 1 << 14

    static let wallHitboxRadius: Float = 0
    static let smallGravity: Float = 4
    static let bigGravity: Float = 5
    static let smallFriction: Float = 0.91
    static let bigFriction: Float = 0.93
    static let buoyancy: Float = 1.3

    static func resolve(_ input: SM64BullyCollisionInput) -> SM64BullyCollisionResult? {
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
        let floor = input.world.findFloor(x: result.position.x, y: result.position.y, z: result.position.z)
        var collisionFlags: UInt32 = 0
        let hitWall = result.moveFlags & SM64SLWalkingPenguinCollision.hitWall != 0
        if hitWall { collisionFlags |= Self.hitWallFlag }
        if result.position.y == result.floorHeight { collisionFlags |= Self.grounded }
        if floor.type == 0x0001 || floor.type == 0x000A {
            collisionFlags |= Self.underwaterFlag
        }
        let normal = SM64SurfaceVec3f(
            x: floor.normalX ?? 0,
            y: floor.normalY ?? 1,
            z: floor.normalZ ?? 0
        )
        return SM64BullyCollisionResult(
            position: result.position,
            floorHeight: result.floorHeight,
            floorSurfaceID: result.floorSurfaceID,
            floorType: result.floorType,
            floorRoom: result.floorSurfaceID.flatMap { input.world.surface(withID: $0)?.room } ?? 0,
            floorNormalX: normal.x,
            floorNormalY: normal.y,
            floorNormalZ: normal.z,
            wallSurfaceIDs: result.wallSurfaceIDs,
            moveFlags: result.moveFlags,
            collisionFlags: collisionFlags,
            hitWall: hitWall
        )
    }

    static func move(_ input: SM64BullyMovementInput) -> SM64BullyMovementResult? {
        guard input.gravity.isFinite,
              input.friction.isFinite,
              input.buoyancy.isFinite,
              input.velocityY.isFinite,
              input.forwardVelocity.isFinite,
              input.floorHeight.isFinite,
              input.intendedFloorHeight.isFinite,
              input.waterLevel.isFinite else {
            return nil
        }

        var position = input.candidatePosition
        var collisionFlags = input.collisionFlags & ~(Self.grounded | Self.underwaterFlag | Self.noYVelocity)
        var moveFlags = input.moveFlags & ~Self.hitEdge
        var hitEdge = false
        let steepNormalY = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: 60 * (0x1_0000 / 360)))
        let roomAdmitted = input.objectRoom == -1
            || !input.intendedFloorExists
            || input.intendedFloorRoom == 0
            || input.objectRoom == input.intendedFloorRoom
            || input.intendedFloorRoom == 18
        let deltaFloorHeight = input.intendedFloorHeight - input.floorHeight
        if !roomAdmitted || input.intendedFloorHeight < -10_000 {
            hitEdge = true
        } else if deltaFloorHeight < 5 {
            if deltaFloorHeight < -50, moveFlags & Self.onGround != 0 {
                hitEdge = true
            } else if input.intendedFloorNormalY <= steepNormalY {
                hitEdge = true
            }
        } else if input.intendedFloorNormalY <= steepNormalY,
                  input.startPosition.y <= input.intendedFloorHeight {
            hitEdge = true
        }
        if hitEdge {
            position.x = input.startPosition.x
            position.z = input.startPosition.z
            moveFlags |= Self.hitEdge
            collisionFlags |= Self.hitWallFlag
        }

        let underwater = input.waterLevel > position.y
        let netGravity = underwater ? (1 - input.buoyancy) * input.gravity : input.gravity
        var velocityY = input.velocityY - netGravity
        velocityY = min(max(velocityY, -75), 75)
        position.y += velocityY
        if position.y < input.floorHeight {
            position.y = input.floorHeight
            if velocityY < -17.5 {
                velocityY = -(velocityY / 2)
            } else {
                velocityY = 0
            }
        }

        var velocityX = SM64CanonicalTrig.sins(input.moveYaw) * input.forwardVelocity
        var velocityZ = SM64CanonicalTrig.coss(input.moveYaw) * input.forwardVelocity
        if position.y >= input.floorHeight && position.y < input.floorHeight + 37 {
            let denominator = input.floorNormalX * input.floorNormalX
                + input.floorNormalY * input.floorNormalY
                + input.floorNormalZ * input.floorNormalZ
            let horizontal = input.floorNormalX * input.floorNormalX
                + input.floorNormalZ * input.floorNormalZ
            if denominator > 0 {
                velocityX += input.floorNormalX * horizontal / denominator * input.gravity * 2
                velocityZ += input.floorNormalZ * horizontal / denominator * input.gravity * 2
            }
            let effectiveFriction = input.floorNormalY < 0.2 && input.friction < 0.9999
                ? 0
                : input.friction
            let speed = (velocityX * velocityX + velocityZ * velocityZ).squareRoot() * effectiveFriction
            if speed == 0 {
                velocityX = 0
                velocityZ = 0
            }
            let yaw = SM64CanonicalTrig.atan2s(y: velocityZ, x: velocityX)
            if velocityX != 0 || velocityZ != 0 {
                _ = yaw
            }
            let negativeSpeed = input.forwardVelocity < 0
            let signedSpeed = negativeSpeed ? -speed : speed
            velocityX = SM64CanonicalTrig.sins(input.moveYaw) * signedSpeed
            velocityZ = SM64CanonicalTrig.coss(input.moveYaw) * signedSpeed
        }
        if position.y == input.floorHeight { collisionFlags |= Self.grounded }
        if velocityY == 0 { collisionFlags |= Self.noYVelocity }
        if collisionFlags & Self.grounded == 0 { moveFlags |= Self.inAir }
        else { moveFlags &= ~Self.inAir }
        if underwater { collisionFlags |= Self.underwaterFlag }

        let speed = (velocityX * velocityX + velocityZ * velocityZ).squareRoot()
        let signedForwardVelocity = input.forwardVelocity < 0 ? -speed : speed
        return SM64BullyMovementResult(
            position: position,
            velocity: SM64ObjectVector3(x: velocityX, y: velocityY, z: velocityZ),
            forwardVelocity: signedForwardVelocity,
            moveFlags: moveFlags,
            collisionFlags: collisionFlags,
            hitEdge: hitEdge,
            underwater: underwater
        )
    }
}
