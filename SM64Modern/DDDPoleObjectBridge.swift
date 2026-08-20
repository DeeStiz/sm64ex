import Foundation

struct SM64DDDPoleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64DDDPoleOutput
}

final class SM64DDDPoleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_64646470
    static let defaultModel: UInt32 = 0
    private var saveUnlocked: [SM64ObjectID: Bool] = [:]
    private(set) var effectLog: [SM64DDDPoleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        saveUnlocked.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPole(
        in engineState: SM64SwiftEngineState,
        behaviorParam: Int32 = 1,
        saveUnlocked: Bool = true,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .polelike, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, behaviorParam: behaviorParam, saveUnlocked: saveUnlocked, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned DDD pole could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        behaviorParam: Int32,
        saveUnlocked: Bool,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        self.saveUnlocked[id] = saveUnlocked
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = behaviorParam
            record.interactionType = 1 << 6
            record.hitboxRadius = 80
            record.hitboxHeight = 800
            record.hitboxDownOffset = 100
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let unlocked = saveUnlocked[id], let record = engineState.objects.record(for: id) else { return false }
        let maxOffset = 100 * Float(record.behaviorParams2ndByte)
        let output = SM64DDDPoleBehavior.update(.init(
            timer: record.timer,
            offset: record.graphYOffset,
            velocity: record.forwardVelocity == 0 ? 10 : record.forwardVelocity,
            maxOffset: maxOffset,
            saveUnlocked: unlocked
        ))
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.graphYOffset = output.offset
            next.forwardVelocity = output.velocity
            next.hitboxDownOffset = output.hitboxDownOffset
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { saveUnlocked.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
