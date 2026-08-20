import Foundation

struct SM64PushableMetalBoxInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let marioCollided: Bool
    let marioFlags: UInt32
    let boxToMarioYaw: Int32
    let marioMoveYaw: Int32
    let floorDeltaAhead: Float
}

struct SM64PushableMetalBoxOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let hitboxRadius: Float
    let hitboxHeight: Float
    let pushed: Bool
}

/// Value counterpart of `bhv_pushable_loop`.
enum SM64PushableMetalBoxBehavior {
    static let pushFlag: UInt32 = 0x8000_0000

    static func update(_ input: SM64PushableMetalBoxInput)
        -> SM64PushableMetalBoxOutput
    {
        var moveYaw = input.moveYaw
        var forwardVelocity: Float = 0
        var pushed = false

        if input.marioCollided,
           input.marioFlags & Self.pushFlag != 0,
           SM64Angle.absDifference(input.boxToMarioYaw, input.marioMoveYaw) > 0x4000
        {
            moveYaw = (input.marioMoveYaw &+ 0x2000) & 0xC000
            if abs(input.floorDeltaAhead) < 8 {
                forwardVelocity = 4
                pushed = true
            }
        }

        var position = input.position
        let velocityY = input.velocityY + input.gravity
        position.x += forwardVelocity * SM64CanonicalTrig.sins(
            Int16(truncatingIfNeeded: moveYaw)
        )
        position.y += velocityY
        position.z += forwardVelocity * SM64CanonicalTrig.coss(
            Int16(truncatingIfNeeded: moveYaw)
        )

        return .init(
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            hitboxRadius: 220,
            hitboxHeight: 300,
            pushed: pushed
        )
    }
}

private enum SM64Angle {
    static func absDifference(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        let difference = Int32(Int16(truncatingIfNeeded: lhs &- rhs))
        return abs(difference)
    }
}
