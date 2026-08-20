import Foundation

struct SM64MarioVerticalWindInput: Equatable, Sendable {
    let action: UInt32
    let floorType: UInt32
    let positionY: Float
    let velocityY: Float
}

struct SM64MarioVerticalWindResult: Equatable, Sendable {
    let velocityY: Float
    let active: Bool
}

/// Value counterpart of `apply_vertical_wind`; C retains sound delivery and
/// pointer-backed Mario mutation.
enum SM64MarioVerticalWind {
    private static let groundPound: UInt32 = 0x0080_08A9
    private static let verticalWindSurface: UInt32 = 0x0038

    static func update(_ input: SM64MarioVerticalWindInput) -> SM64MarioVerticalWindResult? {
        guard input.positionY.isFinite, input.velocityY.isFinite else { return nil }
        var velocityY = input.velocityY
        var active = false
        if input.action != groundPound {
            let offsetY = input.positionY + 1500
            if input.floorType == verticalWindSurface,
               offsetY > -3000, offsetY < 2000 {
                let maxVelocityY = offsetY >= 0
                    ? 10000 / (offsetY + 200)
                    : 50
                active = true
                if velocityY < maxVelocityY {
                    velocityY += maxVelocityY / 8
                    if velocityY > maxVelocityY { velocityY = maxVelocityY }
                }
            }
        }
        return SM64MarioVerticalWindResult(velocityY: velocityY, active: active)
    }
}
