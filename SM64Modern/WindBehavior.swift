import Foundation

struct SM64WindInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let facePitch: Int32
    let faceYaw: Int32
    let timer: Int32
    let initialRandomX: Float
    let initialRandomY: Float
    let initialRandomZ: Float
    let initialYawJitter: Int32
    let initialForwardVelocity: Float
    let initialVelocityY: Float
    let initialRandomYaw: Int32
    let facePitchJitter: Float
    let faceYawJitter: Float
}

struct SM64WindOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let facePitch: Int32
    let faceYaw: Int32
    let opacity: Int32
    let scale: Float
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_wind_loop`.
enum SM64WindBehavior {
    static func update(_ input: SM64WindInput) -> SM64WindOutput {
        var position = input.position
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var opacity: Int32 = 0
        if input.timer == 0 {
            opacity = 100
            if input.movePitch == 0 {
                position.x += input.initialRandomX
                    + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw &+ 0x8000)) * 500
                position.y += 80 + input.initialRandomY
                position.z += input.initialRandomZ
                    + SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw &+ 0x8000)) * 500
                moveYaw &+= input.initialYawJitter
                forwardVelocity = input.initialForwardVelocity
            } else {
                position.x += input.initialRandomX
                position.y -= 300
                position.z += input.initialRandomZ
                velocityY = input.initialVelocityY
                moveYaw = input.initialRandomYaw
                forwardVelocity = 10
            }
        } else {
            opacity = 100
        }
        let facePitch = input.facePitch
            &+ Int32(4000 + 2000 * input.facePitchJitter)
        let faceYaw = input.faceYaw
            &+ Int32(4000 + 2000 * input.faceYawJitter)
        position.x += SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        )
        position.z += SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        )
        position.y += velocityY
        return SM64WindOutput(
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            facePitch: facePitch,
            faceYaw: faceYaw,
            opacity: opacity,
            scale: 1,
            shouldDelete: input.timer > 8
        )
    }
}
