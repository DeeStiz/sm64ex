import Foundation

struct SM64LllRotatingHexFlameInput: Equatable, Sendable {
    let parentPosition: SM64ObjectVector3
    let parentMoveYaw: Int16
    let parentAction: Int32
    let leftOffset: Float
    let forwardOffset: Float
    let previousPosition: SM64ObjectVector3
}

struct SM64LllRotatingHexFlameOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_lll_rotating_hex_flame_loop`.
enum SM64LllRotatingHexFlameBehavior {
    static func update(_ input: SM64LllRotatingHexFlameInput)
        -> SM64LllRotatingHexFlameOutput
    {
        let yaw = input.parentMoveYaw
        let dx = SM64DeterministicPrimitives.cFloatMultiply(
            input.forwardOffset, SM64CanonicalTrig.sins(yaw)
        ) + SM64DeterministicPrimitives.cFloatMultiply(
            input.leftOffset, SM64CanonicalTrig.coss(yaw)
        )
        let dz = SM64DeterministicPrimitives.cFloatMultiply(
            input.forwardOffset, SM64CanonicalTrig.coss(yaw)
        ) - SM64DeterministicPrimitives.cFloatMultiply(
            input.leftOffset, SM64CanonicalTrig.sins(yaw)
        )
        let position = SM64ObjectVector3(
            x: input.parentPosition.x + dx,
            y: input.parentPosition.y + 100,
            z: input.parentPosition.z + dz
        )
        return SM64LllRotatingHexFlameOutput(
            position: position,
            velocity: SM64ObjectVector3(
                x: position.x - input.previousPosition.x,
                y: position.y - input.previousPosition.y,
                z: position.z - input.previousPosition.z
            ),
            shouldDelete: input.parentAction == 3
        )
    }
}
