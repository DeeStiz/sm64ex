import Foundation

struct SM64BowlingBallObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BowlingBallOutput
    let spawnedBall: SM64ObjectID?
}

final class SM64BowlingBallObjectBridge {
    static let bowlingBallBehaviorIdentity: UInt64 = 0x6268_765F_62626C62
    static let freeBowlingBallBehaviorIdentity: UInt64 = 0x6268_765F_6662626C
    static let bobBowlingBallSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_62737062
    static let ttmBowlingBallSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_74737062
    static let thiBowlingBallSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_68627370
    static let pitBowlingBallBehaviorIdentity: UInt64 = 0x6268_765F_7062626C
    static let defaultModel: UInt32 = 0xB4 // MODEL_BOWLING_BALL
    static let damageInteractionType: UInt32 = 1

    private struct State {
        let role: SM64BowlingBallRole
        let behaviorParam: Int32
        let periodMinus1: Int32
        var targetYaw: Int32
        var maxSpawnDistance: Float
        var distanceToMario: Float
        var marioY: Float
        var spawnAdmission: Bool
        var pathEnded: Bool
        var grounded: Bool
        var landed: Bool
        var floorFlat: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BowlingBallObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBobSpawner(
        in engineState: SM64SwiftEngineState,
        behaviorParam: Int32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            behaviorIdentity: Self.bobBowlingBallSpawnerBehaviorIdentity
        )
        guard attachSpawner(id, behaviorParam: behaviorParam, periodMinus1: 127, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bob bowling-ball spawner could not attach")
        }
        return id
    }

    @discardableResult
    func spawnTtmSpawner(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 1, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.ttmBowlingBallSpawnerBehaviorIdentity)
        guard attachSpawner(id, behaviorParam: behaviorParam, periodMinus1: 127, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned TTM bowling-ball spawner could not attach") }
        return id
    }

    @discardableResult
    func spawnThiSpawner(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 3, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.thiBowlingBallSpawnerBehaviorIdentity)
        guard attachSpawner(id, behaviorParam: behaviorParam, periodMinus1: 63, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned THI bowling-ball spawner could not attach") }
        return id
    }

    @discardableResult
    func spawnBowlingBall(
        in engineState: SM64SwiftEngineState,
        behaviorParam: Int32 = 0,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: Self.defaultModel,
            behaviorIdentity: Self.bowlingBallBehaviorIdentity,
            parent: parent
        )
        guard attachBall(id, role: .rolling, behaviorParam: behaviorParam, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned bowling ball could not attach")
        }
        return id
    }

    @discardableResult
    func spawnFreeBowlingBall(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: Self.defaultModel,
            behaviorIdentity: Self.freeBowlingBallBehaviorIdentity
        )
        guard attachBall(id, role: .free, behaviorParam: 0, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned free bowling ball could not attach")
        }
        return id
    }

    @discardableResult
    func spawnPitBowlingBall(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, model: Self.defaultModel, behaviorIdentity: Self.pitBowlingBallBehaviorIdentity)
        guard attachBall(id, role: .pit, behaviorParam: 0, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned pit bowling ball could not attach") }
        return id
    }

    @discardableResult
    private func attachSpawner(
        _ id: SM64ObjectID,
        behaviorParam: Int32,
        periodMinus1: Int32,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            role: .spawner,
            behaviorParam: behaviorParam,
            periodMinus1: periodMinus1,
            targetYaw: 0,
            maxSpawnDistance: maxDistance(for: behaviorParam),
            distanceToMario: 19_000,
            marioY: 0,
            spawnAdmission: false,
            pathEnded: false,
            grounded: false,
            landed: false,
            floorFlat: false
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = behaviorParam
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    private func attachBall(
        _ id: SM64ObjectID,
        role: SM64BowlingBallRole,
        behaviorParam: Int32,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            role: role,
            behaviorParam: behaviorParam,
            periodMinus1: 0,
            targetYaw: 0,
            maxSpawnDistance: 0,
            distanceToMario: 19_000,
            marioY: 0,
            spawnAdmission: false,
            pathEnded: false,
            grounded: false,
            landed: false,
            floorFlat: false
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.gravity = role == .pit ? 12 : 5.5
            record.friction = 1
            record.buoyancy = 2
            record.interactionType = Self.damageInteractionType
            record.damageOrCoinValue = 2
            record.hitboxRadius = 100
            record.hitboxHeight = 150
            record.graphYOffset = 130
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInput(
        distanceToMario: Float? = nil,
        marioY: Float? = nil,
        targetYaw: Int32? = nil,
        spawnAdmission: Bool? = nil,
        pathEnded: Bool? = nil,
        grounded: Bool? = nil,
        landed: Bool? = nil,
        floorFlat: Bool? = nil,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = states[id] else { return false }
        if let distanceToMario { state.distanceToMario = distanceToMario }
        if let marioY { state.marioY = marioY }
        if let targetYaw { state.targetYaw = targetYaw }
        if let spawnAdmission { state.spawnAdmission = spawnAdmission }
        if let pathEnded { state.pathEnded = pathEnded }
        if let grounded { state.grounded = grounded }
        if let landed { state.landed = landed }
        if let floorFlat { state.floorFlat = floorFlat }
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64BowlingBallBehavior.update(.init(
            role: state.role,
            action: record.action,
            timer: record.timer,
            position: record.position,
            homePosition: record.homePosition,
            moveYaw: record.moveAngles.yaw,
            targetYaw: state.targetYaw,
            forwardVelocity: record.forwardVelocity,
            velocityY: record.velocity.y,
            behaviorParam: state.behaviorParam,
            distanceToMario: state.distanceToMario,
            marioY: state.marioY,
            periodMinus1: state.periodMinus1,
            maxSpawnDistance: state.maxSpawnDistance,
            spawnAdmission: state.spawnAdmission,
            pathEnded: state.pathEnded,
            grounded: state.grounded,
            landed: state.landed,
            floorFlat: state.floorFlat
        ))
        state.spawnAdmission = false
        state.pathEnded = false
        state.grounded = false
        state.landed = false
        state.floorFlat = false
        states[id] = state

        var child: SM64ObjectID?
        if output.spawnBall {
            child = try? spawnBowlingBall(
                in: engineState,
                behaviorParam: state.behaviorParam,
                position: record.position,
                parent: id
            )
            if let child {
                _ = engineState.objects.mutate(child) { $0.behaviorParams2ndByte = state.behaviorParam }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.graphYOffset = output.graphYOffset
            next.intangibleTimer = output.tangible ? -1 : 1
            next.graphFlags = output.visible
                ? next.graphFlags & ~UInt16(0x10)
                : next.graphFlags | UInt16(0x10)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output, spawnedBall: child))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }

    private func maxDistance(for behaviorParam: Int32) -> Float {
        switch behaviorParam {
        case 0: return 7_000
        case 1: return 8_000
        case 2: return 6_000
        default: return 12_000
        }
    }
}
