import Foundation

enum SM64BowserFlameKind: UInt8, Equatable, Sendable {
    case normal = 0
    case largeBurningOut = 1
}

struct SM64BowserFlameInput: Equatable, Sendable {
    let kind: SM64BowserFlameKind
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let scaleFactor: Float
    let action: Int32
    let timer: Int32
    let animationState: Int32
    let phase: Int32
    let globalTimer: Int32
    let landingScale: Float
    let landed: Bool
    let floorHazard: Bool
}

struct SM64BowserFlameOutput: Equatable, Sendable {
    let kind: SM64BowserFlameKind
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let scaleFactor: Float
    let action: Int32
    let timer: Int32
    let animationState: Int32
    let shouldDelete: Bool
    let spawnSmoke: Bool
}

enum SM64BowserFlameBehavior {
    static func update(_ input: SM64BowserFlameInput) -> SM64BowserFlameOutput {
        var position = input.position
        var velocityY = input.velocityY
        var gravity = input.gravity
        var forwardVelocity = input.forwardVelocity
        var scaleFactor = input.scaleFactor
        var action = input.action
        var timer = input.timer
        var shouldDelete = input.floorHazard
        var spawnSmoke = false

        if action == 0 {
            position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            velocityY += gravity
            position.y += velocityY
            velocityY = max(velocityY, -4)
            let phase = Int16(truncatingIfNeeded: ((input.phase + input.globalTimer) & 0x3f) << 10)
            position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw)) * SM64CanonicalTrig.sins(phase) * 4
            position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw)) * SM64CanonicalTrig.sins(phase) * 4
            if input.landed {
                action = 1
                scaleFactor = input.landingScale
                forwardVelocity = 0
                velocityY = 0
                gravity = 0
                timer = 0
            } else {
                timer &+= 1
            }
        } else {
            if input.timer > Int32(scaleFactor * 10 + 5) {
                scaleFactor -= 0.15
                if scaleFactor <= 0 {
                    shouldDelete = true
                    spawnSmoke = true
                }
            }
            timer &+= 1
        }

        return SM64BowserFlameOutput(
            kind: input.kind,
            position: position,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            gravity: gravity,
            scaleFactor: scaleFactor,
            action: action,
            timer: timer,
            animationState: input.timer % 2 == 0 ? input.animationState &+ 1 : input.animationState,
            shouldDelete: shouldDelete,
            spawnSmoke: spawnSmoke
        )
    }
}
