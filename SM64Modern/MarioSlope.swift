import Foundation

enum SM64MarioFloorClass: Int16, Equatable, Sendable {
    case defaultClass = 0x0000
    case verySlippery = 0x0013
    case slippery = 0x0014
    case notSlippery = 0x0015
}

struct SM64MarioSlopeInput: Equatable, Sendable {
    let floorClass: SM64MarioFloorClass
    let terrainIsSlide: Bool
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let action: UInt32
}

struct SM64MarioSlopeResult: Equatable, Sendable {
    let facingDownhill: Bool
    let floorIsSlope: Bool
    let floorIsSteep: Bool
    let forwardVelocity: Float
    let slideYaw: Int16
    let slideVelocityX: Float
    let slideVelocityZ: Float
    let velocity: SM64ObjectVector3
    let shouldUpdateMovingSand: Bool
    let shouldUpdateWindyGround: Bool
}

/// Value counterparts of the C slope predicates and `apply_slope_accel`.
/// Terrain effects remain owner-thread intents; all scalar and velocity math is
/// deterministic and pointer-free.
enum SM64MarioSlope {
    private static let slideCosine: Float = 0.9998477
    private static let defaultSlopeCosine: Float = 0.9659258
    private static let slipperySlopeCosine: Float = 0.9848076
    private static let verySlipperySlopeCosine: Float = 0.9961947
    private static let notSlipperySlopeCosine: Float = 0.9396926

    static func update(_ input: SM64MarioSlopeInput) -> SM64MarioSlopeResult? {
        guard input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
              input.forwardVelocity.isFinite else {
            return nil
        }

        let floorDeltaYaw = Int32(Int16(truncatingIfNeeded: Int32(input.floorAngle) - Int32(input.faceYaw)))
        let facingDownhill = floorDeltaYaw > -0x4000 && floorDeltaYaw < 0x4000
        let floorIsSlope = isSlope(
            floorClass: input.floorClass,
            terrainIsSlide: input.terrainIsSlide,
            normalY: input.floorNormalY
        )
        let floorIsSteep = !facingDownhill && isSteep(
            floorClass: input.floorClass,
            normalY: input.floorNormalY
        )

        let steepness = sqrt(
            input.floorNormalX * input.floorNormalX
                + input.floorNormalZ * input.floorNormalZ
        )
        var forwardVelocity = input.forwardVelocity
        if floorIsSlope {
            let slopeAcceleration: Float
            switch input.action {
            case SM64MarioActionID.softBackwardGroundKnockback,
                 SM64MarioActionID.softForwardGroundKnockback:
                slopeAcceleration = 1.7
            case _ where input.floorClass == .verySlippery:
                slopeAcceleration = 5.3
            case _ where input.floorClass == .slippery:
                slopeAcceleration = 2.7
            case _ where input.floorClass == .notSlippery:
                slopeAcceleration = 0
            default:
                slopeAcceleration = 1.7
            }
            if floorDeltaYaw > -0x4000 && floorDeltaYaw < 0x4000 {
                forwardVelocity += slopeAcceleration * steepness
            } else {
                forwardVelocity -= slopeAcceleration * steepness
            }
        }

        let slideYaw = input.faceYaw
        let slideVelocityX = SM64CanonicalTrig.sins(slideYaw) * forwardVelocity
        let slideVelocityZ = SM64CanonicalTrig.coss(slideYaw) * forwardVelocity
        return SM64MarioSlopeResult(
            facingDownhill: facingDownhill,
            floorIsSlope: floorIsSlope,
            floorIsSteep: floorIsSteep,
            forwardVelocity: forwardVelocity,
            slideYaw: slideYaw,
            slideVelocityX: slideVelocityX,
            slideVelocityZ: slideVelocityZ,
            velocity: SM64ObjectVector3(x: slideVelocityX, y: 0, z: slideVelocityZ),
            shouldUpdateMovingSand: true,
            shouldUpdateWindyGround: true
        )
    }

    static func isSlope(
        floorClass: SM64MarioFloorClass,
        terrainIsSlide: Bool,
        normalY: Float
    ) -> Bool {
        if terrainIsSlide && normalY < slideCosine { return true }
        switch floorClass {
        case .verySlippery: return normalY <= verySlipperySlopeCosine
        case .slippery: return normalY <= slipperySlopeCosine
        case .notSlippery: return normalY <= notSlipperySlopeCosine
        case .defaultClass: return normalY <= defaultSlopeCosine
        }
    }

    static func isSteep(
        floorClass: SM64MarioFloorClass,
        normalY: Float
    ) -> Bool {
        switch floorClass {
        case .verySlippery: return normalY <= 0.9659258
        case .slippery: return normalY <= 0.9396926
        case .defaultClass, .notSlippery: return normalY <= 0.8660254
        }
    }
}
