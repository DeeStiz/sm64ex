import Foundation

struct SM64HauntedBookshelfManagerInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let sequence: Int32
    let enabled: Bool
    let nearAndFacingMario: Bool
    let shelfPresent: Bool
    let shelfPositionX: Float
    let positionX: Float
    let inDifferentRoom: Bool
}

struct SM64HauntedBookshelfManagerOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let sequence: Int32
    let enabled: Bool
    let positionX: Float
    let spawnSwitches: Bool
    let openShelf: Bool
    let shouldDelete: Bool
}

/// Value counterpart of the haunted bookshelf manager's five action states.
enum SM64HauntedBookshelfManagerBehavior {
    static func update(_ input: SM64HauntedBookshelfManagerInput) -> SM64HauntedBookshelfManagerOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var sequence = input.sequence
        var enabled = input.enabled
        var positionX = input.positionX
        var spawnSwitches = false
        var openShelf = false
        var shouldDelete = false

        if input.inDifferentRoom {
            return .init(action: 4, timer: 0, sequence: sequence, enabled: enabled, positionX: positionX, spawnSwitches: false, openShelf: false, shouldDelete: sequence >= 3)
        }
        switch input.action {
        case 0:
            spawnSwitches = input.timer == 0
            action = 1
            timer = 0
        case 1:
            if !enabled && input.nearAndFacingMario { enabled = true }
            else if timer > 60 { action = 2; timer = 0; enabled = false }
        case 2:
            if sequence < 0 {
                if timer > 30 { sequence = 0; enabled = false; timer = 0 }
                else if timer > 10 { enabled = true }
            } else if sequence >= 3 {
                if timer > 100 && input.shelfPresent { openShelf = true; positionX = input.shelfPositionX; action = 3; timer = 0 }
            } else {
                timer = 0
            }
        case 3:
            if timer > 85 { action = 4; timer = 0 }
            else if input.shelfPresent { positionX = input.shelfPositionX }
        case 4:
            if sequence >= 3 { shouldDelete = true }
            else { action = 0; timer = 0 }
        default:
            action = 0
            timer = 0
        }
        return .init(action: action, timer: timer, sequence: sequence, enabled: enabled, positionX: positionX, spawnSwitches: spawnSwitches, openShelf: openShelf, shouldDelete: shouldDelete)
    }
}
