import Foundation

enum SM64BooKeyKind: UInt8, Equatable, Sendable { case alpha = 0; case beta = 1 }
struct SM64BooKeyInput: Equatable, Sendable { let kind: SM64BooKeyKind; let action: Int32; let timer: Int32; let roll: Int32; let yaw: Int32; let velocityY: Float; let graphYOffset: Float; let parentAlive: Bool; let collided: Bool; let landed: Bool }
struct SM64BooKeyOutput: Equatable, Sendable { let kind: SM64BooKeyKind; let action: Int32; let timer: Int32; let roll: Int32; let yaw: Int32; let velocityY: Float; let graphYOffset: Float; let tangible: Bool; let copyParent: Bool; let shouldDelete: Bool; let spawnSparkles: Bool; let parentDeath: Bool; let parentHoot: Bool }

enum SM64BooKeyBehavior {
    static func update(_ input: SM64BooKeyInput) -> SM64BooKeyOutput {
        if input.kind == .alpha {
            return .init(kind: .alpha, action: input.action, timer: input.timer &+ 1,
                         roll: input.roll &+ 0x200, yaw: input.yaw &+ 0x200,
                         velocityY: input.velocityY, graphYOffset: input.graphYOffset,
                         tangible: true, copyParent: false, shouldDelete: input.collided,
                         spawnSparkles: input.collided, parentDeath: input.collided, parentHoot: false)
        }
        var action = input.action; var timer = input.timer &+ 1; var roll = input.roll; var yaw = input.yaw; var velocity = input.velocityY; var graph = input.graphYOffset; var tangible = false; var copyParent = false; var deleteKey = false; var sparkles = false; var parentHoot = false
        switch input.action {
        case 0:
            if input.parentAlive { copyParent = true; roll &+= 0x200; yaw &+= 0x200 }
            else { action = 1; timer = 0; velocity = 40; roll &+= 0x200; yaw &+= 0x200 }
        case 1:
            roll &+= 0x200; yaw &+= 0x200
            if input.timer == 0 { velocity = 40 }
            if input.timer > 90 || input.landed { action = 2; timer = 0; tangible = true }
            if tangible && input.collided { deleteKey = true; sparkles = true; parentHoot = true }
        case 2:
            tangible = true; graph = min(26, input.graphYOffset + 2)
            if roll & 0xFFFF != 0 { roll = (roll & 0xF800) &+ 0x800 }
            yaw &+= 0x800
            if input.collided { deleteKey = true; sparkles = true; parentHoot = true }
        default: action = 0; timer = 0
        }
        return .init(kind: .beta, action: action, timer: timer, roll: roll, yaw: yaw, velocityY: velocity, graphYOffset: graph, tangible: tangible, copyParent: copyParent, shouldDelete: deleteKey, spawnSparkles: sparkles, parentDeath: false, parentHoot: parentHoot)
    }
}
