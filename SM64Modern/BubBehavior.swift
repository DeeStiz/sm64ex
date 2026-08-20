import Foundation

enum SM64BubRole: UInt8, Equatable, Sendable { case spawner = 0; case bub = 1 }

struct SM64BubOutput: Equatable, Sendable {
    let role: SM64BubRole
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let spawnParticle: Bool
    let spawnedChildren: Int
    let shouldDelete: Bool
}

enum SM64BubBehavior {
    static func updateSpawner(action: Int32, timer: Int32, distanceToMario: Float, marioY: Float, positionY: Float, childCount: Int) -> SM64BubOutput {
        var nextAction = action
        var spawn = 0
        switch action {
        case 0 where distanceToMario < 1_500:
            nextAction = 1
            spawn = childCount
        case 1 where marioY - positionY > 2_000:
            nextAction = 2
        case 2:
            nextAction = 3
        case 3:
            nextAction = 0
        default:
            break
        }
        return .init(role: .spawner, action: nextAction, timer: timer &+ 1, position: .zero, moveYaw: 0, forwardVelocity: 0, velocityY: 0, spawnParticle: false, spawnedChildren: spawn, shouldDelete: false)
    }

    static func updateBub(
        action: Int32,
        timer: Int32,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        forwardVelocity: Float,
        waterLevel: Float,
        targetY: Float,
        angleToMario: Int32,
        angleToHome: Int32,
        distanceToMario: Float,
        lateralDistanceHome: Float,
        randomFleeTrigger: Bool,
        interacted: Bool,
        parentDuplicate: Bool
    ) -> SM64BubOutput {
        var nextAction = action
        var nextPosition = position
        var nextYaw = moveYaw
        var nextForward = forwardVelocity
        var spawnParticle = false
        var nextTimer = timer &+ 1

        if action == 0 {
            nextAction = 1
            nextTimer = 0
        } else if action == 1 {
            if timer == 0 { nextForward = 3 }
            nextPosition.y = verticalApproach(position.y, target: targetY, waterLevel: waterLevel, speed: 1)
            nextYaw = approachAngle(current: moveYaw, target: lateralDistanceHome > 800 ? angleToHome : angleToMario, increment: 0x100)
            if distanceToMario < 200 && randomFleeTrigger { nextAction = 2; nextTimer = 0 }
            if interacted { nextAction = 2; nextTimer = 0 }
        } else if action == 2 {
            if timer < 20 && interacted { spawnParticle = true }
            if nextForward == 0 { nextForward = 6 }
            nextPosition.y = verticalApproach(position.y, target: targetY, waterLevel: waterLevel, speed: 2)
            nextYaw = approachAngle(current: moveYaw, target: angleToMario &+ 0x8000, increment: 0x400)
            if timer > 200 && distanceToMario > 600 { nextAction = 1; nextTimer = 0 }
        }

        nextPosition.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextYaw)) * nextForward
        nextPosition.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextYaw)) * nextForward
        return .init(role: .bub, action: nextAction, timer: nextTimer, position: nextPosition, moveYaw: nextYaw, forwardVelocity: nextForward, velocityY: 0, spawnParticle: spawnParticle, spawnedChildren: 0, shouldDelete: parentDuplicate)
    }

    private static func verticalApproach(_ current: Float, target: Float, waterLevel: Float, speed: Float) -> Float {
        let ceiling = waterLevel - 50
        if current >= ceiling { return current > ceiling ? ceiling : current }
        if current < target { return min(current + speed, target) }
        return max(current - speed, target)
    }

    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- current)
        if delta > Int16(increment) { return current &+ increment }
        if delta < -Int16(increment) { return current &- increment }
        return target
    }
}
