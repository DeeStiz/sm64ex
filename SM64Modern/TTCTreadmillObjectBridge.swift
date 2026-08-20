import Foundation

struct SM64TTCTreadmillObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCTreadmillOutput
}

/// Owner-thread adapter for `bhvTTCTreadmill`. The first registered treadmill
/// is elected as the master in deterministic scheduler order; its surface
/// speed is shared with later treadmill records just like C's shared surface
/// pointers.
final class SM64TTCTreadmillObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_74746D
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        var timeUntilSwitch: Int32
        var targetSpeed: Float
        let randomTimeUntilSwitch: Int32
        let randomDirection: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private var masterID: SM64ObjectID?
    private var surfaceSpeed: Float = 0
    private(set) var effectLog: [SM64TTCTreadmillObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        if let masterID, !registered.contains(masterID) { self.masterID = nil }
    }

    @discardableResult
    func spawnTreadmill(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedSetting: Int32 = 0,
        behaviorByte: UInt8 = 0,
        randomTimeUntilSwitch: Int32 = 20,
        randomDirection: Int32 = -1,
        model: UInt32 = SM64TTCTreadmillObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCTreadmillObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            faceYaw: faceYaw,
            speedSetting: speedSetting,
            behaviorByte: behaviorByte,
            randomTimeUntilSwitch: randomTimeUntilSwitch,
            randomDirection: randomDirection,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC treadmill could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedSetting: Int32,
        behaviorByte: UInt8,
        randomTimeUntilSwitch: Int32 = 20,
        randomDirection: Int32 = -1,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (0...3).contains(speedSetting) else { return false }
        let initialization = SM64TTCTreadmillBehavior.initialize(
            behaviorByte: behaviorByte,
            speedSetting: speedSetting
        )
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            timeUntilSwitch: 0,
            targetSpeed: initialization.initialSurfaceSpeed,
            randomTimeUntilSwitch: randomTimeUntilSwitch,
            randomDirection: randomDirection
        )
        if registered.count == 1 {
            surfaceSpeed = initialization.initialSurfaceSpeed
        }
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = Int32(faceYaw)
            record.behaviorParams2ndByte = Int32(behaviorByte)
            record.forwardVelocity = 0.084 * initialization.initialSurfaceSpeed
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTCTreadmillObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var treadmillState = states[id] else { return nil }
        let isMaster = masterID == id
        let noMasterExists = masterID == nil
        let output = SM64TTCTreadmillBehavior.update(
            SM64TTCTreadmillInput(
                speedSetting: treadmillState.speedSetting,
                timer: record.timer,
                timeUntilSwitch: treadmillState.timeUntilSwitch,
                speed: surfaceSpeed,
                targetSpeed: treadmillState.targetSpeed,
                isMaster: isMaster,
                noMasterExists: noMasterExists,
                randomTimeUntilSwitch: treadmillState.randomTimeUntilSwitch,
                randomDirection: treadmillState.randomDirection
            )
        )
        if output.becameMaster { masterID = id }
        if isMaster || output.becameMaster {
            surfaceSpeed = output.speed
            treadmillState.timeUntilSwitch = output.timeUntilSwitch
            treadmillState.targetSpeed = output.targetSpeed
        }
        states[id] = treadmillState
        let nextTimer = output.timer == record.timer ? record.timer &+ 1 : output.timer
        _ = engineState.objects.mutate(id) { next in
            next.timer = nextTimer
            next.forwardVelocity = output.forwardVelocity
            next.velocity.x = output.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: next.moveAngles.yaw))
            next.velocity.z = output.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: next.moveAngles.yaw))
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCTreadmillObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        states.removeValue(forKey: id)
        if masterID == id { masterID = nil }
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
