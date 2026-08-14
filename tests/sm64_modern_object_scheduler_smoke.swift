import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashResult(_ initial: UInt64, _ result: SM64ObjectSchedulerTickResult) -> UInt64 {
    var hash = hashU64(initial, result.frame)
    for count in result.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(result.objectCounter))
    hash = hashU64(hash, UInt64(result.updated.count))
    for id in result.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(result.skippedByTimeStop.count))
    for id in result.skippedByTimeStop { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(result.unloaded.count))
    for id in result.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, result.timeStopWasActive ? 1 : 0)
    return hashU64(hash, result.timeStopIsActive ? 1 : 0)
}

@main
enum SM64ModernObjectSchedulerSmoke {
    static func main() throws {
        let state = SM64SwiftEngineState(objectCapacity: 8)
        let spawner = try state.spawnObject(in: .spawner, behaviorIdentity: 0x10)
        let surface = try state.spawnObject(in: .surface, behaviorIdentity: 0x20)
        _ = try state.spawnObject(in: .generalActor, behaviorIdentity: 0x30)
        _ = try state.spawnObject(in: .player, behaviorIdentity: 0x40, isMario: true)
        _ = try state.spawnObject(in: .unimportant, behaviorIdentity: 0x50)
        let scheduler = SM64ObjectScheduler()
        var spawnedDuringUpdate = false

        let first = scheduler.update(state: state) { id, pool in
            if id == spawner && !spawnedDuringUpdate {
                spawnedDuringUpdate = true
                _ = try? pool.spawn(in: .spawner, behaviorIdentity: 0x60)
            }
            if id == surface { _ = pool.markForDeletion(id) }
        }
        require(first.updated.map(\.traceSubject) == [1, 6, 2, 4, 3, 5], "live list append order")
        require(first.unloaded == [surface], "ordered end-of-frame unload")
        require(first.listCounts[SM64ObjectList.spawner.rawValue] == 2, "spawner count")
        require(first.objectCounter == 4, "terrain counter replacement")
        require(first.frame == 1 && !first.timeStopWasActive && !first.timeStopIsActive, "first tick state")
        require(state.globals.previousFrameObjectCount == 4, "previous object count")
        require(!state.objects.contains(surface), "surface removed")

        state.addTimeStop(.enabled)
        let second = scheduler.update(state: state) { _, _ in }
        require(second.updated.map(\.traceSubject) == [1, 6, 4, 3, 5], "second tick ordering")
        require(second.skippedByTimeStop.isEmpty, "time stop latch is deferred")
        require(second.timeStopIsActive, "logical time stop latch")

        let third = scheduler.update(state: state) { _, _ in }
        require(third.updated.map(\.traceSubject) == [4, 5], "time stop allowlist")
        require(third.skippedByTimeStop.map(\.traceSubject) == [1, 6, 3], "time stop skipped objects")
        require(third.listCounts[SM64ObjectList.spawner.rawValue] == 2, "time stop counts nodes")
        require(third.objectCounter == 3, "time stop counter")
        require(third.timeStopWasActive && third.timeStopIsActive, "active time stop remains latched")

        var fingerprint = fnvOffset
        fingerprint = hashResult(fingerprint, first)
        fingerprint = hashResult(fingerprint, second)
        fingerprint = hashResult(fingerprint, third)
        print(String(format: "objectSchedulerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern object scheduler smoke passed")
    }
}
