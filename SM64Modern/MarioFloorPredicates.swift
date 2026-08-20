import Foundation

struct SM64MarioFloorPredicatesInput: Equatable, Sendable {
    let floorPresent: Bool
    let floorType: UInt32
    let terrainType: UInt16
    let normalY: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let isCrawling: Bool
    let turnYaw: Int16
    let forwardVelocity: Float
}

struct SM64MarioFloorPredicatesResult: Equatable, Sendable {
    let floorClass: Int32
    let isSlippery: Bool
    let isSlope: Bool
    let isSteep: Bool
    let facingDownhill: Bool
}

/// Value counterpart of the shared floor class/slippery/slope/steep helpers.
enum SM64MarioFloorPredicates {
    private static let defaultClass: Int32 = 0x0000
    private static let verySlipperyClass: Int32 = 0x0013
    private static let slipperyClass: Int32 = 0x0014
    private static let notSlipperyClass: Int32 = 0x0015

    static func update(_ input: SM64MarioFloorPredicatesInput) -> SM64MarioFloorPredicatesResult? {
        guard input.normalY.isFinite, input.forwardVelocity.isFinite else { return nil }
        var floorClass: Int32 = (input.terrainType & 0x0007) == 0x0006
            ? verySlipperyClass : defaultClass
        if input.floorPresent {
            switch input.floorType {
            case 0x0015, 0x0037, 0x007A:
                floorClass = notSlipperyClass
            case 0x0014, 0x002A, 0x0035, 0x0079:
                floorClass = slipperyClass
            case 0x0013, 0x002E, 0x0036, 0x0073, 0x0074, 0x0075, 0x0078:
                floorClass = verySlipperyClass
            default:
                break
            }
            if input.isCrawling && input.normalY > 0.5 && floorClass == defaultClass {
                floorClass = notSlipperyClass
            }
        }

        var facingYaw = input.faceYaw
        if input.turnYaw != 0 && input.forwardVelocity < 0 {
            facingYaw = Int16(truncatingIfNeeded: Int32(facingYaw) + Int32(Int16(bitPattern: 0x8000)))
        }
        let facingDelta = Int16(truncatingIfNeeded: Int32(input.floorAngle) - Int32(facingYaw))
        let facingDownhill = facingDelta > -0x4000 && facingDelta < 0x4000

        guard input.floorPresent else {
            return SM64MarioFloorPredicatesResult(
                floorClass: floorClass, isSlippery: false, isSlope: false,
                isSteep: false, facingDownhill: facingDownhill
            )
        }
        let terrainSlide = (input.terrainType & 0x0007) == 0x0006
        let slippery: Bool
        let slope: Bool
        if terrainSlide && input.normalY < 0.9998477 {
            slippery = true
            slope = true
        } else {
            let slipperyLimit: Float
            let slopeLimit: Float
            switch floorClass {
            case verySlipperyClass:
                slipperyLimit = 0.9848077
                slopeLimit = 0.9961947
            case slipperyClass:
                slipperyLimit = 0.9396926
                slopeLimit = 0.9848077
            case notSlipperyClass:
                slipperyLimit = 0
                slopeLimit = 0.9396926
            default:
                slipperyLimit = 0.7880108
                slopeLimit = 0.9659258
            }
            slippery = input.normalY <= slipperyLimit
            slope = input.normalY <= slopeLimit
        }
        let steepLimit: Float = floorClass == verySlipperyClass
            ? 0.9659258
            : floorClass == slipperyClass ? 0.9396926 : 0.8660254
        return SM64MarioFloorPredicatesResult(
            floorClass: floorClass,
            isSlippery: slippery,
            isSlope: slope,
            isSteep: !facingDownhill && input.normalY <= steepLimit,
            facingDownhill: facingDownhill
        )
    }
}
