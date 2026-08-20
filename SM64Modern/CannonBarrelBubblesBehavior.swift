import Foundation

struct SM64CannonBarrelBubblesInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let parentPosition: SM64ObjectVector3
    let relativePosition: SM64ObjectVector3
    let parentFaceYaw: Int32
    let parentMovePitch: Int32
    let parentAction: Int32
    let accumulatedDistance: Float
    let forwardVelocity: Float
    let cannonActive: Bool
}

struct SM64CannonBarrelBubblesOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let facePitch: Int32
    let accumulatedDistance: Float
    let forwardVelocity: Float
    let spawnBomb: Bool
    let bombPosition: SM64ObjectVector3
    let shouldDeactivate: Bool
}

enum SM64CannonBarrelBubblesBehavior {
    private static func approach(_ value: Float, target: Float, delta: Float) -> Float {
        let signedDelta = value > target ? -delta : delta
        let next = value + signedDelta
        return (next - target) * signedDelta >= 0 ? target : next
    }

    static func update(_ input: SM64CannonBarrelBubblesInput) -> SM64CannonBarrelBubblesOutput {
        let moveYaw = input.parentFaceYaw
        let movePitch = input.parentMovePitch &+ 0x4000
        if input.parentAction == 2 {
            return .init(position: input.position, moveYaw: moveYaw, movePitch: movePitch, facePitch: input.parentMovePitch, accumulatedDistance: input.accumulatedDistance, forwardVelocity: input.forwardVelocity, spawnBomb: false, bombPosition: input.position, shouldDeactivate: true)
        }
        let nextDistance = input.accumulatedDistance + input.forwardVelocity
        if nextDistance > 0 {
            return .init(position: input.position, moveYaw: moveYaw, movePitch: movePitch, facePitch: input.parentMovePitch, accumulatedDistance: nextDistance, forwardVelocity: approach(input.forwardVelocity, target: -5, delta: 18), spawnBomb: false, bombPosition: input.position, shouldDeactivate: false)
        }
        let shouldSpawn = input.cannonActive && input.forwardVelocity == 0
        return .init(position: input.parentPosition, moveYaw: moveYaw, movePitch: movePitch, facePitch: input.parentMovePitch, accumulatedDistance: 0, forwardVelocity: shouldSpawn ? 35 : 0, spawnBomb: shouldSpawn, bombPosition: input.parentPosition, shouldDeactivate: false)
    }
}
