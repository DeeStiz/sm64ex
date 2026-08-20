import Foundation

enum SM64FishVariant: UInt8, Equatable, Sendable { case blue20 = 0; case blue5 = 1; case cyan20 = 2; case cyan5 = 3 }
enum SM64FishRole: UInt8, Equatable, Sendable { case group = 0; case fish = 1 }

struct SM64FishGroupOutput: Equatable, Sendable {
    let action: Int32
    let variant: SM64FishVariant
    let spawnedChildren: Int
}

struct SM64FishOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let animationAcceleration: Float
    let shouldDelete: Bool
}

enum SM64FishBehavior {
    static func updateGroup(action: Int32, variant: SM64FishVariant, distanceToMario: Float, secretAquarium: Bool) -> SM64FishGroupOutput {
        if action == 0 && (distanceToMario < 1_500 || secretAquarium) {
            return .init(action: 1, variant: variant, spawnedChildren: variant == .blue20 || variant == .cyan20 ? 20 : 5)
        }
        if action == 1 && distanceToMario > 2_000 { return .init(action: 2, variant: variant, spawnedChildren: 0) }
        if action == 2 { return .init(action: 0, variant: variant, spawnedChildren: 0) }
        return .init(action: action, variant: variant, spawnedChildren: 0)
    }

    static func updateFish(action: Int32, timer: Int32, position: SM64ObjectVector3, moveYaw: Int32, forwardVelocity: Float, targetY: Float, angleToMario: Int32, angleToHome: Int32, parentDuplicate: Bool) -> SM64FishOutput {
        var nextAction = action
        var nextTimer = timer &+ 1
        var nextYaw = moveYaw
        var nextForward = forwardVelocity
        var nextPosition = position
        var animation: Float = timer < 10 ? 2 : 1
        if action == 0 {
            nextAction = 1; nextTimer = 0; nextForward = 3
        } else if action == 1 {
            nextYaw = approachAngle(current: moveYaw, target: angleToMario, increment: 0x400)
            nextPosition.y = approach(position.y, target: targetY, step: 2)
            if timer > 90 { nextAction = 2; nextTimer = 0 }
        } else if action == 2 {
            animation = 4
            nextYaw = approachAngle(current: moveYaw, target: angleToMario &+ 0x8000, increment: 0x400)
            nextPosition.y = approach(position.y, target: targetY, step: 4)
            if timer > 60 { nextAction = 1; nextTimer = 0 }
        }
        nextPosition.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextYaw)) * nextForward
        nextPosition.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextYaw)) * nextForward
        _ = angleToHome
        return .init(action: nextAction, timer: nextTimer, position: nextPosition, moveYaw: nextYaw, forwardVelocity: nextForward, animationAcceleration: animation, shouldDelete: parentDuplicate)
    }

    private static func approach(_ current: Float, target: Float, step: Float) -> Float { current < target ? min(current + step, target) : max(current - step, target) }
    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 { let delta = Int16(truncatingIfNeeded: target &- current); if delta > Int16(increment) { return current &+ increment }; if delta < -Int16(increment) { return current &- increment }; return target }
}
