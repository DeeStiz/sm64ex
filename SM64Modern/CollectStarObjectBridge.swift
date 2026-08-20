import Foundation

struct SM64CollectStarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CollectStarOutput
}

final class SM64CollectStarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737461
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let transparentStarModel: UInt32 = 0x7B // MODEL_TRANSPARENT_STAR
    static let interactionType: UInt32 = 1 << 12 // INTERACT_STAR_OR_KEY

    private struct State {
        let starCollected: Bool
        let behaviorByte: UInt8
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CollectStarObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnStar(
        in engineState: SM64SwiftEngineState,
        starCollected: Bool = false,
        behaviorByte: UInt8 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: starCollected ? Self.transparentStarModel : Self.starModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, starCollected: starCollected, behaviorByte: behaviorByte, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned collectible star could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        starCollected: Bool,
        behaviorByte: UInt8,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(starCollected: starCollected, behaviorByte: behaviorByte)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.model = starCollected ? Self.transparentStarModel : Self.starModel
            record.behaviorParams = Int32(behaviorByte) << 24
            record.interactionType = Self.interactionType
            record.hitboxRadius = 80
            record.hitboxHeight = 50
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64CollectStarObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64CollectStarBehavior.update(
            .init(
                starCollected: state.starCollected,
                faceYaw: record.faceAngles.yaw,
                interactionStatus: record.interactionStatus
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.model = output.model == .transparentStar ? Self.transparentStarModel : Self.starModel
            next.faceAngles.yaw = output.faceYaw
            next.hitboxRadius = output.hitboxRadius
            next.hitboxHeight = output.hitboxHeight
            if output.clearInteraction { next.interactionStatus = 0 }
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64CollectStarObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
