import Foundation

struct SM64GrandStarInput: Equatable, Sendable { let action: Int32; let timer: Int32; let subAction: Int32; let position: SM64ObjectVector3; let homeY: Float; let velocityY: Float; let forwardVelocity: Float; let yaw: Int32; let angleVelocityYaw: Int32; let interacted: Bool }
struct SM64GrandStarOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let subAction: Int32; let position: SM64ObjectVector3; let velocityY: Float; let forwardVelocity: Float; let yaw: Int32; let angleVelocityYaw: Int32; let tangible: Bool; let shouldDelete: Bool; let spawnSparkles: Bool; let playAppearsSound: Bool; let playGrandSound: Bool; let playJumpSound: Bool }
enum SM64GrandStarBehavior {
    static func update(_ input: SM64GrandStarInput) -> SM64GrandStarOutput {
        var action = input.action; var timer = input.timer &+ 1; var sub = input.subAction; var position = input.position; var velocityY = input.velocityY; var forward = input.forwardVelocity; var yaw = input.yaw; var angular = input.angleVelocityYaw; var tangible = false; var deleteStar = false; var sparkles = false; var appears = false; var grand = false; var jump = false
        if input.action == 0 { if input.timer == 0 { angular = 0x400; appears = true }; if input.timer > 70 { action = 1; timer = 0 }; sparkles = true }
        else if input.action == 1 { if input.timer == 0 { grand = true }; position.y += velocityY; velocityY -= 2; if sub == 0 && position.y < input.homeY { position.y = input.homeY; velocityY = 60; forward = 0; sub = 1; jump = true }; if sub != 0 && velocityY < 0 && position.y < input.homeY + 200 { position.y = input.homeY + 200; velocityY = 0; forward = 0; action = 2; timer = 0 }; sparkles = true }
        else { tangible = true; if input.interacted { deleteStar = true } }
        yaw &+= angular
        return .init(action: action, timer: timer, subAction: sub, position: position, velocityY: velocityY, forwardVelocity: forward, yaw: yaw, angleVelocityYaw: angular, tangible: tangible, shouldDelete: deleteStar, spawnSparkles: sparkles, playAppearsSound: appears, playGrandSound: grand, playJumpSound: jump)
    }
}
