import Foundation

enum SM64SnowmanBottomRouteOwnerError: Error, Equatable, Sendable {
    case checkpointSpawnFailed(SM64ObjectID)
}

/// Coordinates the Snowman Bottom owner with its generation-scoped checkpoint.
///
/// `SM64SnowmanBottomObjectBridge` predates the central dispatch integration and
/// intentionally keeps its checkpoint bridge private.  This route-local owner
/// is the lifecycle boundary the eventual dispatch lane can adopt: a bottom
/// and the checkpoint it creates are retired together, so an unloaded parent
/// cannot leave a live child holding a stale parent identity.
final class SM64SnowmanBottomRouteOwner {
    private let checkpointBridge: SM64SnowmanCheckpointObjectBridge
    private let bottomBridge: SM64SnowmanBottomObjectBridge
    private var checkpointByBottom: [SM64ObjectID: SM64ObjectID] = [:]

    init() {
        let checkpointBridge = SM64SnowmanCheckpointObjectBridge()
        self.checkpointBridge = checkpointBridge
        self.bottomBridge = SM64SnowmanBottomObjectBridge(checkpointBridge: checkpointBridge)
    }

    var registeredIDs: [SM64ObjectID] {
        bottomBridge.registeredIDs
    }

    var checkpointIDs: [SM64ObjectID] {
        checkpointByBottom.values.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func checkpointID(for bottomID: SM64ObjectID) -> SM64ObjectID? {
        checkpointByBottom[bottomID]
    }

    func checkpointCounter(for bottomID: SM64ObjectID) -> Int32 {
        checkpointBridge.counter(for: bottomID)
    }

    var bottomEffects: [SM64SnowmanBottomObjectEffectRecord] {
        bottomBridge.effectLog
    }

    var checkpointEffects: [SM64SnowmanCheckpointObjectEffectRecord] {
        checkpointBridge.effectLog
    }

    func beginExternalTick() {
        bottomBridge.beginExternalTick()
        checkpointBridge.beginExternalTick()
    }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parentHead: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let previousCheckpointIDs = Set(engineState.objects.ids(in: .default))
        let bottomID = try bottomBridge.spawn(
            in: engineState,
            position: position,
            parentHead: parentHead
        )
        let createdCheckpointIDs = engineState.objects.ids(in: .default).filter {
            !previousCheckpointIDs.contains($0) &&
                engineState.objects.record(for: $0)?.parent == bottomID
        }
        guard createdCheckpointIDs.count == 1, let checkpointID = createdCheckpointIDs.first else {
            for id in createdCheckpointIDs {
                _ = engineState.objects.despawn(id)
            }
            bottomBridge.remove(bottomID)
            _ = engineState.objects.despawn(bottomID)
            throw SM64SnowmanBottomRouteOwnerError.checkpointSpawnFailed(bottomID)
        }
        checkpointByBottom[bottomID] = checkpointID
        return bottomID
    }

    /// Runs the parent first, matching the C object-list ordering, then its
    /// checkpoint child.  The child observes the parent's post-step action and
    /// therefore cannot increment a stale counter after the parent retires.
    @discardableResult
    func updateInline(_ bottomID: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let checkpointID = checkpointByBottom[bottomID],
              engineState.objects.record(for: bottomID) != nil,
              let checkpointRecord = engineState.objects.record(for: checkpointID),
              checkpointRecord.parent == bottomID else {
            return false
        }
        guard bottomBridge.updateInline(bottomID, state: engineState) else { return false }
        return checkpointBridge.updateInline(checkpointID, state: engineState)
    }

    /// Removes owner bookkeeping and marks the child for the same end-of-frame
    /// unload as its parent.  The pool remains authoritative for actual object
    /// destruction; this method only establishes the ownership fence.
    func remove(_ bottomID: SM64ObjectID, state engineState: SM64SwiftEngineState) {
        if let checkpointID = checkpointByBottom.removeValue(forKey: bottomID) {
            _ = engineState.objects.markForDeletion(checkpointID)
            checkpointBridge.remove(checkpointID)
        }
        _ = engineState.objects.markForDeletion(bottomID)
        bottomBridge.remove(bottomID)
    }

    /// Cleans children whose parent was unloaded before the owner callback ran.
    /// This is the generation-safe counterpart to the C parent's object-list
    /// teardown and prevents a checkpoint from surviving a bottom reset.
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        let unloadedSet = Set(unloaded)
        let stalePairs = checkpointByBottom.filter { bottomID, checkpointID in
            guard !unloadedSet.contains(bottomID),
                  !unloadedSet.contains(checkpointID),
                  pool.record(for: bottomID) != nil else {
                return true
            }
            guard let checkpoint = pool.record(for: checkpointID) else { return true }
            return checkpoint.parent != bottomID
        }
        for (bottomID, checkpointID) in stalePairs {
            if let checkpoint = pool.record(for: checkpointID), checkpoint.parent == bottomID {
                _ = pool.despawn(checkpointID)
            }
            checkpointBridge.remove(checkpointID)
            checkpointByBottom.removeValue(forKey: bottomID)
            bottomBridge.remove(bottomID)
        }
        bottomBridge.pruneExternal(unloaded: unloaded, pool: pool)
        checkpointBridge.pruneExternal(unloaded: unloaded, pool: pool)
    }
}
