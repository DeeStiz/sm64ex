import Foundation

struct SM64ObjectSchedulerTickResult: Equatable, Sendable {
    let frame: UInt64
    let listCounts: [Int]
    let objectCounter: UInt32
    let updated: [SM64ObjectID]
    let skippedByTimeStop: [SM64ObjectID]
    let unloaded: [SM64ObjectID]
    let timeStopWasActive: Bool
    let timeStopIsActive: Bool
}

/// Owner-thread object-list scheduler. The callback is deliberately a narrow
/// mutation boundary: behavior code can inspect and mutate the pool, while
/// list traversal, time-stop selection, counters, and unload ordering remain
/// one deterministic implementation.
final class SM64ObjectScheduler {
    static let graphRenderHasAnimation: UInt16 = 1 << 5
    static let interactionDoorMask: UInt32 = (1 << 2) | (1 << 11)

    typealias UpdateHandler = (_ id: SM64ObjectID, _ pool: SM64ObjectPool) -> Void

    @discardableResult
    func update(
        state: SM64SwiftEngineState,
        advanceNativeDynamics: Bool = true,
        advanceLegacyDomain: Bool = true,
        handler: UpdateHandler
    ) -> SM64ObjectSchedulerTickResult {
        let initialFrame = state.globals.frame
        guard advanceNativeDynamics else {
            return SM64ObjectSchedulerTickResult(
                frame: initialFrame,
                listCounts: Array(repeating: 0, count: SM64ObjectList.allCases.count),
                objectCounter: state.globals.objectCounter,
                updated: [],
                skippedByTimeStop: [],
                unloaded: [],
                timeStopWasActive: state.globals.timeStopState.contains(.active),
                timeStopIsActive: state.globals.timeStopState.contains(.active)
            )
        }

        state.beginFrame()
        let timeStopWasActive = state.globals.timeStopState.contains(.active)
        var listCounts = Array(repeating: 0, count: SM64ObjectList.allCases.count)
        var updated: [SM64ObjectID] = []
        var skipped: [SM64ObjectID] = []

        for objectList in SM64ObjectList.updateOrder {
            let count = updateList(
                objectList,
                state: state,
                timeStopWasActive: timeStopWasActive,
                updated: &updated,
                skipped: &skipped,
                handler: handler
            )
            listCounts[objectList.rawValue] = count
        }

        // C's terrain pass accidentally assigns the spawner count over the
        // counter before the surface count, then adds the remaining lists.
        var objectCounter = UInt32(listCounts[SM64ObjectList.surface.rawValue])
        for objectList in SM64ObjectList.updateOrder.dropFirst(2) {
            objectCounter += UInt32(listCounts[objectList.rawValue])
        }
        state.finishFrame(objectCount: objectCounter)
        let unloaded = state.objects.unloadDeactivated()

        if advanceLegacyDomain {
            state.latchTimeStopAtLogicalBoundary()
        }

        return SM64ObjectSchedulerTickResult(
            frame: state.globals.frame,
            listCounts: listCounts,
            objectCounter: objectCounter,
            updated: updated,
            skippedByTimeStop: skipped,
            unloaded: unloaded,
            timeStopWasActive: timeStopWasActive,
            timeStopIsActive: state.globals.timeStopState.contains(.active)
        )
    }

    private func updateList(
        _ objectList: SM64ObjectList,
        state: SM64SwiftEngineState,
        timeStopWasActive: Bool,
        updated: inout [SM64ObjectID],
        skipped: inout [SM64ObjectID],
        handler: UpdateHandler
    ) -> Int {
        var cursor = 0
        var count = 0

        while true {
            let ids = state.objects.ids(in: objectList)
            guard cursor < ids.count else { break }
            let id = ids[cursor]
            let nextID = cursor + 1 < ids.count ? ids[cursor + 1] : nil
            guard let record = state.objects.record(for: id) else {
                cursor += 1
                continue
            }

            if timeStopWasActive && !shouldUpdateDuringTimeStop(id: id, record: record, state: state) {
                _ = state.objects.mutate(id) { $0.graphFlags &= ~Self.graphRenderHasAnimation }
                skipped.append(id)
            } else {
                _ = state.objects.mutate(id) { $0.graphFlags |= Self.graphRenderHasAnimation }
                _ = state.setCurrentObject(id)
                handler(id, state.objects)
                updated.append(id)
            }
            count += 1

            // Keep traversal live when a behavior appends to its current list,
            // and keep the pre-callback successor when a callback despawns the
            // current node.
            let currentIDs = state.objects.ids(in: objectList)
            if let nextID, let nextIndex = currentIDs.firstIndex(of: nextID) {
                cursor = nextIndex
            } else if state.objects.contains(id) {
                cursor += 1
            } else {
                cursor = min(cursor, currentIDs.count)
            }
        }

        return count
    }

    private func shouldUpdateDuringTimeStop(
        id: SM64ObjectID,
        record: SM64ObjectRecord,
        state: SM64SwiftEngineState
    ) -> Bool {
        let flags = state.globals.timeStopState
        if flags.contains(.allObjects) { return true }
        if !flags.contains(.marioAndDoors), state.globals.marioObject == id { return true }
        if !flags.contains(.marioAndDoors), record.interactionType & Self.interactionDoorMask != 0 {
            return true
        }
        return record.activeFlags & (
            SM64ObjectPool.activeFlagUnimportant | SM64ObjectPool.activeFlagInitiatedTimeStop
        ) != 0
    }
}
