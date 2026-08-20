import Foundation

struct SM64StarSpawnCoordinatesObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64StarSpawnCoordinatesOutput
    let spawnedSparkleSpawner: SM64ObjectID?
}

final class SM64StarSpawnCoordinatesObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737363
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let transparentStarModel: UInt32 = 0x7B // MODEL_TRANSPARENT_STAR
    static let interactionType: UInt32 = 1 << 12 // INTERACT_STAR_OR_KEY

    private struct State {
        let starCollected: Bool
        let homePosition: SM64ObjectVector3
        var action: SM64StarSpawnAction
        var moveYaw: Int32
        var faceYaw: Int32
        var forwardVelocity: Float
        var velocityY: Float
        var starSpawnBaseY: Float
    }

    private let sparkleSpawnerBridge: SM64SparkleSpawnerObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64StarSpawnCoordinatesObjectEffectRecord] = []

    init(sparkleSpawnerBridge: SM64SparkleSpawnerObjectBridge? = nil) {
        self.sparkleSpawnerBridge = sparkleSpawnerBridge
    }

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
        position: SM64ObjectVector3 = .zero,
        homePosition: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: starCollected ? Self.transparentStarModel : Self.starModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, starCollected: starCollected, position: position, homePosition: homePosition, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned star coordinates object could not attach")
        }
        engineState.addTimeStop([.enabled, .marioAndDoors])
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        starCollected: Bool,
        position: SM64ObjectVector3,
        homePosition: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initial = SM64StarSpawnCoordinatesBehavior.initialState(
            starCollected: starCollected,
            position: position,
            homePosition: homePosition
        )
        states[id] = State(
            starCollected: starCollected,
            homePosition: homePosition,
            action: initial.action,
            moveYaw: initial.moveYaw,
            faceYaw: initial.faceYaw,
            forwardVelocity: initial.forwardVelocity,
            velocityY: initial.velocityY,
            starSpawnBaseY: initial.starSpawnBaseY
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = homePosition
            record.model = starCollected ? Self.transparentStarModel : Self.starModel
            record.interactionType = Self.interactionType
            record.interactionSubtype = 0
            record.hitboxRadius = 80
            record.hitboxHeight = 50
            record.intangibleTimer = 1
            record.moveAngles.yaw = initial.moveYaw
            record.forwardVelocity = initial.forwardVelocity
            record.velocity.y = initial.velocityY
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64StarSpawnCoordinatesObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64StarSpawnCoordinatesBehavior.update(
            .init(
                starCollected: state.starCollected,
                action: state.action,
                timer: record.timer,
                position: record.position,
                homePosition: state.homePosition,
                moveYaw: state.moveYaw,
                faceYaw: record.faceAngles.yaw,
                forwardVelocity: state.forwardVelocity,
                velocityY: state.velocityY,
                starSpawnBaseY: state.starSpawnBaseY,
                interactionStatus: record.interactionStatus
            )
        )
        var sparkleSpawner: SM64ObjectID?
        if output.spawnSparkle, let sparkleSpawnerBridge {
            sparkleSpawner = try? sparkleSpawnerBridge.spawnSpawner(
                in: engineState,
                position: output.position,
                randomOffset: .zero,
                randomScale: 1
            )
            if let sparkleSpawner {
                _ = engineState.objects.mutate(sparkleSpawner) { child in
                    child.parent = id
                }
            }
        }

        state.action = output.action
        state.moveYaw = output.moveYaw
        state.faceYaw = output.faceYaw
        state.forwardVelocity = output.forwardVelocity
        state.velocityY = output.velocityY
        state.starSpawnBaseY = output.starSpawnBaseY
        states[id] = state

        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.model = output.model == .transparentStar ? Self.transparentStarModel : Self.starModel
            next.faceAngles.yaw = output.faceYaw
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.intangibleTimer = output.becomeTangible ? 0 : next.intangibleTimer
            if output.clearInteraction { next.interactionStatus = 0 }
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        if output.clearTimeStop {
            engineState.removeTimeStop([.enabled, .marioAndDoors])
        }
        let effect = SM64StarSpawnCoordinatesObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedSparkleSpawner: sparkleSpawner
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
