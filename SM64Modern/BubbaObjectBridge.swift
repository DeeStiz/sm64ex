import Foundation

struct SM64BubbaObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BubbaOutput
    let spawnedWaterSplash: SM64ObjectID?
}

final class SM64BubbaObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62756262
    static let defaultModel: UInt32 = 0x59 // MODEL_BUBBA
    static let interactionType: UInt32 = 1 << 26 // INTERACT_CLAM_OR_BUBBA

    private struct State {
        var attackTimer: Int32
        var targetYaw: Int32
        var targetPitch: Int32
        var wasInWater: Bool
        var waterLevel: Float
        var nearAndFacingMario: Bool
        var pitchAligned: Bool
        var inWater: Bool
        var hitWall: Bool
        var reflectedYaw: Int32
    }

    private let waterSplashBridge: SM64WaterSplashObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BubbaObjectEffectRecord] = []

    init(waterSplashBridge: SM64WaterSplashObjectBridge? = nil) {
        self.waterSplashBridge = waterSplashBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBubba(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: Self.defaultModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attachBubba(id, position: position, waterLevel: waterLevel, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bubba could not attach")
        }
        return id
    }

    @discardableResult
    func attachBubba(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        waterLevel: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            attackTimer: 0,
            targetYaw: 0,
            targetPitch: 0,
            wasInWater: false,
            waterLevel: waterLevel,
            nearAndFacingMario: false,
            pitchAligned: false,
            inWater: false,
            hitWall: false,
            reflectedYaw: 0
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.gravity = -4
            record.buoyancy = 0
            record.interactionType = Self.interactionType
            record.damageOrCoinValue = 1
            record.health = 99
            record.hitboxRadius = 300
            record.hitboxHeight = 200
            record.hurtboxRadius = 150
            record.hurtboxHeight = 200
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInput(
        distanceToMario: Float? = nil,
        nearAndFacingMario: Bool? = nil,
        pitchAligned: Bool? = nil,
        inWater: Bool? = nil,
        waterLevel: Float? = nil,
        pitchToMario: Int32? = nil,
        pitchToHome: Int32? = nil,
        hitWall: Bool? = nil,
        reflectedYaw: Int32? = nil,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = states[id] else { return false }
        if let nearAndFacingMario { state.nearAndFacingMario = nearAndFacingMario }
        if let pitchAligned { state.pitchAligned = pitchAligned }
        if let inWater { state.inWater = inWater }
        if let waterLevel { state.waterLevel = waterLevel }
        if let hitWall { state.hitWall = hitWall }
        if let reflectedYaw { state.reflectedYaw = reflectedYaw }
        states[id] = state
        if let distanceToMario { distanceInputs[id] = distanceToMario }
        if let pitchToMario { pitchToMarioInputs[id] = pitchToMario }
        if let pitchToHome { pitchToHomeInputs[id] = pitchToHome }
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64BubbaBehavior.update(
            SM64BubbaInput(
                action: record.action,
                timer: record.timer,
                attackTimer: state.attackTimer,
                position: record.position,
                moveYaw: record.moveAngles.yaw,
                movePitch: record.moveAngles.pitch,
                forwardVelocity: record.forwardVelocity,
                velocityY: record.velocity.y,
                targetYaw: state.targetYaw,
                targetPitch: state.targetPitch,
                pitchToMario: pitchToMarioInputs.removeValue(forKey: id) ?? record.moveAngles.pitch,
                pitchToHome: pitchToHomeInputs.removeValue(forKey: id) ?? record.moveAngles.pitch,
                angleToMario: record.angleToMario,
                distanceToMario: distanceInputs.removeValue(forKey: id) ?? record.distanceToMario,
                nearAndFacingMario: state.nearAndFacingMario,
                pitchAligned: state.pitchAligned,
                inWater: state.inWater,
                wasInWater: state.wasInWater,
                waterLevel: state.waterLevel,
                floorHeight: record.floorHeight,
                hitWall: state.hitWall,
                reflectedYaw: state.reflectedYaw
            )
        )
        state.attackTimer = output.attackTimer
        state.targetYaw = output.targetYaw
        state.targetPitch = output.targetPitch
        state.wasInWater = state.inWater
        state.nearAndFacingMario = false
        state.pitchAligned = false
        state.hitWall = false
        states[id] = state

        var splash: SM64ObjectID?
        if output.spawnWaterSplash {
            if let waterSplashBridge {
                splash = try? waterSplashBridge.spawnBubbleSplash(
                    in: engineState,
                    position: output.position,
                    waterLevel: state.waterLevel
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.moveAngles.pitch = output.movePitch
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.animationState = output.animationState
            next.interactionSubtype = output.interactionSubtype
            next.hurtboxRadius = output.hurtboxRadius
            next.hurtboxHeight = 200
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, spawnedWaterSplash: splash))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        distanceInputs.removeValue(forKey: id)
        pitchToMarioInputs.removeValue(forKey: id)
        pitchToHomeInputs.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }

    private var distanceInputs: [SM64ObjectID: Float] = [:]
    private var pitchToMarioInputs: [SM64ObjectID: Int32] = [:]
    private var pitchToHomeInputs: [SM64ObjectID: Int32] = [:]

}
