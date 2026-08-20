import Foundation

enum SM64MarioTerrainImpulseFamily: UInt32, Equatable, Sendable {
    case movingSand = 1
    case horizontalWind = 2
}

struct SM64MarioTerrainImpulseInput: Equatable, Sendable {
    let family: SM64MarioTerrainImpulseFamily
    let floorType: UInt32
    let force: Int16
    let movingAction: Bool
    let faceYaw: Int16
    let forwardVelocity: Float
    let globalTimer: UInt32
    let velocityX: Float
    let velocityZ: Float
}

struct SM64MarioTerrainImpulseResult: Equatable, Sendable {
    let velocityX: Float
    let velocityZ: Float
    let applied: Bool
    let soundKind: UInt32
}

/// Value counterpart of the moving-sand and horizontal-wind helpers. Surface
/// ownership and the JP wind sound remain explicit C effects.
enum SM64MarioTerrainImpulse {
    private static let deepMovingQuicksand: UInt32 = 0x0024
    private static let shallowMovingQuicksand: UInt32 = 0x0025
    private static let movingQuicksand: UInt32 = 0x0027
    private static let instantMovingQuicksand: UInt32 = 0x002D
    private static let horizontalWind: UInt32 = 0x002C
    private static let movingSandSpeeds: [Float] = [12, 8, 4, 0]

    static func update(_ input: SM64MarioTerrainImpulseInput) -> SM64MarioTerrainImpulseResult? {
        guard input.forwardVelocity.isFinite,
              input.velocityX.isFinite,
              input.velocityZ.isFinite else { return nil }

        var velocityX = input.velocityX
        var velocityZ = input.velocityZ
        var applied = false

        switch input.family {
        case .movingSand:
            let speedIndex = Int(input.force) >> 8
            guard speedIndex >= 0, speedIndex < movingSandSpeeds.count else { return nil }
            switch input.floorType {
            case deepMovingQuicksand, shallowMovingQuicksand,
                 movingQuicksand, instantMovingQuicksand:
                let pushAngle = Int16(truncatingIfNeeded: Int32(input.force) << 8)
                let speed = movingSandSpeeds[speedIndex]
                velocityX += speed * SM64CanonicalTrig.sins(pushAngle)
                velocityZ += speed * SM64CanonicalTrig.coss(pushAngle)
                applied = true
            default:
                break
            }

        case .horizontalWind:
            guard input.floorType == horizontalWind else {
                return SM64MarioTerrainImpulseResult(
                    velocityX: velocityX, velocityZ: velocityZ,
                    applied: false, soundKind: 0
                )
            }
            let pushAngle = Int16(truncatingIfNeeded: Int32(input.force) << 8)
            var pushSpeed: Float
            if input.movingAction {
                let pushDYaw = Int16(truncatingIfNeeded: Int32(input.faceYaw) - Int32(pushAngle))
                pushSpeed = input.forwardVelocity > 0 ? -input.forwardVelocity * 0.5 : -8
                if pushDYaw > -0x4000 && pushDYaw < 0x4000 { pushSpeed *= -1 }
                pushSpeed *= SM64CanonicalTrig.coss(pushDYaw)
            } else {
                pushSpeed = 3.2 + Float(input.globalTimer % 4)
            }
            velocityX += pushSpeed * SM64CanonicalTrig.sins(pushAngle)
            velocityZ += pushSpeed * SM64CanonicalTrig.coss(pushAngle)
            applied = true
        }

        return SM64MarioTerrainImpulseResult(
            velocityX: velocityX, velocityZ: velocityZ,
            applied: applied, soundKind: 0
        )
    }
}
