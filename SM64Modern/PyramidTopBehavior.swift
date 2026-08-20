import Foundation

struct SM64PyramidTopInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let pillarsTouched: Int32
    let faceYaw: Int32
    let angleVelocityYaw: Int32
    let velocityY: Float
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
}

struct SM64PyramidTopOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int32
    let angleVelocityYaw: Int32
    let velocityY: Float
    let position: SM64ObjectVector3
    let spawnFragments: Int32
    let playPuzzleJingle: Bool
    let playSpinSound: Bool
    let spawnExplosionSound: Bool
    let deactivated: Bool
}

enum SM64PyramidTopBehavior {
    static func update(_ input: SM64PyramidTopInput) -> SM64PyramidTopOutput {
        var action = input.action
        var faceYaw = input.faceYaw
        var angleVelocityYaw = input.angleVelocityYaw
        var velocityY = input.velocityY
        var position = input.position
        var fragments: Int32 = 0
        var puzzleJingle = false
        var spinSound = false
        var explosionSound = false
        var deactivated = false
        if action == 0 {
            if input.pillarsTouched == 4 { action = 1; puzzleJingle = true }
        } else if action == 1 {
            if input.timer == 0 { spinSound = true }
            if input.timer < 90 { fragments = 1 }
            if input.timer >= 60 {
                angleVelocityYaw = min(angleVelocityYaw &+ 0x100, 0x1800)
                if angleVelocityYaw == 0x1800 { velocityY = 5 }
                faceYaw &+= angleVelocityYaw
                position.y += velocityY
            }
            if input.timer == 150 { action = 2 }
        } else if action == 2 {
            if input.timer == 0 { explosionSound = true; fragments = 30; deactivated = true }
        }
        return .init(action: action, timer: input.timer &+ 1, faceYaw: faceYaw, angleVelocityYaw: angleVelocityYaw, velocityY: velocityY, position: position, spawnFragments: fragments, playPuzzleJingle: puzzleJingle, playSpinSound: spinSound, spawnExplosionSound: explosionSound, deactivated: deactivated)
    }
}
