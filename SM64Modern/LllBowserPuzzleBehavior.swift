import Foundation

struct SM64LllBowserPuzzlePieceInput: Equatable, Sendable {
    let action: Int32
    let previousAction: Int32
    let timer: Int32
    let homePosition: SM64ObjectVector3
    let offset: SM64ObjectVector3
    let continuePerformingAction: Bool
    let nextActionIndex: Int32
    let actionList: [Int32]
    let marioStanding: Bool
    let parentCompletionFlags: Int32
}

struct SM64LllBowserPuzzlePieceOutput: Equatable, Sendable {
    let action: Int32
    let previousAction: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let offset: SM64ObjectVector3
    let continuePerformingAction: Bool
    let nextActionIndex: Int32
    let parentCompletionFlags: Int32
    let playedMoveSound: Bool
}

struct SM64LllBowserPuzzleInput: Equatable, Sendable {
    let action: Int32
    let previousAction: Int32
    let timer: Int32
    let completionFlags: Int32
    let distanceToMario: Float
}

struct SM64LllBowserPuzzleOutput: Equatable, Sendable {
    let action: Int32
    let previousAction: Int32
    let timer: Int32
    let completionFlags: Int32
    let spawnPieces: Bool
    let spawnCoins: Bool
}

/// Value counterparts of `bhv_lll_bowser_puzzle_loop` and
/// `bhv_lll_bowser_puzzle_piece_loop`.
///
/// The piece action lists intentionally use the same signed sentinel and
/// indices as the C arrays. The owner bridge retains the list/index as state;
/// no C pointer crosses the Swift boundary.
enum SM64LllBowserPuzzleBehavior {
    static let actionIdle: Int32 = 2
    static let actionMoveLeft: Int32 = 3
    static let actionMoveRight: Int32 = 4
    static let actionMoveUp: Int32 = 5
    static let actionMoveDown: Int32 = 6

    static let actionSpawnPieces: Int32 = 0
    static let actionWaitForComplete: Int32 = 1
    static let actionDone: Int32 = 2
    static let completionMarioStanding: Int32 = 1
    static let completionActionListWrapped: Int32 = 2

    /// The first piece starts in action 1, but the native update immediately
    /// consumes the first action-list entry. The other pieces start in action
    /// 0, which is also replaced before their action body runs.
    static let pieceInitialActions: [Int32] = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    /// `bhv_lll_bowser_puzzle_spawn_piece` uses a 480-unit board width. The C
    /// offsets are signed tenths of that width, so each table unit is 48.
    static let pieceWidth: Float = 480
    static let pieceModels: [UInt32] = (0..<14).map { 0x43 + UInt32($0) }
    static let pieceOffsets: [(x: Int32, z: Int32)] = [
        (-5, -15), (5, -15), (-15, -5), (-5, -5), (5, -5), (15, -5),
        (-15, 5), (-5, 5), (5, 5), (15, 5), (-15, 15), (-5, 15),
        (5, 15), (15, 15),
    ]

    /// The C source has fourteen 27-entry arrays (26 actions plus -1), in
    /// piece-number order 1 through 14. Do not reorder these by movement
    /// order: `sBowserPuzzlePieces` indexes this table in source order.
    static let pieceActionLists: [[Int32]] = [
        list([1: 3, 24: 4]),
        list([2: 3, 23: 4]),
        list([11: 6, 14: 5]),
        list([12: 3, 13: 4]),
        list([3: 5, 22: 6]),
        list([4: 3, 21: 4]),
        list([10: 4, 15: 3]),
        list([9: 6, 16: 5]),
        list([6: 4, 19: 3]),
        list([5: 5, 20: 6]),
        list([0: 2, 25: 2]),
        list([8: 4, 17: 3]),
        list([7: 5, 18: 6]),
        list([0: 2, 25: 2]),
    ]

    private static func list(_ overrides: [Int: Int32]) -> [Int32] {
        var actions = Array(repeating: actionIdle, count: 26)
        for (index, action) in overrides where actions.indices.contains(index) {
            actions[index] = action
        }
        actions.append(-1)
        return actions
    }

    static func updatePiece(_ input: SM64LllBowserPuzzlePieceInput) -> SM64LllBowserPuzzlePieceOutput {
        var action = input.action
        var previousAction = input.previousAction
        var timer = input.timer
        var offset = input.offset
        var continuePerformingAction = input.continuePerformingAction
        var nextActionIndex = input.nextActionIndex
        var completionFlags = input.parentCompletionFlags
        var playedMoveSound = false

        // `cur_obj_update` performs this boundary reset before the native
        // body, while `cur_obj_change_action` below resets it immediately.
        if action != previousAction {
            timer = 0
            previousAction = action
        }

        // C assigns (rather than ORs) this flag when Mario is standing on a
        // piece. The end-of-list flag is then ORed below in the same update.
        if input.marioStanding {
            completionFlags = 1
        }

        if !continuePerformingAction {
            let index = max(0, Int(nextActionIndex))
            let selectedAction = input.actionList.indices.contains(index) ? input.actionList[index] : -1
            action = selectedAction == -1 ? actionIdle : selectedAction
            nextActionIndex = Int32(index + 1)
            if input.actionList.indices.contains(index + 1), input.actionList[index + 1] == -1 {
                completionFlags |= 2
                nextActionIndex = 0
            }
            continuePerformingAction = true
            timer = 0
            previousAction = action
        }

        switch action {
        case 1:
            // The C body adds to oPosY, then the common home+offset write
            // below replaces it. Keeping offsetY unchanged is intentional.
            action = actionMoveLeft
        case actionIdle:
            if timer >= 24 {
                continuePerformingAction = false
            }
        case actionMoveLeft, actionMoveRight, actionMoveUp, actionMoveDown:
            if timer < 20 {
                offset.y = timer % 2 == 0 ? -6 : 0
            } else {
                if timer == 20 {
                    playedMoveSound = true
                }
                if timer < 24 {
                    switch action {
                    case actionMoveLeft: offset.x -= 120
                    case actionMoveRight: offset.x += 120
                    case actionMoveUp: offset.z -= 120
                    case actionMoveDown: offset.z += 120
                    default: break
                    }
                } else {
                    // This direct assignment does not reset oTimer until
                    // cur_obj_update's post-native action check.
                    action = actionIdle
                    continuePerformingAction = false
                }
            }
        default:
            break
        }

        if timer < 0x3FFF_FFFF {
            timer += 1
        }
        if action != previousAction {
            timer = 0
            previousAction = action
        }

        let position = SM64ObjectVector3(
            x: input.homePosition.x + offset.x,
            y: input.homePosition.y + offset.y,
            z: input.homePosition.z + offset.z
        )
        return .init(
            action: action,
            previousAction: previousAction,
            timer: timer,
            position: position,
            offset: offset,
            continuePerformingAction: continuePerformingAction,
            nextActionIndex: nextActionIndex,
            parentCompletionFlags: completionFlags,
            playedMoveSound: playedMoveSound
        )
    }

    static func updatePuzzle(_ input: SM64LllBowserPuzzleInput) -> SM64LllBowserPuzzleOutput {
        var action = input.action
        var previousAction = input.previousAction
        var timer = input.timer
        var completionFlags = input.completionFlags
        var spawnPieces = false
        var spawnCoins = false

        if action != previousAction {
            timer = 0
            previousAction = action
        }

        switch action {
        case 0:
            spawnPieces = true
            action = 1
        case 1 where completionFlags == 3 && input.distanceToMario < 1_000:
            spawnCoins = true
            completionFlags = 0
            action = 2
        default:
            break
        }

        if timer < 0x3FFF_FFFF {
            timer += 1
        }
        if action != previousAction {
            timer = 0
            previousAction = action
        }

        return .init(
            action: action,
            previousAction: previousAction,
            timer: timer,
            completionFlags: completionFlags,
            spawnPieces: spawnPieces,
            spawnCoins: spawnCoins
        )
    }
}
