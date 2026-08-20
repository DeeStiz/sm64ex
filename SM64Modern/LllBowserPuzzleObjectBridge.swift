import Foundation

enum SM64LllBowserPuzzleObjectKind: UInt8, Equatable, Sendable {
    case puzzle = 0
    case piece = 1
}

/// One owner-thread receipt for either the LLL Bowser puzzle spawner or one
/// of its surface-list pieces. The copied behavior output is value-only;
/// object IDs are the only relationship that crosses the bridge.
struct SM64LllBowserPuzzleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64LllBowserPuzzleObjectKind
    let parentID: SM64ObjectID?
    let puzzleOutput: SM64LllBowserPuzzleOutput?
    let pieceOutput: SM64LllBowserPuzzlePieceOutput?
    let spawnedChildren: [SM64ObjectID]
    let spawnedCoins: [SM64ObjectID]
}

/// Owner-thread bridge for `bhvLllBowserPuzzle` and its fourteen
/// `bhvLllBowserPuzzlePiece` children. It retains the action-list/index state
/// that was pointer-based in C, while keeping parent/child identity as
/// generation-checked `SM64ObjectID` values.
final class SM64LllBowserPuzzleObjectBridge {
    static let puzzleBehaviorIdentity: UInt64 = 0x6268_765F_6C6270
    static let pieceBehaviorIdentity: UInt64 = 0x6268_765F_6C6271
    static let singleCoinGetsSpawnedBehaviorIdentity: UInt64 = 0x6268_765F_736367
    static let yellowCoinModel: UInt32 = 0x74
    static let defaultModel: UInt32 = 0

    private struct PieceState {
        let parentID: SM64ObjectID
        let sourceIndex: Int
        let actionList: [Int32]
        var nextActionIndex: Int32
        var continuePerformingAction: Bool
        var offset: SM64ObjectVector3
    }

    private var puzzleCompletionFlags: [SM64ObjectID: Int32] = [:]
    private var pieces: [SM64ObjectID: PieceState] = [:]
    private var spawnedCoins: [SM64ObjectID: [SM64ObjectID]] = [:]
    private(set) var effectLog: [SM64LllBowserPuzzleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        (Array(puzzleCompletionFlags.keys) + Array(pieces.keys)).sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func pieceIDs(for parentID: SM64ObjectID) -> [SM64ObjectID] {
        pieces.compactMap { id, state in
            state.parentID == parentID ? id : nil
        }.sorted {
            guard let lhs = pieces[$0], let rhs = pieces[$1] else { return false }
            if lhs.sourceIndex != rhs.sourceIndex { return lhs.sourceIndex < rhs.sourceIndex }
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func coinIDs(for parentID: SM64ObjectID) -> [SM64ObjectID] {
        spawnedCoins[parentID] ?? []
    }

    func completionFlags(for parentID: SM64ObjectID) -> Int32? {
        puzzleCompletionFlags[parentID]
    }

    /// Clears only receipts. Object-list traversal and lifecycle ownership
    /// remain with the enclosing engine owner thread.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnPuzzle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 19_000,
        model: UInt32 = SM64LllBowserPuzzleObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .spawner,
            model: model,
            behaviorIdentity: Self.puzzleBehaviorIdentity
        )
        guard attachPuzzle(
            id,
            position: position,
            distanceToMario: distanceToMario,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL Bowser puzzle could not attach")
        }
        return id
    }

    @discardableResult
    func attachPuzzle(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 19_000,
        action: Int32 = SM64LllBowserPuzzleBehavior.actionSpawnPieces,
        previousAction: Int32 = SM64LllBowserPuzzleBehavior.actionSpawnPieces,
        timer: Int32 = 0,
        completionFlags: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, position.x.isFinite, position.y.isFinite,
              position.z.isFinite, distanceToMario.isFinite else { return false }
        puzzleCompletionFlags[id] = completionFlags
        spawnedCoins.removeValue(forKey: id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.distanceToMario = distanceToMario
            record.action = action
            record.previousAction = previousAction
            record.timer = timer
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func spawnPiece(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        sourceIndex: Int,
        model: UInt32? = nil
    ) throws -> SM64ObjectID {
        guard SM64LllBowserPuzzleBehavior.pieceActionLists.indices.contains(sourceIndex),
              SM64LllBowserPuzzleBehavior.pieceModels.indices.contains(sourceIndex) else {
            throw SM64ObjectPoolError.invalidReference(parent)
        }
        let id = try engineState.spawnObject(
            in: .surface,
            model: model ?? SM64LllBowserPuzzleBehavior.pieceModels[sourceIndex],
            behaviorIdentity: Self.pieceBehaviorIdentity,
            parent: parent
        )
        guard attachPiece(id, parent: parent, sourceIndex: sourceIndex, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL Bowser puzzle piece could not attach")
        }
        return id
    }

    @discardableResult
    func attachPiece(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        sourceIndex: Int,
        position: SM64ObjectVector3? = nil,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              pool.record(for: parent) != nil,
              SM64LllBowserPuzzleBehavior.pieceActionLists.indices.contains(sourceIndex),
              SM64LllBowserPuzzleBehavior.pieceOffsets.indices.contains(sourceIndex),
              SM64LllBowserPuzzleBehavior.pieceInitialActions.indices.contains(sourceIndex) else {
            return false
        }
        let parentRecord = pool.record(for: parent)!
        let descriptor = SM64LllBowserPuzzleBehavior.pieceOffsets[sourceIndex]
        let defaultPosition = SM64ObjectVector3(
            x: parentRecord.position.x + Float(descriptor.x) * SM64LllBowserPuzzleBehavior.pieceWidth / 10,
            y: parentRecord.position.y + 50,
            z: parentRecord.position.z + Float(descriptor.z) * SM64LllBowserPuzzleBehavior.pieceWidth / 10
        )
        let piecePosition = position ?? defaultPosition
        guard piecePosition.x.isFinite, piecePosition.y.isFinite, piecePosition.z.isFinite else { return false }

        pieces[id] = PieceState(
            parentID: parent,
            sourceIndex: sourceIndex,
            actionList: SM64LllBowserPuzzleBehavior.pieceActionLists[sourceIndex],
            nextActionIndex: 0,
            continuePerformingAction: false,
            offset: .zero
        )
        return pool.mutate(id) { record in
            record.parent = parent
            record.position = piecePosition
            record.homePosition = piecePosition
            record.action = SM64LllBowserPuzzleBehavior.pieceInitialActions[sourceIndex]
            record.previousAction = 0
            record.timer = 0
            record.collisionDistance = 3_000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    /// Updates one already-registered puzzle or piece. The enclosing
    /// dispatcher remains responsible for list order; this method never
    /// recursively runs a child update.
    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64LllBowserPuzzleObjectEffectRecord? {
        if puzzleCompletionFlags[id] != nil {
            return updatePuzzleInline(id, state: engineState)
        }
        return updatePieceInline(id, state: engineState)
    }

    @discardableResult
    func updatePuzzleInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64LllBowserPuzzleObjectEffectRecord? {
        guard let completionFlags = puzzleCompletionFlags[id],
              let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64LllBowserPuzzleBehavior.updatePuzzle(
            SM64LllBowserPuzzleInput(
                action: record.action,
                previousAction: record.previousAction,
                timer: record.timer,
                completionFlags: completionFlags,
                distanceToMario: record.distanceToMario
            )
        )
        var children: [SM64ObjectID] = []
        if output.spawnPieces {
            // This is deliberately the same 0..<14 source order as
            // `sBowserPuzzlePieces` in bowser_puzzle_piece.inc.c.
            for sourceIndex in 0..<SM64LllBowserPuzzleBehavior.pieceActionLists.count {
                if let child = try? spawnPiece(
                    in: engineState,
                    parent: id,
                    sourceIndex: sourceIndex
                ) {
                    children.append(child)
                }
            }
        }
        var coins: [SM64ObjectID] = []
        if output.spawnCoins {
            // C's five `spawn_object` calls are parented to the puzzle and
            // retain their call order for the level-list insertion contract.
            for _ in 0..<5 {
                if let coin = try? engineState.spawnObject(
                    in: .level,
                    model: Self.yellowCoinModel,
                    behaviorIdentity: Self.singleCoinGetsSpawnedBehaviorIdentity,
                    parent: id
                ) {
                    _ = engineState.objects.mutate(coin) { child in
                        child.position = record.position
                        child.homePosition = record.position
                        child.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                            | SM64ObjectScheduler.objectFlagBuildTransform
                    }
                    coins.append(coin)
                }
            }
            spawnedCoins[id, default: []].append(contentsOf: coins)
        }

        puzzleCompletionFlags[id] = output.completionFlags
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.previousAction = output.previousAction
            next.timer = output.timer
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        let effect = SM64LllBowserPuzzleObjectEffectRecord(
            objectID: id,
            kind: .puzzle,
            parentID: nil,
            puzzleOutput: output,
            pieceOutput: nil,
            spawnedChildren: children,
            spawnedCoins: coins
        )
        effectLog.append(effect)
        return effect
    }

    @discardableResult
    func updatePieceInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64LllBowserPuzzleObjectEffectRecord? {
        guard var piece = pieces[id],
              let record = engineState.objects.record(for: id),
              let parent = engineState.objects.record(for: piece.parentID) else { return nil }
        let output = SM64LllBowserPuzzleBehavior.updatePiece(
            SM64LllBowserPuzzlePieceInput(
                action: record.action,
                previousAction: record.previousAction,
                timer: record.timer,
                homePosition: record.homePosition,
                offset: piece.offset,
                continuePerformingAction: piece.continuePerformingAction,
                nextActionIndex: piece.nextActionIndex,
                actionList: piece.actionList,
                marioStanding: record.platform == id,
                parentCompletionFlags: puzzleCompletionFlags[piece.parentID] ?? 0
            )
        )
        piece.offset = output.offset
        piece.nextActionIndex = output.nextActionIndex
        piece.continuePerformingAction = output.continuePerformingAction
        pieces[id] = piece
        puzzleCompletionFlags[piece.parentID] = output.parentCompletionFlags
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.previousAction = output.previousAction
            next.timer = output.timer
            next.position = output.position
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        _ = parent // Keep the parent lookup as an explicit lifecycle guard.
        let effect = SM64LllBowserPuzzleObjectEffectRecord(
            objectID: id,
            kind: .piece,
            parentID: piece.parentID,
            puzzleOutput: nil,
            pieceOutput: output,
            spawnedChildren: [],
            spawnedCoins: []
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        puzzleCompletionFlags.removeValue(forKey: id)
        spawnedCoins.removeValue(forKey: id)
        if puzzleCompletionFlags[id] == nil {
            let childIDs = pieces.compactMap { childID, state in
                state.parentID == id ? childID : nil
            }
            for childID in childIDs { removePiece(childID) }
        }
        removePiece(id)
    }

    private func removePiece(_ id: SM64ObjectID) {
        pieces.removeValue(forKey: id)
    }

    /// Drops Swift shadows for scheduler unloads, stale generations, and
    /// orphaned children without touching the pool's lifecycle itself.
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
        for id in Array(pieces.keys) {
            guard let piece = pieces[id], pool.record(for: piece.parentID) != nil else {
                removePiece(id)
                continue
            }
        }
    }
}
