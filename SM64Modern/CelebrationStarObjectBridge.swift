import Foundation

struct SM64CelebrationStarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CelebrationStarOutput
    let spawnedSparkle: SM64ObjectID?
}

final class SM64CelebrationStarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_637374
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let bowserKeyModel: UInt32 = 0xCC // MODEL_BOWSER_KEY
    static let interactionType: UInt32 = 1 << 12 // INTERACT_STAR_OR_KEY
    static let interactionSubtype: UInt32 = 1 << 11 // INT_SUBTYPE_GRAND_STAR
    static let hitboxRadius: Float = 160
    static let hitboxHeight: Float = 100

    private struct State {
        let variant: SM64CelebrationStarVariant
        let homePosition: SM64ObjectVector3
        var moveYaw: Int32
        var faceYaw: Int32
        var facePitch: Int32
        var faceRoll: Int32
        var diameter: Float
        var scale: Float
        var action: SM64CelebrationStarAction
        var marioYaw: Int32
    }

    private let sparkleBridge: SM64CelebrationStarSparkleObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CelebrationStarObjectEffectRecord] = []

    init(sparkleBridge: SM64CelebrationStarSparkleObjectBridge? = nil) {
        self.sparkleBridge = sparkleBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnStar(
        in engineState: SM64SwiftEngineState,
        variant: SM64CelebrationStarVariant = .star,
        marioPosition: SM64ObjectVector3 = .zero,
        marioYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: variant == .bowserKey ? Self.bowserKeyModel : Self.starModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, variant: variant, marioPosition: marioPosition, marioYaw: marioYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned celebration star could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        variant: SM64CelebrationStarVariant,
        marioPosition: SM64ObjectVector3,
        marioYaw: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initial = SM64CelebrationStarBehavior.initialState(
            variant: variant,
            marioPosition: marioPosition,
            marioYaw: marioYaw
        )
        states[id] = State(
            variant: variant,
            homePosition: .init(x: marioPosition.x, y: initial.position.y, z: marioPosition.z),
            moveYaw: initial.moveYaw,
            faceYaw: initial.faceYaw,
            facePitch: initial.facePitch,
            faceRoll: initial.faceRoll,
            diameter: initial.diameter,
            scale: initial.scale,
            action: initial.action,
            marioYaw: marioYaw
        )
        return pool.mutate(id) { record in
            record.position = initial.position
            record.homePosition = initial.position
            record.scale = .init(x: initial.scale, y: initial.scale, z: initial.scale)
            record.faceAngles.pitch = initial.facePitch
            record.faceAngles.yaw = initial.faceYaw
            record.faceAngles.roll = initial.faceRoll
            record.action = initial.action.rawValue
            record.interactionType = Self.interactionType
            record.interactionSubtype = Self.interactionSubtype
            record.hitboxRadius = Self.hitboxRadius
            record.hitboxHeight = Self.hitboxHeight
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64CelebrationStarObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64CelebrationStarBehavior.update(
            .init(
                variant: state.variant,
                action: state.action,
                timer: record.timer,
                position: record.position,
                homePosition: state.homePosition,
                moveYaw: state.moveYaw,
                faceYaw: state.faceYaw,
                facePitch: state.facePitch,
                faceRoll: state.faceRoll,
                diameter: state.diameter,
                scale: state.scale,
                marioYaw: state.marioYaw
            )
        )

        var sparkle: SM64ObjectID?
        if output.spawnSparkle, let sparkleBridge {
            sparkle = try? sparkleBridge.spawnSparkle(in: engineState, position: output.position)
            if let sparkle {
                _ = engineState.objects.mutate(sparkle) { child in
                    child.parent = id
                }
            }
        }

        state.action = output.action
        state.moveYaw = output.moveYaw
        state.faceYaw = output.faceYaw
        state.facePitch = output.facePitch
        state.faceRoll = output.faceRoll
        state.diameter = output.diameter
        state.scale = output.scale
        states[id] = state

        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.faceAngles.pitch = output.facePitch
            next.faceAngles.yaw = output.faceYaw
            next.faceAngles.roll = output.faceRoll
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.action = output.action.rawValue
            next.graphYOffset = output.graphYOffset
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }

        let effect = SM64CelebrationStarObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedSparkle: sparkle
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
