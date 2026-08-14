import Foundation

struct SM64MarioSlidingInput: Equatable, Sendable {
    let floorClass: SM64MarioFloorClass
    let floorIsSlope: Bool
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let intendedYaw: Int16
    let intendedMagnitude: Float
    let faceYaw: Int16
    let slideYaw: Int16
    let forwardVelocity: Float
    let slideVelocityX: Float
    let slideVelocityZ: Float
    let stopSpeed: Float
}

struct SM64MarioSlidingResult: Equatable, Sendable {
    let stopped: Bool
    let faceYaw: Int16
    let slideYaw: Int16
    let forwardVelocity: Float
    let slideVelocityX: Float
    let slideVelocityZ: Float
    let velocity: SM64ObjectVector3
    let shouldUpdateMovingSand: Bool
    let shouldUpdateWindyGround: Bool
}

/// Value counterpart of `update_sliding` and `update_sliding_angle`.
enum SM64MarioSliding {
    static func update(_ input: SM64MarioSlidingInput) -> SM64MarioSlidingResult? {
        guard input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
              input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.slideVelocityX.isFinite,
              input.slideVelocityZ.isFinite,
              input.stopSpeed.isFinite else {
            return nil
        }

        let intendedDelta = Int16(
            truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.slideYaw)
        )
        var forward = SM64CanonicalTrig.coss(intendedDelta)
        let sideward = SM64CanonicalTrig.sins(intendedDelta)
        if forward < 0 && input.forwardVelocity >= 0 {
            forward *= 0.5 + 0.5 * input.forwardVelocity / 100
        }

        let acceleration: Float
        let baseLoss: Float
        switch input.floorClass {
        case .verySlippery:
            acceleration = 10
            baseLoss = 0.98
        case .slippery:
            acceleration = 8
            baseLoss = 0.96
        case .notSlippery:
            acceleration = 5
            baseLoss = 0.92
        case .defaultClass:
            acceleration = 7
            baseLoss = 0.92
        }
        let lossFactor = input.intendedMagnitude / 32 * forward * 0.02 + baseLoss
        let oldSpeed = sqrt(input.slideVelocityX * input.slideVelocityX + input.slideVelocityZ * input.slideVelocityZ)

        // Preserve the C asymmetry: the updated X component is used while
        // calculating the Z component.
        var slideVelocityX = input.slideVelocityX
            + input.slideVelocityZ * (input.intendedMagnitude / 32) * sideward * 0.05
        var slideVelocityZ = input.slideVelocityZ
            - slideVelocityX * (input.intendedMagnitude / 32) * sideward * 0.05
        let newSpeed = sqrt(slideVelocityX * slideVelocityX + slideVelocityZ * slideVelocityZ)
        if oldSpeed > 0 && newSpeed > 0 {
            slideVelocityX = slideVelocityX * oldSpeed / newSpeed
            slideVelocityZ = slideVelocityZ * oldSpeed / newSpeed
        }

        let slopeAngle = SM64CanonicalTrig.atan2s(y: input.floorNormalZ, x: input.floorNormalX)
        let steepness = sqrt(input.floorNormalX * input.floorNormalX + input.floorNormalZ * input.floorNormalZ)
        slideVelocityX += acceleration * steepness * SM64CanonicalTrig.sins(slopeAngle)
        slideVelocityZ += acceleration * steepness * SM64CanonicalTrig.coss(slopeAngle)
        slideVelocityX *= lossFactor
        slideVelocityZ *= lossFactor

        let slideYaw = SM64CanonicalTrig.atan2s(y: slideVelocityZ, x: slideVelocityX)
        let facingDelta = Int16(
            truncatingIfNeeded: Int32(input.faceYaw) - Int32(slideYaw)
        )
        var newFacingDelta = Int32(facingDelta)
        if newFacingDelta > 0 && newFacingDelta <= 0x4000 {
            newFacingDelta -= 0x200
            if newFacingDelta < 0 { newFacingDelta = 0 }
        } else if newFacingDelta > -0x4000 && newFacingDelta < 0 {
            newFacingDelta += 0x200
            if newFacingDelta > 0 { newFacingDelta = 0 }
        } else if newFacingDelta > 0x4000 && newFacingDelta < 0x8000 {
            newFacingDelta += 0x200
            if newFacingDelta > 0x8000 { newFacingDelta = 0x8000 }
        } else if newFacingDelta > -0x8000 && newFacingDelta < -0x4000 {
            newFacingDelta -= 0x200
            if newFacingDelta < -0x8000 { newFacingDelta = -0x8000 }
        }
        let faceYaw = Int16(
            truncatingIfNeeded: Int32(slideYaw) + newFacingDelta
        )
        var forwardVelocity = sqrt(slideVelocityX * slideVelocityX + slideVelocityZ * slideVelocityZ)
        if forwardVelocity > 100 {
            slideVelocityX = slideVelocityX * 100 / forwardVelocity
            slideVelocityZ = slideVelocityZ * 100 / forwardVelocity
        }
        if newFacingDelta < -0x4000 || newFacingDelta > 0x4000 {
            forwardVelocity *= -1
        }

        var stopped = false
        if !input.floorIsSlope,
           forwardVelocity * forwardVelocity < input.stopSpeed * input.stopSpeed {
            forwardVelocity = 0
            slideVelocityX = SM64CanonicalTrig.sins(faceYaw) * forwardVelocity
            slideVelocityZ = SM64CanonicalTrig.coss(faceYaw) * forwardVelocity
            stopped = true
        }

        return SM64MarioSlidingResult(
            stopped: stopped,
            faceYaw: faceYaw,
            slideYaw: slideYaw,
            forwardVelocity: forwardVelocity,
            slideVelocityX: slideVelocityX,
            slideVelocityZ: slideVelocityZ,
            velocity: SM64ObjectVector3(x: slideVelocityX, y: 0, z: slideVelocityZ),
            shouldUpdateMovingSand: true,
            shouldUpdateWindyGround: true
        )
    }
}
