import Foundation

enum SM64MarioBonkSoundKind: UInt32, Equatable, Sendable {
    case hit = 0
    case bonk = 1
    case metalBonk = 2
}

struct SM64MarioBonkInput: Equatable, Sendable {
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocityX: Float
    let velocityZ: Float
    let wallAngle: Int16?
    let negateSpeed: Bool
    let metalCap: Bool
}

struct SM64MarioBonkResult: Equatable, Sendable {
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocityX: Float
    let velocityZ: Float
    let soundKind: SM64MarioBonkSoundKind
}

/// Value counterpart of `mario_bonk_reflection`; C retains the sound/device
/// leaf and Mario object graph while Swift owns the scalar reflection.
enum SM64MarioBonk {
    static func update(_ input: SM64MarioBonkInput) -> SM64MarioBonkResult? {
        guard input.forwardVelocity.isFinite,
              input.velocityX.isFinite,
              input.velocityZ.isFinite else { return nil }

        var faceYaw = input.faceYaw
        let soundKind: SM64MarioBonkSoundKind
        if let wallAngle = input.wallAngle {
            faceYaw = Int16(truncatingIfNeeded:
                Int32(wallAngle) - Int32(Int16(truncatingIfNeeded:
                    Int32(faceYaw) - Int32(wallAngle))))
            soundKind = input.metalCap ? .metalBonk : .bonk
        } else {
            soundKind = .hit
        }

        var forwardVelocity = input.forwardVelocity
        var velocityX = input.velocityX
        var velocityZ = input.velocityZ
        if input.negateSpeed {
            forwardVelocity = -forwardVelocity
            velocityX = SM64CanonicalTrig.sins(faceYaw) * forwardVelocity
            velocityZ = SM64CanonicalTrig.coss(faceYaw) * forwardVelocity
        } else {
            faceYaw = Int16(truncatingIfNeeded: Int32(faceYaw) + Int32(Int16(bitPattern: 0x8000)))
        }

        return SM64MarioBonkResult(
            faceYaw: faceYaw,
            forwardVelocity: forwardVelocity,
            velocityX: velocityX,
            velocityZ: velocityZ,
            soundKind: soundKind
        )
    }
}
