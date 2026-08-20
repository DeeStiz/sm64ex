import Foundation

struct SM64WarpObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WarpOutput
}

final class SM64WarpObjectBridge {
    static let normalBehaviorIdentity: UInt64 = 0x6268_765F_777270
    static let fadingBehaviorIdentity: UInt64 = 0x6268_765F_667763
    static let pipeBehaviorIdentity: UInt64 = 0x6268_765F_777070
    static let exitPodiumBehaviorIdentity: UInt64 = 0x6268_765F_657077
    static let interactionType: UInt32 = 1 << 13 // INTERACT_WARP

    private struct State {
        let variant: SM64WarpVariant
        let behaviorByte: UInt8
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WarpObjectEffectRecord] = []

    static func behaviorIdentity(for variant: SM64WarpVariant) -> UInt64 {
        switch variant {
        case .normal: return normalBehaviorIdentity
        case .fading: return fadingBehaviorIdentity
        case .pipe: return pipeBehaviorIdentity
        case .exitPodium: return exitPodiumBehaviorIdentity
        }
    }

    static func variant(for identity: UInt64) -> SM64WarpVariant? {
        switch identity {
        case normalBehaviorIdentity: return .normal
        case fadingBehaviorIdentity: return .fading
        case pipeBehaviorIdentity: return .pipe
        case exitPodiumBehaviorIdentity: return .exitPodium
        default: return nil
        }
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnWarp(
        in engineState: SM64SwiftEngineState,
        variant: SM64WarpVariant = .normal,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: UInt8 = 0
    ) throws -> SM64ObjectID {
        let list: SM64ObjectList = variant == .pipe || variant == .exitPodium ? .surface : .level
        let id = try engineState.spawnObject(
            in: list,
            behaviorIdentity: Self.behaviorIdentity(for: variant)
        )
        guard attach(id, variant: variant, position: position, behaviorByte: behaviorByte, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned warp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        variant: SM64WarpVariant,
        position: SM64ObjectVector3,
        behaviorByte: UInt8,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(variant: variant, behaviorByte: behaviorByte)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams = Int32(behaviorByte) << 24
            record.interactionType = Self.interactionType
            record.interactionSubtype = variant == .fading ? 1 : 0
            record.intangibleTimer = 0
            record.hitboxHeight = 50
            record.collisionDistance = variant == .exitPodium ? 8_000 : record.collisionDistance
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WarpObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let byte = UInt8(truncatingIfNeeded: UInt32(bitPattern: record.behaviorParams) >> 24)
        let output = SM64WarpBehavior.update(
            .init(
                variant: state.variant,
                behaviorByte: byte,
                timer: record.timer,
                interactionStatus: record.interactionStatus
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.hitboxRadius = output.hitboxRadius
            next.hitboxHeight = output.hitboxHeight
            next.interactionSubtype = output.interactionSubtype
            next.collisionDataIdentity = output.collisionDataIdentity
            if output.clearInteraction { next.interactionStatus = 0 }
            next.timer &+= 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WarpObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
