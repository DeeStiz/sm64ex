import Foundation

struct SM64SpawnedStarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SpawnedStarOutput
    let spawnedSparkleSpawner: SM64ObjectID?
}

final class SM64SpawnedStarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737374
    static let noLevelExitBehaviorIdentity: UInt64 = 0x6268_765F_73736E
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let transparentStarModel: UInt32 = 0x7B // MODEL_TRANSPARENT_STAR
    static let interactionType: UInt32 = 1 << 12 // INTERACT_STAR_OR_KEY

    private struct State {
        let starCollected: Bool
        let noExit: Bool
        let homePosition: SM64ObjectVector3
        var action: SM64SpawnedStarAction
        var moveYaw: Int32
        var faceYaw: Int32
        var angleVelocityYaw: Int32
        var forwardVelocity: Float
        var velocityY: Float
        var gravity: Float
    }

    private let sparkleSpawnerBridge: SM64SparkleSpawnerObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SpawnedStarObjectEffectRecord] = []

    init(sparkleSpawnerBridge: SM64SparkleSpawnerObjectBridge? = nil) {
        self.sparkleSpawnerBridge = sparkleSpawnerBridge
    }

    static func behaviorIdentity(for noExit: Bool) -> UInt64 {
        noExit ? noLevelExitBehaviorIdentity : defaultBehaviorIdentity
    }

    static func noExit(for identity: UInt64) -> Bool? {
        switch identity {
        case defaultBehaviorIdentity: return false
        case noLevelExitBehaviorIdentity: return true
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
    func spawnStar(
        in engineState: SM64SwiftEngineState,
        noExit: Bool = false,
        starCollected: Bool = false,
        position: SM64ObjectVector3 = .zero,
        homePosition: SM64ObjectVector3 = .zero,
        marioPosition: SM64ObjectVector3 = .zero,
        moveToMario: Bool = false
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: starCollected ? Self.transparentStarModel : Self.starModel,
            behaviorIdentity: Self.behaviorIdentity(for: noExit)
        )
        guard attach(id, noExit: noExit, starCollected: starCollected, position: position, homePosition: homePosition, marioPosition: marioPosition, moveToMario: moveToMario, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned star could not attach")
        }
        engineState.addTimeStop([.enabled, .marioAndDoors])
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        noExit: Bool,
        starCollected: Bool,
        position: SM64ObjectVector3,
        homePosition: SM64ObjectVector3,
        marioPosition: SM64ObjectVector3,
        moveToMario: Bool,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initial = SM64SpawnedStarBehavior.initialState(
            starCollected: starCollected,
            noExit: noExit,
            position: position,
            homePosition: homePosition,
            marioPosition: marioPosition,
            moveToMario: moveToMario
        )
        let actualHome = moveToMario ? .init(x: marioPosition.x, y: marioPosition.y + 250, z: marioPosition.z) : homePosition
        states[id] = State(starCollected: starCollected, noExit: noExit, homePosition: actualHome, action: initial.action, moveYaw: initial.moveYaw, faceYaw: initial.faceYaw, angleVelocityYaw: initial.angleVelocityYaw, forwardVelocity: initial.forwardVelocity, velocityY: initial.velocityY, gravity: initial.gravity)
        return pool.mutate(id) { record in
            record.position = initial.position
            record.homePosition = actualHome
            record.model = starCollected ? Self.transparentStarModel : Self.starModel
            record.interactionType = Self.interactionType
            record.hitboxRadius = 80
            record.hitboxHeight = 50
            record.intangibleTimer = 1
            record.moveAngles.yaw = initial.moveYaw
            record.forwardVelocity = initial.forwardVelocity
            record.velocity.y = initial.velocityY
            record.gravity = initial.gravity
            record.angleVelocity.yaw = initial.angleVelocityYaw
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setCameraClear(_ clear: Bool, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        cameraClear[id] = clear
        return true
    }

    private var cameraClear: [SM64ObjectID: Bool] = [:]

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64SpawnedStarObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64SpawnedStarBehavior.update(
            .init(starCollected: state.starCollected, noExit: state.noExit, action: state.action, timer: record.timer, position: record.position, homePosition: state.homePosition, moveYaw: state.moveYaw, faceYaw: record.faceAngles.yaw, angleVelocityYaw: state.angleVelocityYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, interactionStatus: record.interactionStatus, cameraClear: cameraClear[id] ?? true)
        )
        var sparkleSpawner: SM64ObjectID?
        if output.spawnSparkle, let sparkleSpawnerBridge {
            sparkleSpawner = try? sparkleSpawnerBridge.spawnSpawner(in: engineState, position: output.position, randomOffset: .zero, randomScale: 1)
            if let sparkleSpawner { _ = engineState.objects.mutate(sparkleSpawner) { $0.parent = id } }
        }
        state.action = output.action; state.moveYaw = output.moveYaw; state.faceYaw = output.faceYaw; state.angleVelocityYaw = output.angleVelocityYaw; state.forwardVelocity = output.forwardVelocity; state.velocityY = output.velocityY; state.gravity = output.gravity; states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.model = output.model == .transparentStar ? Self.transparentStarModel : Self.starModel
            next.faceAngles.yaw = output.faceYaw
            next.angleVelocity.yaw = output.angleVelocityYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.gravity = output.gravity
            next.intangibleTimer = output.becomeTangible ? 0 : next.intangibleTimer
            if output.clearInteraction { next.interactionStatus = 0 }
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        if output.clearTimeStop { engineState.removeTimeStop([.enabled, .marioAndDoors]) }
        let effect = SM64SpawnedStarObjectEffectRecord(objectID: id, output: output, spawnedSparkleSpawner: sparkleSpawner)
        effectLog.append(effect); return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id); cameraClear.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
