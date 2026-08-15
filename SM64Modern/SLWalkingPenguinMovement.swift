import Foundation

/// Scalar inputs for the `cur_obj_move_standard(-78)` portion of the
/// walking-penguin update.  The owner thread supplies the floor selected by
/// the immutable collision world for the behavior's candidate X/Z position.
struct SM64SLWalkingPenguinMovementInput: Equatable, Sendable {
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
    let activeFarAway: Bool
}

struct SM64SLWalkingPenguinMovementResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let moveFlags: UInt32
    let hitEdge: Bool
    let enteredWater: Bool
    let atWaterSurface: Bool
    let leftGround: Bool
    let bounced: Bool
}

/// Value implementation of the scalar movement portion used by the SL
/// walking penguin.  Wall projection and floor selection remain separate
/// collision concerns; this kernel consumes the selected candidate floor and
/// reproduces C's edge/steep-slope, drag, water, gravity, and ground flags.
enum SM64SLWalkingPenguinMovement {
    static let steepSlopeAngleDegrees: Int16 = 78
    static let landed: UInt32 = 1 << 0
    static let onGround: UInt32 = 1 << 1
    static let leftGround: UInt32 = 1 << 2
    static let enteredWater: UInt32 = 1 << 3
    static let atWaterSurface: UInt32 = 1 << 4
    static let underwaterOffGround: UInt32 = 1 << 5
    static let underwaterOnGround: UInt32 = 1 << 6
    static let inAir: UInt32 = 1 << 7
    static let hitEdge: UInt32 = 1 << 10
    static let bounce: UInt32 = 1 << 13

    private static let waterMask: UInt32 =
        enteredWater | atWaterSurface | underwaterOffGround | underwaterOnGround
    private static let onGroundMask: UInt32 = landed | onGround

    static func resolve(
        _ input: SM64SLWalkingPenguinMovementInput
    ) -> SM64SLWalkingPenguinMovementResult? {
        guard input.startPosition.x.isFinite,
              input.startPosition.y.isFinite,
              input.startPosition.z.isFinite,
              input.candidatePosition.x.isFinite,
              input.candidatePosition.y.isFinite,
              input.candidatePosition.z.isFinite,
              input.velocityY.isFinite,
              input.forwardVelocity.isFinite,
              input.floorHeight.isFinite,
              input.gravity.isFinite,
              input.bounciness.isFinite,
              input.dragStrength.isFinite,
              input.buoyancy.isFinite,
              input.nativeStepScale.isFinite,
              input.nativeStepScale >= 0,
              input.intendedFloorHeight.isFinite,
              input.intendedFloorNormalY.isFinite,
              input.waterLevel.isFinite else {
            return nil
        }

        var position = input.candidatePosition
        var velocityY = input.velocityY
        var velocityX = SM64CanonicalTrig.sins(input.moveYaw) * input.forwardVelocity
        var velocityZ = SM64CanonicalTrig.coss(input.moveYaw) * input.forwardVelocity
        applyDrag(&velocityX, strength: input.dragStrength, scale: input.nativeStepScale)
        applyDrag(&velocityZ, strength: input.dragStrength, scale: input.nativeStepScale)

        var moveFlags = input.moveFlags
        var hitEdge = false
        let steepSlopeNormalY = SM64CanonicalTrig.coss(
            Int16(truncatingIfNeeded: Int32(Self.steepSlopeAngleDegrees) * (0x1_0000 / 360))
        )
        let deltaFloorHeight = input.intendedFloorHeight - input.floorHeight
        let roomAdmitted = input.objectRoom == -1
            || !input.intendedFloorExists
            || input.intendedFloorRoom == 0
            || input.objectRoom == input.intendedFloorRoom
            || input.intendedFloorRoom == 18

        moveFlags &= ~Self.hitEdge
        if !roomAdmitted || input.intendedFloorHeight < -10_000 {
            hitEdge = true
        } else if deltaFloorHeight < 5 {
            if deltaFloorHeight < -50,
               moveFlags & Self.onGround != 0 {
                hitEdge = true
            } else if input.intendedFloorNormalY > steepSlopeNormalY {
                position.x = input.candidatePosition.x
                position.z = input.candidatePosition.z
            } else {
                hitEdge = true
            }
        } else if input.intendedFloorNormalY > steepSlopeNormalY
                    || input.startPosition.y > input.intendedFloorHeight {
            // C moves onto a permissible upward slope (and reports FALSE),
            // or moves while airborne even when the target is steep.
            position.x = input.candidatePosition.x
            position.z = input.candidatePosition.z
        } else {
            // A steep upward slope is rejected without setting HIT_EDGE.
            position.x = input.startPosition.x
            position.z = input.startPosition.z
        }
        if hitEdge {
            position.x = input.startPosition.x
            position.z = input.startPosition.z
            moveFlags |= Self.hitEdge
        }

        moveFlags &= ~Self.leftGround
        var enteredWater = false
        var atWaterSurface = false
        var leftGround = false
        var bounced = false

        if moveFlags & Self.atWaterSurface != 0, velocityY > 5 {
            moveFlags &= ~Self.waterMask
            moveFlags |= 1 << 12 // OBJ_MOVE_LEAVING_WATER
        }

        if moveFlags & Self.waterMask == 0 {
            velocityY += input.gravity * input.nativeStepScale
            if velocityY < -78 { velocityY = -78 }
            position.y += velocityY * input.nativeStepScale
            if position.y > input.waterLevel {
                let ground = updateGroundAir(
                    position: &position,
                    velocityY: &velocityY,
                    moveFlags: &moveFlags,
                    floorHeight: input.floorHeight,
                    bounciness: input.bounciness
                )
                leftGround = ground.leftGround
                bounced = ground.bounced
            } else {
                enteredWater = true
                moveFlags |= Self.enteredWater
                moveFlags &= ~Self.onGroundMask
            }
        } else {
            moveFlags &= ~Self.enteredWater
            velocityY += (input.gravity + input.buoyancy) * input.nativeStepScale
            if velocityY < -78 { velocityY = -78 }
            position.y += velocityY * input.nativeStepScale
            if position.y < input.waterLevel {
                let decelY = abs(velocityY) * (input.dragStrength * 7) / 100
                if velocityY > 0 { velocityY -= decelY } else { velocityY += decelY }
                if position.y < input.floorHeight {
                    position.y = input.floorHeight
                    moveFlags |= Self.underwaterOnGround
                } else {
                    moveFlags |= Self.underwaterOffGround
                }
            } else if position.y < input.floorHeight {
                position.y = input.floorHeight
                moveFlags &= ~Self.waterMask
            } else {
                position.y = input.waterLevel
                velocityY = 0
                moveFlags &= ~(Self.underwaterOffGround | Self.underwaterOnGround)
                moveFlags |= Self.atWaterSurface
                atWaterSurface = true
            }
        }

        if moveFlags & (Self.onGroundMask | Self.atWaterSurface | Self.underwaterOffGround) != 0 {
            moveFlags &= ~Self.inAir
        } else {
            moveFlags |= Self.inAir
        }

        let negativeSpeed = input.forwardVelocity < 0
        var forwardVelocity = (velocityX * velocityX + velocityZ * velocityZ).squareRoot()
        if negativeSpeed { forwardVelocity = -forwardVelocity }
        return SM64SLWalkingPenguinMovementResult(
            position: position,
            velocity: SM64ObjectVector3(x: velocityX, y: velocityY, z: velocityZ),
            forwardVelocity: forwardVelocity,
            moveFlags: moveFlags,
            hitEdge: hitEdge,
            enteredWater: enteredWater,
            atWaterSurface: atWaterSurface,
            leftGround: leftGround,
            bounced: bounced
        )
    }

    private static func applyDrag(_ value: inout Float, strength: Float, scale: Float) {
        guard value != 0 else { return }
        let deceleration = value * value * (strength * 0.0001) * scale
        if value > 0 {
            value -= deceleration
            if value < 0.001 { value = 0 }
        } else {
            value += deceleration
            if value > -0.001 { value = 0 }
        }
    }

    private static func updateGroundAir(
        position: inout SM64ObjectVector3,
        velocityY: inout Float,
        moveFlags: inout UInt32,
        floorHeight: Float,
        bounciness: Float
    ) -> (leftGround: Bool, bounced: Bool) {
        moveFlags &= ~Self.bounce
        var leftGround = false
        var bounced = false
        if position.y < floorHeight {
            if moveFlags & Self.onGround == 0 {
                if moveFlags & Self.landed != 0 {
                    moveFlags &= ~Self.landed
                    moveFlags |= Self.onGround
                } else {
                    moveFlags |= Self.landed
                }
            }
            position.y = floorHeight
            if velocityY < 0 { velocityY *= bounciness }
            if velocityY > 5 {
                moveFlags |= Self.bounce
                bounced = true
            }
        } else {
            moveFlags &= ~Self.landed
            if moveFlags & Self.onGround != 0 {
                moveFlags &= ~Self.onGround
                moveFlags |= Self.leftGround
                leftGround = true
            }
        }
        moveFlags &= ~Self.waterMask
        return (leftGround, bounced)
    }
}
