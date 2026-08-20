import Foundation

enum SM64WfTowerPlatformKind: UInt8, Equatable, Sendable {
    case elevator = 0
    case sliding = 1
}

struct SM64WfTowerPlatformInput: Equatable, Sendable {
    let kind: SM64WfTowerPlatformKind
    let action: Int32
    let timer: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let moveYaw: Int16
    let distance: Int32
    let speed: Float
    let marioOnPlatform: Bool
    let parentAction: Int32
}

struct SM64WfTowerPlatformOutput: Equatable, Sendable {
    let action: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let forwardVelocity: Float
    let velocityX: Float
    let velocityZ: Float
    let shouldDelete: Bool
    let playedSound: Bool
}

/// Value counterpart of the WF elevator/sliding tower child loops. Parent
/// deletion, Mario platform state, and wall/collision consumers are explicit
/// owner inputs; this reducer never follows a C object pointer.
enum SM64WfTowerPlatformBehavior {
    static func update(_ input: SM64WfTowerPlatformInput) -> SM64WfTowerPlatformOutput {
        switch input.kind {
        case .elevator:
            return updateElevator(input)
        case .sliding:
            return updateSliding(input)
        }
    }

    private static func updateElevator(_ input: SM64WfTowerPlatformInput)
        -> SM64WfTowerPlatformOutput
    {
        var action = input.action
        var positionY = input.positionY
        var playedSound = false
        switch input.action {
        case 0:
            if input.marioOnPlatform { action = 1 }
        case 1:
            playedSound = true
            if input.timer > 140 { action = 2 }
            else { positionY += 5 }
        case 2:
            if input.timer > 60 { action = 3 }
        case 3:
            playedSound = true
            if input.timer > 140 { action = 0 }
            else { positionY -= 5 }
        default:
            break
        }
        return SM64WfTowerPlatformOutput(
            action: action,
            positionX: input.positionX,
            positionY: positionY,
            positionZ: input.positionZ,
            forwardVelocity: 0,
            velocityX: 0,
            velocityZ: 0,
            shouldDelete: input.parentAction == 3,
            playedSound: playedSound
        )
    }

    private static func updateSliding(_ input: SM64WfTowerPlatformInput)
        -> SM64WfTowerPlatformOutput
    {
        var action = input.action
        let distancePerSpeed = input.speed == 0 ? 0 : input.distance / Int32(input.speed)
        let forwardVelocity: Float
        if input.action == 0 {
            if input.timer > distancePerSpeed { action = 1 }
            forwardVelocity = -input.speed
        } else {
            if input.timer > distancePerSpeed { action = 0 }
            forwardVelocity = input.speed
        }
        let velocityX = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.sins(input.moveYaw)
        )
        let velocityZ = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.coss(input.moveYaw)
        )
        return SM64WfTowerPlatformOutput(
            action: action,
            positionX: input.positionX + velocityX,
            positionY: input.positionY,
            positionZ: input.positionZ + velocityZ,
            forwardVelocity: forwardVelocity,
            velocityX: velocityX,
            velocityZ: velocityZ,
            shouldDelete: input.parentAction == 3,
            playedSound: false
        )
    }
}
