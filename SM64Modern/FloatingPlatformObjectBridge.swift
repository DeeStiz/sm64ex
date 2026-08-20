import Foundation

struct SM64FloatingPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let variant: SM64FloatingPlatformVariant
    let output: SM64FloatingPlatformOutput
}

final class SM64FloatingPlatformObjectBridge {
    static let wdwSquareBehaviorIdentity: UInt64 = 0x6268_765F_77667371
    static let wdwRectangularBehaviorIdentity: UInt64 = 0x6268_765F_77667274
    static let jrbBehaviorIdentity: UInt64 = 0x6268_765F_6A726266
    static let defaultModel: UInt32 = 0

    private struct State {
        let variant: SM64FloatingPlatformVariant
        var floatY: Float
        var velocityY: Float
        var oscillationTimer: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FloatingPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    static func behaviorIdentity(for variant: SM64FloatingPlatformVariant) -> UInt64 {
        switch variant {
        case .wdwSquare: return wdwSquareBehaviorIdentity
        case .wdwRectangular: return wdwRectangularBehaviorIdentity
        case .jrb: return jrbBehaviorIdentity
        }
    }

    static func variant(for behaviorIdentity: UInt64) -> SM64FloatingPlatformVariant? {
        switch behaviorIdentity {
        case wdwSquareBehaviorIdentity: return .wdwSquare
        case wdwRectangularBehaviorIdentity: return .wdwRectangular
        case jrbBehaviorIdentity: return .jrb
        default: return nil
        }
    }

    @discardableResult
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        variant: SM64FloatingPlatformVariant,
        position: SM64ObjectVector3 = .zero,
        floorHeight: Float = 0,
        waterLevel: Float = 0,
        platformOffset: Float = 64,
        model: UInt32 = SM64FloatingPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: model,
            behaviorIdentity: Self.behaviorIdentity(for: variant)
        )
        guard attach(
            id,
            variant: variant,
            position: position,
            floorHeight: floorHeight,
            waterLevel: waterLevel,
            platformOffset: platformOffset,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned floating platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        variant: SM64FloatingPlatformVariant,
        position: SM64ObjectVector3 = .zero,
        floorHeight: Float,
        waterLevel: Float,
        platformOffset: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(variant: variant, floatY: 0, velocityY: 0, oscillationTimer: 0)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.floorHeight = floorHeight
            record.behaviorParams = Int32(platformOffset.bitPattern)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            record.soundStateID = Int32(waterLevel.bitPattern)
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64FloatingPlatformObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let platformOffset = Float(bitPattern: UInt32(bitPattern: record.behaviorParams))
        let waterLevel = Float(bitPattern: UInt32(bitPattern: record.soundStateID))
        let marioPosition = engineState.globals.marioObject.flatMap {
            engineState.objects.record(for: $0)?.position
        } ?? .zero
        let output = SM64FloatingPlatformBehavior.update(
            SM64FloatingPlatformInput(
                marioOnPlatform: record.platform == id,
                objectPosition: record.position,
                marioPosition: marioPosition,
                moveYaw: record.moveAngles.yaw,
                floorHeight: record.floorHeight,
                waterLevel: waterLevel,
                platformOffset: platformOffset,
                floatY: state.floatY,
                velocityY: state.velocityY,
                oscillationTimer: state.oscillationTimer,
                facePitch: record.faceAngles.pitch,
                faceRoll: record.faceAngles.roll
            )
        )
        state.floatY = output.floatY
        state.velocityY = output.velocityY
        state.oscillationTimer = output.oscillationTimer
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.homePosition.y = output.homeY
            next.position.y = output.positionY
            next.faceAngles.pitch = output.facePitch
            next.faceAngles.roll = output.faceRoll
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64FloatingPlatformObjectEffectRecord(
            objectID: id,
            variant: state.variant,
            output: output
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
