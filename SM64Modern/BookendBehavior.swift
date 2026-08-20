import Foundation

enum SM64BookendRole: UInt8, Equatable, Sendable { case spawner = 0; case flying = 1 }

struct SM64BookendOutput: Equatable, Sendable {
    let role: SM64BookendRole
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let spawnChild: Bool
}

enum SM64BookendBehavior {
    static func updateSpawner(timer: Int32, distanceToMario: Float, facingMario: Bool) -> SM64BookendOutput {
        let spawn = timer > 40 && distanceToMario < 600 && facingMario
        return .init(role: .spawner, action: 0, timer: spawn ? 0 : timer &+ 1, position: .zero, moveYaw: 0, forwardVelocity: 0, spawnChild: spawn)
    }

    static func updateFlying(action: Int32, timer: Int32, position: SM64ObjectVector3, moveYaw: Int32, forwardVelocity: Float) -> SM64BookendOutput {
        var nextAction = action
        var nextTimer = timer &+ 1
        var nextVelocity = forwardVelocity
        var nextPosition = position
        if action == 3 {
            nextVelocity = timer >= 4 ? 50 : max(forwardVelocity, 2)
            if timer >= 4 { nextAction = 2; nextTimer = 0 }
        } else if action == 2 {
            nextPosition.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw)) * nextVelocity
            nextPosition.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw)) * nextVelocity
        }
        return .init(role: .flying, action: nextAction, timer: nextTimer, position: nextPosition, moveYaw: moveYaw, forwardVelocity: nextVelocity, spawnChild: false)
    }
}
