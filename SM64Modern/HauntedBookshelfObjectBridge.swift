import Foundation

struct SM64HauntedBookshelfObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HauntedBookshelfOutput
}

final class SM64HauntedBookshelfObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_686273
    static let collisionDataIdentity: UInt64 = 0x6862735F636F6C6C
    private var shouldOpen: [SM64ObjectID: Bool] = [:]
    private(set) var effectLog: [SM64HauntedBookshelfObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { shouldOpen.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBookshelf(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned haunted bookshelf could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        shouldOpen[id] = false
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.collisionDataIdentity = Self.collisionDataIdentity
            record.collisionDistance = 4_000
            record.room = 6
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setShouldOpen(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard shouldOpen[id] != nil else { return false }
        shouldOpen[id] = value
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id) else { return false }
        let output = SM64HauntedBookshelfBehavior.update(.init(action: record.action, timer: record.timer, position: record.position, shouldOpen: shouldOpen.removeValue(forKey: id) ?? false))
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.collisionDataIdentity = Self.collisionDataIdentity
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { shouldOpen.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
