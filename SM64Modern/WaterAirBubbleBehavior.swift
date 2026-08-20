import Foundation

struct SM64WaterAirBubbleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let angleF4: Int32
    let timer: Int32
    let velocityY: Float
    let forwardVelocity: Float
    let moveYaw: Int32
    let marioPosition: SM64ObjectVector3
    let randomJitterX: Float
    let randomJitterZ: Float
    let waterLevel: Float
    let interacted: Bool
}

struct SM64WaterAirBubbleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scaleX: Float
    let scaleY: Float
    let angleF4: Int32
    let timer: Int32
    let velocityY: Float
    let forwardVelocity: Float
    let moveYaw: Int32
    let intangible: Bool
    let shouldDelete: Bool
    let spawnBubbleCount: Int32
    let playSound: Bool
}

/// Value counterpart of `bhv_water_air_bubble_loop`.
enum SM64WaterAirBubbleBehavior {
    static func update(_ input: SM64WaterAirBubbleInput) -> SM64WaterAirBubbleOutput {
        let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleF4))
        let scaleX = sine * 0.5 + 4
        let scaleY = -sine * 0.5 + 4
        var position = input.position
        let velocityY = input.velocityY
        var forwardVelocity = input.forwardVelocity
        var moveYaw = input.moveYaw
        let intangible = input.timer < 30
        if intangible {
            position.y += 3
        } else {
            forwardVelocity = forwardVelocity >= 2 ? 2 : forwardVelocity + 10
            let dx = input.marioPosition.x - position.x
            let dz = input.marioPosition.z - position.z
            let angle = atan2(Double(dz), Double(dx)) * 32768.0 / Double.pi
            moveYaw = Int32(Int16(truncatingIfNeeded: Int32(angle)))
            position.x += SM64DeterministicPrimitives.cFloatMultiply(
                forwardVelocity, SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
            )
            position.z += SM64DeterministicPrimitives.cFloatMultiply(
                forwardVelocity, SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
            )
            position.y += velocityY
        }
        position.x += input.randomJitterX
        position.z += input.randomJitterZ
        let shouldDelete = input.interacted || input.timer > 200 || position.y > input.waterLevel
        return SM64WaterAirBubbleOutput(
            position: position,
            scaleX: scaleX,
            scaleY: scaleY,
            angleF4: input.angleF4 &+ 0x400,
            timer: input.timer &+ 1,
            velocityY: velocityY,
            forwardVelocity: forwardVelocity,
            moveYaw: moveYaw,
            intangible: intangible,
            shouldDelete: shouldDelete,
            spawnBubbleCount: input.interacted || input.timer > 200 ? 30 : 0,
            playSound: input.interacted || input.timer > 200
        )
    }
}
