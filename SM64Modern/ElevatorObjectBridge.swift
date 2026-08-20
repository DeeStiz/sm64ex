import Foundation

struct SM64ElevatorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ElevatorOutput
}

/// Shared owner adapter for the standard, RR, and mesh elevator identities.
/// The existing value kernel owns action/timer movement decisions; this type
/// owns immutable authored bounds, Mario/platform relation input, and the
/// level-list object record mutation.
final class SM64ElevatorObjectBridge {
    static let rrBehaviorIdentity: UInt64 = 0x6268_765F_7272_65
    static let hmcBehaviorIdentity: UInt64 = 0x6268_765F_686D_6365
    static let meshBehaviorIdentity: UInt64 = 0x6268_765F_6D65_7365
    static let anotherElevatorBehaviorIdentity: UInt64 = 0x6268_765F_61656C
    static let defaultModel: UInt32 = 0

    private struct Metadata: Sendable {
        let bottomY: Float
        let topY: Float
        let midpointY: Float
        let platformKind: UInt32
        let marioInAirAction: Bool
    }

    private var registered: Set<SM64ObjectID> = []
    private var metadata: [SM64ObjectID: Metadata] = [:]
    private(set) var effectLog: [SM64ElevatorObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    static func platformKind(for behaviorIdentity: UInt64) -> UInt32 {
        switch behaviorIdentity {
        case rrBehaviorIdentity: return 1
        case meshBehaviorIdentity: return 2
        default: return 0
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnElevator(
        in engineState: SM64SwiftEngineState,
        behaviorIdentity: UInt64,
        positionY: Float = 0,
        bottomY: Float? = nil,
        topY: Float? = nil,
        midpointY: Float? = nil,
        faceYaw: Int16 = 0,
        model: UInt32 = SM64ElevatorObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        let bottom = bottomY ?? positionY
        let top = topY ?? positionY + 384
        let midpoint = midpointY ?? (bottom + top) * 0.5
        guard attach(
            id,
            positionY: positionY,
            bottomY: bottom,
            topY: top,
            midpointY: midpoint,
            platformKind: Self.platformKind(for: behaviorIdentity),
            faceYaw: faceYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned elevator could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        positionY: Float,
        bottomY: Float,
        topY: Float,
        midpointY: Float,
        platformKind: UInt32,
        marioInAirAction: Bool = false,
        faceYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              bottomY.isFinite, topY.isFinite, midpointY.isFinite,
              bottomY <= topY else { return false }
        registered.insert(id)
        metadata[id] = Metadata(
            bottomY: bottomY,
            topY: topY,
            midpointY: midpointY,
            platformKind: platformKind,
            marioInAirAction: marioInAirAction
        )
        _ = pool.mutate(id) { record in
            record.position.y = positionY
            record.homePosition.y = bottomY
            record.faceAngles.yaw = Int32(faceYaw)
            record.moveAngles.yaw = Int32(faceYaw)
            record.action = 0
            record.timer = 0
            record.velocity.y = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state: SM64SwiftEngineState
    ) -> SM64ElevatorObjectEffectRecord? {
        guard registered.contains(id),
              let record = state.objects.record(for: id),
              let authored = metadata[id] else { return nil }
        let mario = state.globals.marioObject.flatMap(state.objects.record(for:))
        let output = SM64ElevatorBehavior.update(
            SM64ElevatorInput(
                action: record.action,
                timer: record.timer,
                positionY: record.position.y,
                velocityY: record.velocity.y,
                bottomY: authored.bottomY,
                topY: authored.topY,
                midpointY: authored.midpointY,
                platformKind: authored.platformKind,
                marioPositionY: mario?.position.y ?? record.position.y,
                marioOnPlatform: record.platform != nil || mario?.platform == id,
                marioInAirAction: authored.marioInAirAction
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = state.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64ElevatorObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        metadata.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
