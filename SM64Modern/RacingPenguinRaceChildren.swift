import Foundation

enum SM64RacingPenguinRaceChildKind: UInt8, Equatable, Sendable {
    case finishLine = 0
    case shortcutCheck = 1
}

struct SM64RacingPenguinRaceChildInput: Equatable, Sendable {
    let kind: SM64RacingPenguinRaceChildKind
    let parentReachedBottom: Bool
    let distanceToMario: Float
    let marioDeltaZ: Float
}

struct SM64RacingPenguinRaceChildOutput: Equatable, Sendable {
    let marioWon: Bool
    let marioCheated: Bool
}

/// Value counterpart of the two child callbacks attached by
/// `bhv_racing_penguin_update`.
///
/// The child objects never retain a parent pointer in Swift. The owner bridge
/// supplies the parent's accumulated state and the copied distance/position
/// facts for this tick, then applies the two resulting mutations to the
/// parent's owner-thread record.
enum SM64RacingPenguinRaceChildren {
    static func update(_ input: SM64RacingPenguinRaceChildInput)
        -> SM64RacingPenguinRaceChildOutput
    {
        switch input.kind {
        case .finishLine:
            let crossed = input.distanceToMario < 1_000 && input.marioDeltaZ < 0
            return SM64RacingPenguinRaceChildOutput(
                marioWon: !input.parentReachedBottom && crossed,
                marioCheated: false
            )
        case .shortcutCheck:
            return SM64RacingPenguinRaceChildOutput(
                marioWon: false,
                marioCheated: input.distanceToMario < 500
            )
        }
    }
}
