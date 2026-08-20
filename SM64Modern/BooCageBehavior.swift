import Foundation

struct SM64BooCageInput: Equatable, Sendable { let action: Int32; let timer: Int32; let position: SM64ObjectVector3; let velocityY: Float; let parentAlive: Bool; let parentPosition: SM64ObjectVector3; let parentYaw: Int32; let moveFlags: UInt32; let marioCollided: Bool }
struct SM64BooCageOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let position: SM64ObjectVector3; let velocityY: Float; let tangible: Bool; let parentCopied: Bool; let spawnSparkle: Bool; let playPuzzleJingle: Bool; let playLandingSound: Bool; let loadCollisionModel: Bool }
enum SM64BooCageBehavior {
    static func update(_ input: SM64BooCageInput) -> SM64BooCageOutput {
        var action = input.action; var timer = input.timer &+ 1; var position = input.position; var velocity = input.velocityY; var tangible = false; var copied = false; var sparkle = false; var jingle = false; var landing = false
        switch input.action {
        case 0:
            if input.parentAlive { position = input.parentPosition; copied = true } else { action = 1; timer = 0; velocity = 60; jingle = true }
        case 1:
            position.y += velocity; velocity -= 4; sparkle = true; landing = input.moveFlags & 1 != 0
            if input.moveFlags & (1 | 2 | 4) != 0 { action = 2; timer = 0 }
        case 2:
            tangible = true; if input.marioCollided { action = 3; timer = 0 }
        case 3: if input.timer > 100 { action = 4; timer = 0 }
        case 4: break
        default: action = 0; timer = 0
        }
        return .init(action: action, timer: timer, position: position, velocityY: velocity, tangible: tangible, parentCopied: copied, spawnSparkle: sparkle, playPuzzleJingle: jingle, playLandingSound: landing, loadCollisionModel: action >= 2)
    }
}
