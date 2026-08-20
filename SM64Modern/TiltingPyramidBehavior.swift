import Foundation

enum SM64TiltingPyramidVariant: UInt8, Equatable, Sendable { case bitfs = 0; case another = 1; case lll = 2 }

struct SM64TiltingPyramidInput: Equatable, Sendable {
    let variant: SM64TiltingPyramidVariant
    let position: SM64ObjectVector3
    let normalX: Float
    let normalY: Float
    let normalZ: Float
    let marioPosition: SM64ObjectVector3
    let marioOnPlatform: Bool
}

struct SM64TiltingPyramidOutput: Equatable, Sendable {
    let variant: SM64TiltingPyramidVariant
    let position: SM64ObjectVector3
    let normalX: Float
    let normalY: Float
    let normalZ: Float
    let marioDisplacement: SM64ObjectVector3
    let collisionLoaded: Bool
}

enum SM64TiltingPyramidBehavior {
    static func update(_ input: SM64TiltingPyramidInput) -> SM64TiltingPyramidOutput {
        var targetX: Float = 0
        var targetY: Float = 1
        var targetZ: Float = 0
        if input.marioOnPlatform {
            var dx = input.marioPosition.x - input.position.x
            var dy: Float = 500
            var dz = input.marioPosition.z - input.position.z
            let length = (dx * dx + dy * dy + dz * dz).squareRoot()
            if length != 0 { dx /= length; dy /= length; dz /= length }
            targetX = dx; targetY = dy; targetZ = dz
        }
        let nextX = approach(input.normalX, target: targetX, step: 0.01)
        let nextY = approach(input.normalY, target: targetY, step: 0.01)
        let nextZ = approach(input.normalZ, target: targetZ, step: 0.01)
        return .init(
            variant: input.variant,
            position: input.position,
            normalX: nextX,
            normalY: nextY,
            normalZ: nextZ,
            marioDisplacement: .zero,
            collisionLoaded: input.variant != .another
        )
    }

    private static func approach(_ current: Float, target: Float, step: Float) -> Float {
        if current < target { return min(current + step, target) }
        return max(current - step, target)
    }
}
