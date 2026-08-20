import Foundation

struct SM64TTCRotatingSolidObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCRotatingSolidOutput
}

/// Owner-thread adapter for `bhvTTCRotatingSolid`. The value kernel owns turn
/// timing, vertical reset, roll approach, and sound intents; the bridge owns
/// copied state and render-facing record mutation.
final class SM64TTCRotatingSolidObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747273
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        let homeY: Float
        let numberOfSides: Int32
        var rotationDelay: Int32
        var soundTimer: Int32
        var verticalVelocity: Float
        var numberOfTurns: Int32
        let randomRotationDelay: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCRotatingSolidObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnRotatingSolid(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        behaviorByte: UInt8 = 0,
        speedSetting: Int32 = 0,
        verticalVelocity: Float = 1,
        randomRotationDelay: Int32 = 20,
        model: UInt32 = SM64TTCRotatingSolidObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCRotatingSolidObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            positionY: positionY,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting,
            verticalVelocity: verticalVelocity,
            randomRotationDelay: randomRotationDelay,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC rotating solid could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        positionY: Float = 0,
        behaviorByte: UInt8,
        speedSetting: Int32,
        verticalVelocity: Float = 1,
        randomRotationDelay: Int32 = 20,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              (0...3).contains(speedSetting), verticalVelocity.isFinite else { return false }
        let initialization = SM64TTCRotatingSolidBehavior.initialize(
            behaviorByte: behaviorByte,
            speedSetting: speedSetting
        )
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            homeY: positionY,
            numberOfSides: Int32(initialization.numberOfSides),
            rotationDelay: initialization.rotationDelay,
            soundTimer: 0,
            verticalVelocity: verticalVelocity,
            numberOfTurns: 0,
            randomRotationDelay: randomRotationDelay
        )
        _ = pool.mutate(id) { record in
            record.position.y = positionY
            record.homePosition.y = positionY
            record.faceAngles.roll = 0
            record.velocity.y = verticalVelocity
            record.behaviorParams2ndByte = Int32(behaviorByte)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTCRotatingSolidObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var solidState = states[id] else { return nil }
        let output = SM64TTCRotatingSolidBehavior.update(
            SM64TTCRotatingSolidInput(
                speedSetting: solidState.speedSetting,
                timer: record.timer,
                rotationDelay: solidState.rotationDelay,
                soundTimer: solidState.soundTimer,
                verticalVelocity: solidState.verticalVelocity,
                positionY: record.position.y,
                homeY: solidState.homeY,
                numberOfTurns: solidState.numberOfTurns,
                numberOfSides: solidState.numberOfSides,
                faceRoll: Int16(truncatingIfNeeded: record.faceAngles.roll),
                randomRotationDelay: solidState.randomRotationDelay
            )
        )
        solidState.rotationDelay = output.rotationDelay
        solidState.soundTimer = output.soundTimer
        solidState.verticalVelocity = output.verticalVelocity
        solidState.numberOfTurns = output.numberOfTurns
        states[id] = solidState
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.position.y = output.positionY
            next.velocity.y = output.verticalVelocity
            next.faceAngles.roll = Int32(output.faceRoll)
            next.angleVelocity.roll = Int32(output.angleVelocityRoll)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCRotatingSolidObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
