import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashI32(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU32(initial, UInt32(bitPattern: value))
}

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashBool(_ initial: UInt64, _ value: Bool) -> UInt64 {
    hashU32(initial, value ? 1 : 0)
}

private func hashPieceOutput(
    _ initial: UInt64,
    _ output: SM64LllBowserPuzzlePieceOutput
) -> UInt64 {
    var hash = initial
    hash = hashI32(hash, output.action)
    hash = hashI32(hash, output.previousAction)
    hash = hashI32(hash, output.timer)
    hash = hashF32(hash, output.position.x)
    hash = hashF32(hash, output.position.y)
    hash = hashF32(hash, output.position.z)
    hash = hashF32(hash, output.offset.x)
    hash = hashF32(hash, output.offset.y)
    hash = hashF32(hash, output.offset.z)
    hash = hashBool(hash, output.continuePerformingAction)
    hash = hashI32(hash, output.nextActionIndex)
    hash = hashI32(hash, output.parentCompletionFlags)
    return hashBool(hash, output.playedMoveSound)
}

private func hashPuzzleOutput(
    _ initial: UInt64,
    _ output: SM64LllBowserPuzzleOutput
) -> UInt64 {
    var hash = initial
    hash = hashI32(hash, output.action)
    hash = hashI32(hash, output.previousAction)
    hash = hashI32(hash, output.timer)
    hash = hashI32(hash, output.completionFlags)
    hash = hashBool(hash, output.spawnPieces)
    return hashBool(hash, output.spawnCoins)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernLllBowserPuzzleSmoke {
    static func main() throws {
        let behavior = SM64LllBowserPuzzleBehavior.self
        require(behavior.pieceActionLists.count == 14, "LLL Bowser puzzle piece count")
        require(behavior.pieceActionLists.allSatisfy { $0.count == 27 && $0.last == -1 },
                "LLL Bowser puzzle action-list sentinel")
        require(behavior.pieceActionLists[2][11] == behavior.actionMoveDown
                    && behavior.pieceActionLists[2][14] == behavior.actionMoveUp,
                "LLL Bowser puzzle piece 3 source table")
        require(behavior.pieceActionLists[6][10] == behavior.actionMoveRight
                    && behavior.pieceActionLists[6][15] == behavior.actionMoveLeft,
                "LLL Bowser puzzle piece 7 source table")

        let home = SM64ObjectVector3(x: 100, y: 200, z: 300)
        let pieceInitial = behavior.updatePiece(
            SM64LllBowserPuzzlePieceInput(
                action: 1,
                previousAction: 0,
                timer: 99,
                homePosition: home,
                offset: .zero,
                continuePerformingAction: false,
                nextActionIndex: 0,
                actionList: behavior.pieceActionLists[0],
                marioStanding: false,
                parentCompletionFlags: 0
            )
        )
        require(pieceInitial.action == behavior.actionIdle && pieceInitial.timer == 1,
                "LLL Bowser puzzle initial action")

        let pieceMove = behavior.updatePiece(
            SM64LllBowserPuzzlePieceInput(
                action: behavior.actionMoveLeft,
                previousAction: behavior.actionMoveLeft,
                timer: 20,
                homePosition: home,
                offset: .zero,
                continuePerformingAction: true,
                nextActionIndex: 2,
                actionList: behavior.pieceActionLists[0],
                marioStanding: false,
                parentCompletionFlags: 0
            )
        )
        require(pieceMove.offset == SM64ObjectVector3(x: -120, y: 0, z: 0)
                    && pieceMove.timer == 21 && pieceMove.playedMoveSound,
                "LLL Bowser puzzle movement boundary")

        let pieceFinished = behavior.updatePiece(
            SM64LllBowserPuzzlePieceInput(
                action: behavior.actionMoveLeft,
                previousAction: behavior.actionMoveLeft,
                timer: 24,
                homePosition: home,
                offset: SM64ObjectVector3(x: -480, y: 0, z: 0),
                continuePerformingAction: true,
                nextActionIndex: 2,
                actionList: behavior.pieceActionLists[0],
                marioStanding: false,
                parentCompletionFlags: 0
            )
        )
        require(pieceFinished.action == behavior.actionIdle && pieceFinished.timer == 0
                    && !pieceFinished.continuePerformingAction,
                "LLL Bowser puzzle movement completion")

        let pieceStanding = behavior.updatePiece(
            SM64LllBowserPuzzlePieceInput(
                action: behavior.actionIdle,
                previousAction: behavior.actionIdle,
                timer: 0,
                homePosition: home,
                offset: .zero,
                continuePerformingAction: true,
                nextActionIndex: 0,
                actionList: behavior.pieceActionLists[0],
                marioStanding: true,
                parentCompletionFlags: 0
            )
        )
        require(pieceStanding.parentCompletionFlags == behavior.completionMarioStanding,
                "LLL Bowser puzzle standing completion flag")

        let puzzleSpawn = behavior.updatePuzzle(
            SM64LllBowserPuzzleInput(
                action: behavior.actionSpawnPieces,
                previousAction: behavior.actionSpawnPieces,
                timer: 0,
                completionFlags: 0,
                distanceToMario: 10_000
            )
        )
        require(puzzleSpawn.spawnPieces && puzzleSpawn.action == behavior.actionWaitForComplete
                    && puzzleSpawn.timer == 0,
                "LLL Bowser puzzle spawn transition")

        let puzzleCoins = behavior.updatePuzzle(
            SM64LllBowserPuzzleInput(
                action: behavior.actionWaitForComplete,
                previousAction: behavior.actionWaitForComplete,
                timer: 7,
                completionFlags: 3,
                distanceToMario: 999.5
            )
        )
        require(puzzleCoins.spawnCoins && puzzleCoins.completionFlags == 0
                    && puzzleCoins.action == behavior.actionDone && puzzleCoins.timer == 0,
                "LLL Bowser puzzle coin transition")

        let engine = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64LllBowserPuzzleObjectBridge()
        let parentID = try bridge.spawnPuzzle(
            in: engine,
            position: SM64ObjectVector3(x: 1_000, y: 2_000, z: 3_000),
            distanceToMario: 999
        )
        bridge.beginExternalTick()
        guard let spawnEffect = bridge.updatePuzzleInline(parentID, state: engine) else {
            preconditionFailure("LLL Bowser puzzle owner spawn effect missing")
        }
        require(spawnEffect.spawnedChildren.count == 14, "LLL Bowser puzzle owner child count")
        require(bridge.pieceIDs(for: parentID) == spawnEffect.spawnedChildren,
                "LLL Bowser puzzle owner source order")
        for (sourceIndex, childID) in spawnEffect.spawnedChildren.enumerated() {
            guard let child = engine.objects.record(for: childID) else {
                preconditionFailure("LLL Bowser puzzle child record missing")
            }
            require(child.parent == parentID, "LLL Bowser puzzle child parent")
            require(child.model == behavior.pieceModels[sourceIndex],
                    "LLL Bowser puzzle child model source order")
            require(child.objectList == .surface, "LLL Bowser puzzle child list")
        }
        require(bridge.registeredIDs.count == 15, "LLL Bowser puzzle owner registration")
        guard let firstPiece = bridge.updatePieceInline(spawnEffect.spawnedChildren[0], state: engine) else {
            preconditionFailure("LLL Bowser puzzle first-piece owner effect missing")
        }
        require(firstPiece.pieceOutput?.action == behavior.actionIdle,
                "LLL Bowser puzzle first-piece owner action")
        bridge.pruneExternal(unloaded: [spawnEffect.spawnedChildren[0]], pool: engine.objects)
        require(!bridge.registeredIDs.contains(spawnEffect.spawnedChildren[0]),
                "LLL Bowser puzzle owner unload pruning")

        var fingerprint = fnvOffset
        fingerprint = hashU32(fingerprint, UInt32(behavior.pieceActionLists.count))
        for index in 0..<behavior.pieceActionLists.count {
            fingerprint = hashU32(fingerprint, UInt32(index))
            fingerprint = hashU32(fingerprint, behavior.pieceModels[index])
            fingerprint = hashI32(fingerprint, behavior.pieceInitialActions[index])
            fingerprint = hashI32(fingerprint, behavior.pieceOffsets[index].x)
            fingerprint = hashI32(fingerprint, behavior.pieceOffsets[index].z)
            fingerprint = hashU32(fingerprint, UInt32(behavior.pieceActionLists[index].count))
            for action in behavior.pieceActionLists[index] {
                fingerprint = hashI32(fingerprint, action)
            }
        }
        fingerprint = hashPieceOutput(fingerprint, pieceInitial)
        fingerprint = hashPieceOutput(fingerprint, pieceMove)
        fingerprint = hashPieceOutput(fingerprint, pieceFinished)
        fingerprint = hashPieceOutput(fingerprint, pieceStanding)
        fingerprint = hashPuzzleOutput(fingerprint, puzzleSpawn)
        fingerprint = hashPuzzleOutput(fingerprint, puzzleCoins)
        print(String(format: "lllBowserPuzzleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern LLL Bowser puzzle smoke passed")
    }
}
