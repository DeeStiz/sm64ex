import Foundation

enum SM64MarioVelocityDerivationFamily: UInt32, Equatable, Sendable {
    case yaw = 1
    case pitchYaw = 2
}

struct SM64MarioVelocityDerivationInput: Equatable, Sendable {
    let family: SM64MarioVelocityDerivationFamily
    let forwardVelocity: Float
    let facePitch: Int16
    let faceYaw: Int16
}

struct SM64MarioVelocityDerivationResult: Equatable, Sendable {
    let velocity: SM64ObjectVector3
    let slideVelocityX: Float
    let slideVelocityZ: Float
}

enum SM64MarioVelocityDerivation {
    static func update(_ input: SM64MarioVelocityDerivationInput) -> SM64MarioVelocityDerivationResult? {
        guard input.forwardVelocity.isFinite else { return nil }
        let x: Float
        let y: Float
        let z: Float
        switch input.family {
        case .yaw:
            x = input.forwardVelocity * SM64CanonicalTrig.sins(input.faceYaw)
            y = 0
            z = input.forwardVelocity * SM64CanonicalTrig.coss(input.faceYaw)
        case .pitchYaw:
            x = input.forwardVelocity * SM64CanonicalTrig.coss(input.facePitch)
                * SM64CanonicalTrig.sins(input.faceYaw)
            y = input.forwardVelocity * SM64CanonicalTrig.sins(input.facePitch)
            z = input.forwardVelocity * SM64CanonicalTrig.coss(input.facePitch)
                * SM64CanonicalTrig.coss(input.faceYaw)
        }
        return SM64MarioVelocityDerivationResult(
            velocity: SM64ObjectVector3(x: x, y: y, z: z),
            slideVelocityX: input.family == .yaw ? x : 0,
            slideVelocityZ: input.family == .yaw ? z : 0
        )
    }
}
