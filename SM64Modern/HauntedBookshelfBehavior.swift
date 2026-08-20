import Foundation

struct SM64HauntedBookshelfInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let shouldOpen: Bool
}

struct SM64HauntedBookshelfOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let playRecedeSound: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_haunted_bookshelf_loop`.
enum SM64HauntedBookshelfBehavior {
    static func update(_ input: SM64HauntedBookshelfInput) -> SM64HauntedBookshelfOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var playSound = false
        var shouldDelete = false
        if input.action == 0 {
            if input.shouldOpen { action = 1; timer = 0 }
        } else if input.action == 1 {
            position.x += 5
            playSound = true
            if input.timer > 101 { shouldDelete = true }
        }
        return .init(action: action, timer: timer, position: position, playRecedeSound: playSound, shouldDelete: shouldDelete)
    }
}
