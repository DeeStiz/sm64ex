import Foundation

struct SM64BlackSmokeMarioInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let marioPosition: SM64ObjectVector3
    let marioYaw: Int32
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let timer: Int32
    let initialMoveYaw: Int32
    let initialForwardVelocity: Float
    let initialVelocityY: Float
    let angleVelocityYaw: Int32
}

struct SM64BlackSmokeMarioOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let shouldDeactivate: Bool
}

enum SM64BlackSmokeMarioBehavior {
    static func update(_ input: SM64BlackSmokeMarioInput) -> SM64BlackSmokeMarioOutput {
        var position = input.position
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        if input.timer == 0 {
            let marioYaw = Int16(truncatingIfNeeded: input.marioYaw)
            position.x = input.marioPosition.x - 30 * SM64CanonicalTrig.sins(marioYaw)
            position.y = input.marioPosition.y
            position.z = input.marioPosition.z - 30 * SM64CanonicalTrig.coss(marioYaw)
            moveYaw = input.initialMoveYaw
            forwardVelocity = input.initialForwardVelocity
            velocityY = input.initialVelocityY
        }
        moveYaw &+= input.angleVelocityYaw
        position.x += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        position.z += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        position.y += velocityY
        return SM64BlackSmokeMarioOutput(position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, shouldDeactivate: input.timer >= 23)
    }
}

struct SM64FlameMarioInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let marioYaw: Int32
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
}

struct SM64FlameMarioOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scale: Float
    let spawnSmoke: Bool
    let clearParticleFlag: Bool
    let shouldDelete: Bool
}

enum SM64FlameMarioBehavior {
    static func update(_ input: SM64FlameMarioInput) -> SM64FlameMarioOutput {
        let yaw = Int16(truncatingIfNeeded: input.marioYaw)
        let position = SM64ObjectVector3(
            x: input.marioPosition.x - 40 * SM64CanonicalTrig.sins(yaw),
            y: input.marioPosition.y - 120,
            z: input.marioPosition.z + 40 * SM64CanonicalTrig.coss(yaw)
        )
        let active = input.activeParticleFlags & input.particleFlag != 0
        return SM64FlameMarioOutput(position: position, scale: 2, spawnSmoke: active && input.timer != 0 && input.timer & 1 != 0, clearParticleFlag: !active, shouldDelete: !active)
    }
}
