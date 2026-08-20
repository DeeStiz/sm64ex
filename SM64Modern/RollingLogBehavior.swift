import Foundation

enum SM64RollingLogVariant: UInt8, Equatable, Sendable {
    case ttm
    case lll
}

struct SM64RollingLogInput: Equatable, Sendable {
    let variant: SM64RollingLogVariant
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let angleVelocityPitch: Int32
    let facePitch: Int32
    let marioIsPlatform: Bool
    let marioPosition: SM64ObjectVector3
    let nearHome: Bool
}

struct SM64RollingLogOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let moveYaw: Int32
    let angleVelocityPitch: Int32
    let facePitch: Int32
    let hitBoundary: Bool
    let playRollSound: Bool
}

/// Value counterpart of `bhv_ttm_rolling_log_loop` and `bhv_lll_rolling_log_loop`.
enum SM64RollingLogBehavior {
    static func update(_ input: SM64RollingLogInput) -> SM64RollingLogOutput {
        var angleVelocity = input.angleVelocityPitch
        if input.marioIsPlatform {
            let yaw = Int16(truncatingIfNeeded: input.moveYaw)
            let deltaX = input.marioPosition.x - input.position.x
            let deltaZ = input.marioPosition.z - input.position.z
            let sp24 = deltaZ * SM64CanonicalTrig.coss(-yaw) - deltaX * SM64CanonicalTrig.sins(-yaw)
            angleVelocity = sp24 > 0 ? min(angleVelocity &+ 0x10, 0x200) : max(angleVelocity &- 0x10, -0x200)
        } else if input.nearHome {
            if angleVelocity != 0 {
                angleVelocity = angleVelocity > 0 ? angleVelocity &- 0x10 : angleVelocity &+ 0x10
                if angleVelocity < 0x10 && angleVelocity > -0x10 { angleVelocity = 0 }
            }
        } else if angleVelocity != 0x100 {
            angleVelocity = angleVelocity > 0x100 ? angleVelocity &- 0x10 : angleVelocity &+ 0x10
            if angleVelocity < 0x110 && angleVelocity > 0xF0 { angleVelocity = 0x100 }
        }

        let forwardVelocity = Float(angleVelocity) / 0x40
        let yaw = Int16(truncatingIfNeeded: input.moveYaw)
        let velocity = SM64ObjectVector3(
            x: forwardVelocity * SM64CanonicalTrig.sins(yaw),
            y: 0,
            z: forwardVelocity * SM64CanonicalTrig.coss(yaw)
        )
        let previousPosition = input.position
        var position = SM64ObjectVector3(
            x: input.position.x + velocity.x,
            y: input.position.y,
            z: input.position.z + velocity.z
        )
        let boundX: Float = input.variant == .ttm ? 3_970 : 5_120
        let boundZ: Float = input.variant == .ttm ? 3_654 : 6_016
        let radiusSquared: Float = input.variant == .ttm ? 271_037 : 1_048_576
        let dx = position.x - boundX
        let dz = position.z - boundZ
        let hitBoundary = radiusSquared < dx * dx + dz * dz
        var finalVelocity = velocity
        var finalForwardVelocity = forwardVelocity
        if hitBoundary {
            position = previousPosition
            finalVelocity = .zero
            finalForwardVelocity = 0
        }

        let nextFacePitch = input.facePitch &+ angleVelocity
        let pitchResidue = nextFacePitch & 0x1FFF
        let playRollSound = abs(pitchResidue) < 528 && angleVelocity != 0
        return .init(
            position: position,
            velocity: finalVelocity,
            forwardVelocity: finalForwardVelocity,
            moveYaw: input.moveYaw,
            angleVelocityPitch: angleVelocity,
            facePitch: nextFacePitch,
            hitBoundary: hitBoundary,
            playRollSound: playRollSound
        )
    }
}
