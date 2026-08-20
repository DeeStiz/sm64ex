import Foundation

struct SM64BooInCastleInput: Equatable, Sendable { let action: Int32; let timer: Int32; let stars: Int32; let room: Int32; let distanceToMario: Float; let positionZ: Float; let opacity: Int32; let forwardVelocity: Float; let activeDifferentRoom: Bool; let angleToMario: Int32; let angleToHome: Int32 }
struct SM64BooInCastleOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let visible: Bool; let opacity: Int32; let scale: Float; let forwardVelocity: Float; let targetAngle: Int32; let shouldDelete: Bool; let playLaugh: Bool; let velocityY: Float }
enum SM64BooInCastleBehavior {
    static func update(_ input: SM64BooInCastleInput) -> SM64BooInCastleOutput {
        var action = input.action; var visible = input.action != 0; var opacity = input.opacity; var scale: Float = 2; var velocity = input.forwardVelocity; var angle = input.angleToHome; var deleteBoo = false; var laugh = false
        if input.action == 0 { visible = false; if input.stars < 12 { deleteBoo = true }; if input.room == 1 { action = 1; visible = true } }
        else if input.action == 1 { visible = true; opacity = 180; if input.timer == 0 { scale = 2 }; if input.distanceToMario < 1000 { action = 2; laugh = true }; velocity = 0; angle = input.angleToMario }
        else { visible = true; velocity = min(32, input.forwardVelocity + 1); angle = input.angleToHome; if input.positionZ < -5000 { opacity = max(0, input.opacity - 20) }; if input.activeDifferentRoom { action = 1 } }
        return .init(action: action, timer: input.timer &+ 1, visible: visible, opacity: opacity, scale: scale, forwardVelocity: velocity, targetAngle: angle, shouldDelete: deleteBoo, playLaugh: laugh, velocityY: 0)
    }
}
