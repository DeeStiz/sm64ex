import Foundation

enum SM64CloudKind: UInt8, Equatable, Sendable { case fwoosh = 0, lakitu = 1 }
enum SM64CloudAction: Int32, Equatable, Sendable { case spawnParts = 0, main = 1, unload = 2, fwooshHidden = 3 }
enum SM64CloudWindSound: Int32, Equatable, Sendable { case none = -1, environment = 0, blow = 1 }

struct SM64CloudInput: Equatable, Sendable {
    let kind: SM64CloudKind
    let action: SM64CloudAction
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let parentPosition: SM64ObjectVector3
    let parentActive: Bool
    let parentFaceYaw: Int32
    let distanceToMario: Float
    let scale: Float
    let movementRadius: Int32
    let globalFrame: UInt64
    let timer: Int32
    let blowing: Bool
    let growSpeed: Float
}

struct SM64CloudOutput: Equatable, Sendable {
    let action: SM64CloudAction
    let position: SM64ObjectVector3
    let centerX: Float
    let centerY: Float
    let faceYaw: Int32
    let scale: Float
    let movementRadius: Int32
    let childPartCount: Int32
    let shouldDelete: Bool
    let hidden: Bool
    let timer: Int32
    let blowing: Bool
    let growSpeed: Float
    let soundIntent: SM64CloudWindSound
    let spawnWindParticles: Bool
}

enum SM64CloudBehavior {
    private static func approach(_ value: Float, target: Float, delta: Float) -> Float {
        if value < target { return min(value + delta, target) }
        return max(value - delta, target)
    }

    static func update(_ input: SM64CloudInput) -> SM64CloudOutput {
        switch input.action {
        case .spawnParts:
            let scale = input.kind == .fwoosh ? max(input.scale, 3) : input.scale
            return .init(action: .main, position: input.position, centerX: input.position.x, centerY: input.position.y, faceYaw: input.parentFaceYaw, scale: scale, movementRadius: input.movementRadius, childPartCount: input.kind == .fwoosh ? 6 : 5, shouldDelete: false, hidden: false, timer: 0, blowing: false, growSpeed: 0, soundIntent: .none, spawnWindParticles: false)
        case .fwooshHidden:
            return input.distanceToMario < 2_000
                ? .init(action: .spawnParts, position: input.position, centerX: input.position.x, centerY: input.position.y, faceYaw: input.parentFaceYaw, scale: input.scale, movementRadius: input.movementRadius, childPartCount: 0, shouldDelete: false, hidden: false, timer: 0, blowing: false, growSpeed: 0, soundIntent: .none, spawnWindParticles: false)
                : .init(action: .fwooshHidden, position: input.homePosition, centerX: input.homePosition.x, centerY: input.homePosition.y, faceYaw: input.parentFaceYaw, scale: input.scale, movementRadius: input.movementRadius, childPartCount: 0, shouldDelete: false, hidden: true, timer: input.timer, blowing: false, growSpeed: 0, soundIntent: .none, spawnWindParticles: false)
        case .unload:
            if input.kind == .fwoosh { return .init(action: .fwooshHidden, position: input.homePosition, centerX: input.homePosition.x, centerY: input.homePosition.y, faceYaw: input.parentFaceYaw, scale: input.scale, movementRadius: input.movementRadius, childPartCount: 0, shouldDelete: false, hidden: true, timer: input.timer, blowing: false, growSpeed: 0, soundIntent: .none, spawnWindParticles: false) }
            return .init(action: .unload, position: input.position, centerX: input.position.x, centerY: input.position.y, faceYaw: input.parentFaceYaw, scale: input.scale, movementRadius: input.movementRadius, childPartCount: 0, shouldDelete: true, hidden: false, timer: input.timer, blowing: false, growSpeed: 0, soundIntent: .none, spawnWindParticles: false)
        case .main:
            if input.kind == .lakitu && !input.parentActive { return update(.init(kind: input.kind, action: .unload, position: input.position, homePosition: input.homePosition, parentPosition: input.parentPosition, parentActive: input.parentActive, parentFaceYaw: input.parentFaceYaw, distanceToMario: input.distanceToMario, scale: input.scale, movementRadius: input.movementRadius, globalFrame: input.globalFrame, timer: input.timer, blowing: input.blowing, growSpeed: input.growSpeed)) }
            if input.kind == .fwoosh && input.distanceToMario > 2_500 { return update(.init(kind: input.kind, action: .unload, position: input.position, homePosition: input.homePosition, parentPosition: input.parentPosition, parentActive: input.parentActive, parentFaceYaw: input.parentFaceYaw, distanceToMario: input.distanceToMario, scale: input.scale, movementRadius: input.movementRadius, globalFrame: input.globalFrame, timer: input.timer, blowing: input.blowing, growSpeed: input.growSpeed)) }
            var nextScale = input.scale
            var nextRadius = input.movementRadius
            var nextTimer = input.timer
            var nextBlowing = input.blowing
            var nextGrowSpeed = input.growSpeed
            var soundIntent: SM64CloudWindSound = .none
            var spawnWindParticles = false
            if input.kind == .fwoosh {
                if input.blowing {
                    nextScale += input.growSpeed
                    nextGrowSpeed -= 0.005
                    if nextGrowSpeed < -0.16 {
                        nextBlowing = false
                        nextTimer = 0
                        nextGrowSpeed = 0
                    } else if nextGrowSpeed < -0.1 {
                        soundIntent = .blow
                        spawnWindParticles = true
                    } else {
                        soundIntent = .environment
                    }
                } else {
                    nextScale = approach(input.scale, target: 3, delta: 0.012)
                    nextRadius = input.movementRadius &+ 0xC8
                    if input.distanceToMario < 1_000 {
                        if input.timer > 100 {
                            nextBlowing = true
                            nextGrowSpeed = 0.14
                        }
                    } else {
                        nextTimer = 0
                    }
                }
            }
            let centerX = input.kind == .fwoosh ? input.homePosition.x + 100 * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextRadius)) : input.parentPosition.x
            let centerY = input.kind == .fwoosh ? input.homePosition.y : input.parentPosition.y
            let baseZ = input.kind == .fwoosh ? input.homePosition.z + 100 * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextRadius)) : input.parentPosition.z
            let localOffset = 2 * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.globalFrame &* 0x800)) * nextScale
            return .init(action: .main, position: .init(x: centerX + localOffset, y: centerY + localOffset + 12 * nextScale, z: baseZ), centerX: centerX, centerY: centerY, faceYaw: input.parentFaceYaw, scale: nextScale, movementRadius: nextRadius, childPartCount: 0, shouldDelete: false, hidden: false, timer: nextTimer, blowing: nextBlowing, growSpeed: nextGrowSpeed, soundIntent: soundIntent, spawnWindParticles: spawnWindParticles)
        }
    }
}
