import Foundation

struct SM64TweesterSandParticleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let timer: Int32
    let initialRandomX: Float
    let initialRandomZ: Float
    let initialFacePitch: Int32
    let initialFaceYaw: Int32
    let randomScale: Float
}

struct SM64TweesterSandParticleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let facePitch: Int32
    let faceYaw: Int32
    let scale: Float
    let shouldDelete: Bool
}

enum SM64TweesterSandParticleBehavior {
    static func update(_ input: SM64TweesterSandParticleInput) -> SM64TweesterSandParticleOutput {
        var position = input.position
        let facePitch = input.initialFacePitch
        let faceYaw = input.initialFaceYaw
        if input.timer == 0 {
            position.x += input.initialRandomX
            position.z += input.initialRandomZ
        }
        position.y += 22
        return SM64TweesterSandParticleOutput(
            position: position,
            moveYaw: input.moveYaw &+ 0x3700,
            forwardVelocity: input.forwardVelocity + 15,
            facePitch: facePitch,
            faceYaw: faceYaw,
            scale: input.randomScale + 1,
            shouldDelete: input.timer > 15
        )
    }
}
