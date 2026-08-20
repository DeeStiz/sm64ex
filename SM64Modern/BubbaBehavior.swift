import Foundation

/// Inputs retained at the Swift owner boundary for `bhvBubba`.
///
/// The native behavior keeps several Bubba-specific values in anonymous
/// object fields.  They are explicit here so the reducer is deterministic and
/// does not need to expose the C object layout to Swift.
struct SM64BubbaInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let attackTimer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let targetYaw: Int32
    let targetPitch: Int32
    let pitchToMario: Int32
    let pitchToHome: Int32
    let angleToMario: Int32
    let distanceToMario: Float
    let nearAndFacingMario: Bool
    let pitchAligned: Bool
    let inWater: Bool
    let wasInWater: Bool
    let waterLevel: Float
    let floorHeight: Float
    let hitWall: Bool
    let reflectedYaw: Int32
}

struct SM64BubbaOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let attackTimer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let targetYaw: Int32
    let targetPitch: Int32
    let animationState: Int32
    let interactionSubtype: UInt32
    let hurtboxRadius: Float
    let spawnWaterSplash: Bool
    let spawnWaterParticle: Bool
    let playChompSound: Bool
}

/// Value counterpart of `bubba_act_0`, `bubba_act_1`, and the movement /
/// hitbox portions of `bhv_bubba_loop`.
enum SM64BubbaBehavior {
    static let eatsMarioSubtype: UInt32 = 1 << 8

    static func update(_ input: SM64BubbaInput) -> SM64BubbaOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var attackTimer = input.attackTimer
        var position = input.position
        var moveYaw = input.moveYaw
        var movePitch = input.movePitch
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var targetYaw = input.targetYaw
        var targetPitch = input.targetPitch
        var animationState: Int32 = 0
        var playChompSound = false

        switch input.action {
        case 0:
            targetPitch = input.pitchToHome
            forwardVelocity = approach(input.forwardVelocity, target: 5, delta: 0.5)
            if input.hitWall {
                targetYaw = input.reflectedYaw
            } else if input.distanceToMario >= 25_000 {
                targetYaw = input.angleToMario
            } else if input.timer > 30 && input.distanceToMario < 2_000 {
                action = 1
                timer = 0
            }
        case 1:
            if input.distanceToMario > 2_500 {
                action = 0
                timer = 0
                attackTimer = 0
            } else if attackTimer != 0 {
                attackTimer -= 1
                if attackTimer == 0 {
                    action = 0
                    timer = 0
                    playChompSound = true
                } else if attackTimer < 15 {
                    animationState = 1
                } else if attackTimer == 20 {
                    targetPitch = input.pitchToMario
                    movePitch = targetPitch
                    forwardVelocity = 40
                } else {
                    targetYaw = input.angleToMario
                    targetPitch = input.pitchToMario
                    moveYaw = approachAngle(moveYaw, targetYaw, increment: 400)
                    movePitch = approachAngle(movePitch, targetPitch, increment: 400)
                }
            } else {
                targetYaw = input.angleToMario
                targetPitch = input.pitchToMario
                if input.nearAndFacingMario && input.pitchAligned {
                    attackTimer = 30
                    forwardVelocity = 0
                    animationState = 1
                } else {
                    forwardVelocity = approach(input.forwardVelocity, target: 20, delta: 0.5)
                }
            }
        default:
            action = 0
            timer = 0
            attackTimer = 0
        }

        if input.inWater {
            moveYaw = approachAngle(moveYaw, targetYaw, increment: 2_000)
            movePitch = approachAngle(movePitch, targetPitch, increment: 2_000)
            let horizontalVelocity = forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: movePitch))
            velocityY = forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: movePitch))
            position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw)) * horizontalVelocity
            position.y += velocityY
            position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw)) * horizontalVelocity
        } else {
            let horizontalVelocity = forwardVelocity
            position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw)) * horizontalVelocity
            position.y += velocityY
            position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw)) * horizontalVelocity
            velocityY = max(velocityY - 4, -20)
            let minimumY = input.floorHeight + 150
            if position.y < minimumY {
                position.y = minimumY
                velocityY = 0
            }
        }

        let facingAttackCone = absAngleDiff(input.angleToMario, moveYaw) < 0x1000
            && absAngleDiff(input.pitchToMario &+ 0x800, movePitch) < 0x2000
        let eating = animationState != 0 && input.distanceToMario < 250 && facingAttackCone
        let hurtboxRadius: Float = facingAttackCone ? 100 : 150

        return SM64BubbaOutput(
            action: action,
            timer: timer,
            attackTimer: attackTimer,
            position: position,
            moveYaw: moveYaw,
            movePitch: movePitch,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            targetYaw: targetYaw,
            targetPitch: targetPitch,
            animationState: animationState,
            interactionSubtype: eating ? eatsMarioSubtype : 0,
            hurtboxRadius: hurtboxRadius,
            spawnWaterSplash: input.inWater && !input.wasInWater,
            spawnWaterParticle: input.inWater && input.timer > 0 && input.timer % 8 == 0,
            playChompSound: playChompSound
        )
    }

    private static func approach(_ value: Float, target: Float, delta: Float) -> Float {
        if value < target { return min(value + delta, target) }
        return max(value - delta, target)
    }

    private static func approachAngle(_ value: Int32, _ target: Int32, increment: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- value)
        if delta > Int16(increment) { return value &+ increment }
        if delta < -Int16(increment) { return value &- increment }
        return target
    }

    private static func absAngleDiff(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        let delta = Int32(Int16(truncatingIfNeeded: lhs &- rhs))
        return delta < 0 ? -delta : delta
    }
}
