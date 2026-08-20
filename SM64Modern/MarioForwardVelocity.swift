import Foundation

struct SM64MarioForwardVelocityInput: Equatable, Sendable {
    let forwardVelocity: Float
    let faceYaw: Int16
}

struct SM64MarioForwardVelocityResult: Equatable, Sendable {
    let forwardVelocity: Float
    let slideVelocityX: Float
    let slideVelocityZ: Float
    let velocityX: Float
    let velocityZ: Float
}

enum SM64MarioForwardVelocity {
    static func update(_ input: SM64MarioForwardVelocityInput) -> SM64MarioForwardVelocityResult? {
        guard input.forwardVelocity.isFinite else { return nil }
        let x = SM64CanonicalTrig.sins(input.faceYaw) * input.forwardVelocity
        let z = SM64CanonicalTrig.coss(input.faceYaw) * input.forwardVelocity
        return SM64MarioForwardVelocityResult(
            forwardVelocity: input.forwardVelocity,
            slideVelocityX: x,
            slideVelocityZ: z,
            velocityX: x,
            velocityZ: z
        )
    }
}
