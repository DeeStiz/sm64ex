import Foundation

struct SM64LllRotatingHexagonalRingInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let marioOnPlatform: Bool
    let moveYaw: Int32
}

struct SM64LllRotatingHexagonalRingOutput: Equatable, Sendable {
    let action: Int32
    let moveYaw: Int32
    let angleVelocityYaw: Int32
    let spawnVolcanoFlame: Bool
}

/// Value counterpart of `bhv_lll_rotating_hexagonal_ring_loop`.
enum SM64LllRotatingHexagonalRingBehavior {
    static func update(_ input: SM64LllRotatingHexagonalRingInput)
        -> SM64LllRotatingHexagonalRingOutput
    {
        var action = input.action
        var angleVelocity: Int32 = 0
        var spawnFlame = false
        switch input.action {
        case 0:
            if input.marioOnPlatform { action = 1 }
            angleVelocity = 0x100
        case 1:
            let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.timer &* 0x80))
            angleVelocity = Int32(256 - sine * 256)
            if input.timer > 128 { action = 2 }
        case 2:
            if !input.marioOnPlatform { action = 3 }
            if input.timer > 128 { action = 4 }
            spawnFlame = true
        case 3:
            let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.timer &* 0x80))
            angleVelocity = Int32(sine * 256)
            if input.timer > 128 { action = 0 }
        case 4:
            action = 0
        default:
            action = 0
        }
        angleVelocity = -angleVelocity
        return SM64LllRotatingHexagonalRingOutput(
            action: action,
            moveYaw: input.moveYaw &+ angleVelocity,
            angleVelocityYaw: angleVelocity,
            spawnVolcanoFlame: spawnFlame
        )
    }
}
