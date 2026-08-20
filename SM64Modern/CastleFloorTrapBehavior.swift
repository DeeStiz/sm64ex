import Foundation

enum SM64CastleFloorTrapRole: UInt8, Equatable, Sendable { case parent = 0; case child = 1 }
struct SM64CastleFloorTrapInput: Equatable, Sendable { let role: SM64CastleFloorTrapRole; let action: Int32; let timer: Int32; let roll: Int32; let angleVelocity: Int32; let interactTurn: Bool; let marioActionExit: Bool; let marioOnPlatform: Bool; let marioDistance: Float; let parentRoll: Int32 }
struct SM64CastleFloorTrapOutput: Equatable, Sendable { let role: SM64CastleFloorTrapRole; let action: Int32; let timer: Int32; let roll: Int32; let angleVelocity: Int32; let playOpenSound: Bool; let parentTurn: Bool; let clearTurn: Bool; let loadCollisionModel: Bool }

enum SM64CastleFloorTrapBehavior {
    static func update(_ input: SM64CastleFloorTrapInput) -> SM64CastleFloorTrapOutput {
        if input.role == .child { return .init(role: .child, action: input.action, timer: input.timer &+ 1, roll: input.parentRoll, angleVelocity: input.angleVelocity, playOpenSound: false, parentTurn: input.marioOnPlatform, clearTurn: false, loadCollisionModel: true) }
        var action = input.action; var roll = input.roll; var velocity = input.angleVelocity; var sound = false; var clear = false
        switch input.action {
        case 0:
            if input.marioActionExit { action = 4 } else { velocity = 0x400; if input.interactTurn { action = 1 } }
        case 1:
            if input.timer == 0 { sound = true }; velocity -= 0x100; roll += velocity; if roll < -0x4000 { roll = -0x4000; action = 2 }
        case 2: if input.marioDistance > 1000 { action = 3 }
        case 3: roll += 0x400; if roll > 0 { roll = 0; action = 0; clear = true }
        case 4: roll = -0x3C00
        default: action = 0; roll = 0
        }
        return .init(role: .parent, action: action, timer: input.timer &+ 1, roll: roll, angleVelocity: velocity, playOpenSound: sound, parentTurn: false, clearTurn: clear, loadCollisionModel: false)
    }
}
