import Foundation

// Central integration note (owned by the coordinator): add these eight
// identities to BehaviorDispatchBridge's route table and owner-thread tick
// result, instantiate the four bridges below, and wire the existing object
// spawn paths for bhvUkiki/bhvMacroUkiki, bhvUkikiCage/bhvUkikiCageStar,
// bhvMips, bhvToadMessage, bhvMenuButton, and bhvMenuButtonManager. The
// Ukiki cage owner also needs the existing `bhvUkikiCageChild` terminal/no-op
// identity when reproducing the two C SPAWN_CHILD records. This file stays
// central-dispatch agnostic so it can be compiled and contract-tested in
// isolation.

// MARK: - Ukiki owner bridge

struct SM64UkikiEnvironment: Equatable, Sendable {
    var marioHasHat = false
    var marioFarAway = false
    var floorAhead = false
    var wallHit = false
    var edgeHit = false
    var marioMovingFastOrInAir = false
    var animationNearEnd = false
    var dialogResult: Int32 = 0
    var canActivateText = false
    var cageDistance: Float = .greatestFiniteMagnitude
    var cageYaw: Int32 = 0
    var tauntsToBeDone: Int32 = 2
}

struct SM64UkikiObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64UkikiOutput
}

final class SM64UkikiObjectBridge {
    static let ukikiBehaviorIdentity: UInt64 = 0x6268_765F_756B
    static let macroUkikiBehaviorIdentity: UInt64 = 0x6268_765F_6D756B
    static let defaultBehaviorIdentity: UInt64 = ukikiBehaviorIdentity

    private let scheduler: SM64ObjectScheduler
    private var environments: [SM64ObjectID: SM64UkikiEnvironment] = [:]
    private(set) var effectLog: [SM64UkikiObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }
    var registeredIDs: [SM64ObjectID] { environments.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        behaviorParam: Int32 = SM64UkikiBehavior.cageParam,
        position: SM64ObjectVector3 = .zero,
        behaviorIdentity: UInt64 = SM64UkikiObjectBridge.ukikiBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: behaviorIdentity)
        guard attach(id, behaviorParam: behaviorParam, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Ukiki could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        behaviorParam: Int32 = SM64UkikiBehavior.cageParam,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        environments[id] = SM64UkikiEnvironment()
        _ = pool.mutate(id) { record in
            record.behaviorParams2ndByte = behaviorParam
            record.position = position
            record.homePosition = position
            record.interactionType = 0x0000_0001
            record.interactionSubtype = SM64UkikiBehavior.holdableNPC
            record.hitboxRadius = 40
            record.hitboxHeight = 40
            record.gravity = -400
            record.buoyancy = 200
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64UkikiEnvironment, for id: SM64ObjectID) -> Bool {
        guard environments[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id), environments[id] != nil else { return false }
        let environment = environments[id]!
        let output = SM64UkikiBehavior.update(
            SM64UkikiInput(
                action: record.action,
                subAction: record.subAction,
                behaviorParam: record.behaviorParams2ndByte,
                textState: Int32(record.dialogState),
                hasHat: record.animationState == 2,
                heldState: Int32(record.heldState),
                distanceToMario: record.distanceToMario,
                angleToMario: record.angleToMario,
                moveYaw: record.moveAngles.yaw,
                positionY: record.position.y,
                marioHasHat: environment.marioHasHat,
                marioFarAway: environment.marioFarAway,
                floorAhead: environment.floorAhead,
                wallHit: environment.wallHit,
                edgeHit: environment.edgeHit,
                marioMovingFastOrInAir: environment.marioMovingFastOrInAir,
                animationNearEnd: environment.animationNearEnd,
                dialogResult: environment.dialogResult,
                canActivateText: environment.canActivateText,
                cageDistance: environment.cageDistance,
                cageYaw: environment.cageYaw,
                timer: record.timer,
                tauntCounter: 0,
                tauntsToBeDone: environment.tauntsToBeDone
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.subAction = output.subAction
            next.dialogState = Int16(clamping: Int(output.dialogID == 0 ? Int32(record.dialogState) : output.dialogID))
            next.animationState = output.animState
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.interactionSubtype = output.interactionSubtype | output.interactionMask
            next.intangibleTimer = output.intangible ? 1 : -1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.resetToHome { next.position = next.homePosition; next.velocity = .zero }
            if output.markForDeletion { next.activeFlags = 0 }
        }
        if output.markForDeletion { _ = engineState.objects.markForDeletion(id) }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        environments frameEnvironments: [SM64ObjectID: SM64UkikiEnvironment] = [:]
    ) -> SM64ObjectSchedulerTickResult {
        for (id, environment) in frameEnvironments { environments[id] = environment }
        beginExternalTick()
        let result = scheduler.update(state: engineState) { [weak self] id, _ in
            _ = self?.updateInline(id, state: engineState)
        }
        pruneExternal(unloaded: result.unloaded, pool: engineState.objects)
        return result
    }

    func remove(_ id: SM64ObjectID) { environments.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}

// MARK: - Ukiki cage owner bridge

struct SM64UkikiCageObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64UkikiCageOutput
}

final class SM64UkikiCageObjectBridge {
    static let cageBehaviorIdentity: UInt64 = 0x6268_765F_756B63
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_756B6373
    static let cageChildBehaviorIdentity: UInt64 = 0x6268_765F_756B6363
    static let defaultBehaviorIdentity: UInt64 = cageBehaviorIdentity

    private let scheduler: SM64ObjectScheduler
    private var starIDs: Set<SM64ObjectID> = []
    private var cageIDs: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64UkikiCageObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }
    var registeredIDs: [SM64ObjectID] { (cageIDs.union(starIDs)).sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnCage(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.cageBehaviorIdentity)
        guard attachCage(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Ukiki cage could not attach")
        }
        return id
    }

    @discardableResult
    func spawnStar(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.starBehaviorIdentity, parent: parent)
        guard attachStar(id, parent: parent, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Ukiki cage star could not attach")
        }
        return id
    }

    @discardableResult
    func attachCage(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        cageIDs.insert(id)
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            record.collisionDistance = 20_000
            record.gravity = -400
            record.buoyancy = 200
        }
        return true
    }

    @discardableResult
    func attachStar(_ id: SM64ObjectID, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        starIDs.insert(id)
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.parent = parent
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id) else { return false }
        let parent = engineState.objects.record(for: record.parent)
        let input = SM64UkikiCageInput(
            action: record.action,
            nextAction: record.subAction,
            parentAction: parent?.action ?? SM64UkikiCageBehavior.cageWaitForUkiki,
            parentPositionX: parent?.position.x ?? record.position.x,
            parentPositionY: parent?.position.y ?? record.position.y,
            parentPositionZ: parent?.position.z ?? record.position.z,
            parentBehaviorParams: parent?.behaviorParams ?? record.behaviorParams,
            moveYaw: record.moveAngles.yaw,
            faceYaw: record.faceAngles.yaw,
            landedOrWater: record.moveFlags != 0,
            timer: record.timer
        )
        let output = starIDs.contains(id)
            ? SM64UkikiCageBehavior.updateStar(input)
            : SM64UkikiCageBehavior.updateCage(input)
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.subAction = output.nextAction
            next.position = .init(x: output.positionX, y: output.positionY, z: output.positionZ)
            next.behaviorParams = output.behaviorParams
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.yaw = output.faceYaw
            next.graphFlags = output.hide ? next.graphFlags | 0x10 : next.graphFlags & ~UInt16(0x10)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        if output.markForDeletion { _ = engineState.objects.markForDeletion(id) }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    @discardableResult
    func tick(state engineState: SM64SwiftEngineState) -> SM64ObjectSchedulerTickResult {
        beginExternalTick()
        let result = scheduler.update(state: engineState) { [weak self] id, _ in _ = self?.updateInline(id, state: engineState) }
        pruneExternal(unloaded: result.unloaded, pool: engineState.objects)
        return result
    }

    func remove(_ id: SM64ObjectID) { cageIDs.remove(id); starIDs.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}

// MARK: - MIPS owner bridge

struct SM64MipsEnvironment: Equatable, Sendable {
    var nearbyMario = false
    var waypointAvailable = false
    var pathReachedEnd = false
    var animationNearEnd = false
    var grounded = false
    var underwater = false
    var dialogReady = false
    var dialogCompleted = false
}

struct SM64MipsObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MipsOutput
}

final class SM64MipsObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D6970
    private let scheduler: SM64ObjectScheduler
    private var environments: [SM64ObjectID: SM64MipsEnvironment] = [:]
    private(set) var effectLog: [SM64MipsObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }
    var registeredIDs: [SM64ObjectID] { environments.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        starCount: Int32 = 15,
        starFlags: UInt8 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, starCount: starCount, starFlags: starFlags, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned MIPS could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, starCount: Int32, starFlags: UInt8, position: SM64ObjectVector3 = .zero, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initialization = SM64MipsBehavior.initialize(starCount: starCount, starFlags: starFlags)
        environments[id] = SM64MipsEnvironment()
        _ = pool.mutate(id) { record in
            record.behaviorParams2ndByte = initialization.encounter
            record.forwardVelocity = initialization.forwardVelocity
            record.gravity = initialization.gravity
            record.friction = initialization.friction
            record.buoyancy = initialization.buoyancy
            record.interactionSubtype = initialization.interactionSubtype
            record.animationState = initialization.animation
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if !initialization.active { record.activeFlags = 0 }
        }
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64MipsEnvironment, for id: SM64ObjectID) -> Bool {
        guard environments[id] != nil else { return false }; environments[id] = environment; return true
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id), let environment = environments[id] else { return false }
        let output = SM64MipsBehavior.update(
            SM64MipsInput(
                action: record.action,
                heldState: Int32(record.heldState),
                encounter: record.behaviorParams2ndByte,
                starStatus: Int32(record.dialogState),
                forwardVelocity: record.forwardVelocity,
                nearbyMario: environment.nearbyMario,
                waypointAvailable: environment.waypointAvailable,
                pathReachedEnd: environment.pathReachedEnd,
                animationNearEnd: environment.animationNearEnd,
                grounded: environment.grounded,
                underwater: environment.underwater,
                dialogReady: environment.dialogReady,
                dialogCompleted: environment.dialogCompleted,
                timer: record.timer
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.heldState = UInt32(output.heldState)
            next.dialogState = Int16(output.starStatus)
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.animationState = output.animation
            next.interactionSubtype = output.interactionSubtype | output.interactionMask
            next.intangibleTimer = output.intangible ? 1 : -1
            next.graphFlags = output.hidden ? next.graphFlags | 0x10 : next.graphFlags & ~UInt16(0x10)
            if output.faceYawToMoveYaw { next.faceAngles.yaw = next.moveAngles.yaw }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    @discardableResult
    func tick(state engineState: SM64SwiftEngineState, environments frame: [SM64ObjectID: SM64MipsEnvironment] = [:]) -> SM64ObjectSchedulerTickResult {
        for (id, environment) in frame { environments[id] = environment }
        beginExternalTick()
        let result = scheduler.update(state: engineState) { [weak self] id, _ in _ = self?.updateInline(id, state: engineState) }
        pruneExternal(unloaded: result.unloaded, pool: engineState.objects)
        return result
    }
    func remove(_ id: SM64ObjectID) { environments.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}

// MARK: - Toad message owner bridge

struct SM64ToadMessageEnvironment: Equatable, Sendable {
    var distanceToMario: Float = .greatestFiniteMagnitude
    var interacted = false
    var dialogCompleted = false
    var renderActive = true
}

struct SM64ToadMessageObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ToadMessageOutput
}

final class SM64ToadMessageObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_746D73
    private let scheduler: SM64ObjectScheduler
    private var environments: [SM64ObjectID: SM64ToadMessageEnvironment] = [:]
    private(set) var effectLog: [SM64ToadMessageObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }
    var registeredIDs: [SM64ObjectID] { environments.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        dialogID: Int32,
        starCount: Int32 = 120,
        saveFlags: UInt32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, dialogID: dialogID, starCount: starCount, saveFlags: saveFlags, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Toad message could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, dialogID: Int32, starCount: Int32, saveFlags: UInt32, position: SM64ObjectVector3 = .zero, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initialization = SM64ToadMessageBehavior.initialize(dialogID: dialogID, starCount: starCount, saveFlags: saveFlags)
        environments[id] = SM64ToadMessageEnvironment()
        _ = pool.mutate(id) { record in
            record.dialogState = Int16(initialization.state)
            record.behaviorParams = initialization.dialogID << 24
            record.dialogResponse = initialization.recentlyTalked ? 1 : 0
            record.dialogState = Int16(initialization.state)
            record.opacity = initialization.opacity
            record.position = position
            record.homePosition = position
            record.interactionType = 0x0000_0004
            record.interactionSubtype = SM64ToadMessageBehavior.npcInteraction
            record.hitboxRadius = 80
            record.hitboxHeight = 100
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if !initialization.active { record.activeFlags = 0 }
        }
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64ToadMessageEnvironment, for id: SM64ObjectID) -> Bool {
        guard environments[id] != nil else { return false }; environments[id] = environment; return true
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id), let environment = environments[id] else { return false }
        let output = SM64ToadMessageBehavior.update(
            SM64ToadMessageInput(
                state: Int32(record.dialogState),
                dialogID: record.behaviorParams >> 24,
                recentlyTalked: record.dialogResponse != 0,
                opacity: record.opacity,
                distanceToMario: environment.distanceToMario,
                interacted: environment.interacted,
                dialogCompleted: environment.dialogCompleted,
                renderActive: environment.renderActive
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.dialogState = Int16(output.state)
            next.behaviorParams = (output.dialogID & 0xFF) << 24
            next.dialogResponse = output.recentlyTalked ? 1 : 0
            next.opacity = output.opacity
            next.interactionSubtype = output.interactionSubtype
            if output.clearInteraction { next.interactionStatus = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    @discardableResult
    func tick(state engineState: SM64SwiftEngineState, environments frame: [SM64ObjectID: SM64ToadMessageEnvironment] = [:]) -> SM64ObjectSchedulerTickResult {
        for (id, environment) in frame { environments[id] = environment }
        beginExternalTick()
        let result = scheduler.update(state: engineState) { [weak self] id, _ in _ = self?.updateInline(id, state: engineState) }
        pruneExternal(unloaded: result.unloaded, pool: engineState.objects)
        return result
    }
    func remove(_ id: SM64ObjectID) { environments.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}

// MARK: - File-select menu owner bridge

struct SM64MenuButtonObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MenuButtonOutput
}

struct SM64MenuButtonManagerObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MenuButtonManagerOutput
}

final class SM64MenuButtonObjectBridge {
    static let buttonBehaviorIdentity: UInt64 = 0x6268_765F_6D6274
    static let managerBehaviorIdentity: UInt64 = 0x6268_765F_6D626D
    static let defaultBehaviorIdentity: UInt64 = buttonBehaviorIdentity
    private let scheduler: SM64ObjectScheduler
    private var buttonIDs: Set<SM64ObjectID> = []
    private var managerIDs: Set<SM64ObjectID> = []
    private(set) var buttonEffectLog: [SM64MenuButtonObjectEffect] = []
    private(set) var managerEffectLog: [SM64MenuButtonManagerObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }
    var registeredIDs: [SM64ObjectID] { (buttonIDs.union(managerIDs)).sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { buttonEffectLog.removeAll(keepingCapacity: true); managerEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnButton(in engineState: SM64SwiftEngineState, relativePosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.buttonBehaviorIdentity)
        guard attachButton(id, relativePosition: relativePosition, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned menu button could not attach")
        }
        return id
    }

    @discardableResult
    func spawnManager(in engineState: SM64SwiftEngineState) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.managerBehaviorIdentity)
        guard attachManager(id, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned menu manager could not attach")
        }
        return id
    }

    @discardableResult
    func attachButton(_ id: SM64ObjectID, relativePosition: SM64ObjectVector3 = .zero, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        buttonIDs.insert(id)
        _ = pool.mutate(id) { record in
            record.parentRelativePosition = relativePosition
            record.position = relativePosition
            record.scale = .one
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func attachManager(_ id: SM64ObjectID, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        managerIDs.insert(id)
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState, legacyDomainAdvances: Bool = true) -> Bool {
        guard let record = engineState.objects.record(for: id) else { return false }
        if managerIDs.contains(id) {
            let output = SM64MenuButtonManagerBehavior.update(.init(selectedButtonID: record.action, legacyDomainAdvances: legacyDomainAdvances))
            managerEffectLog.append(.init(objectID: id, output: output))
            return true
        }
        guard buttonIDs.contains(id) else { return false }
        let output = SM64MenuButtonBehavior.update(
            SM64MenuButtonInput(
                state: record.action,
                timer: record.timer,
                menuLevel: record.behaviorParams2ndByte,
                originalX: record.homePosition.x,
                originalY: record.homePosition.y,
                originalZ: record.homePosition.z,
                relativeX: record.parentRelativePosition.x,
                relativeY: record.parentRelativePosition.y,
                relativeZ: record.parentRelativePosition.z,
                facePitch: record.faceAngles.pitch,
                faceYaw: record.faceAngles.yaw,
                scale: record.scale.x,
                legacyDomainAdvances: legacyDomainAdvances
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.action = output.state
            next.timer = output.timer
            next.homePosition = .init(x: output.originalX, y: output.originalY, z: output.originalZ)
            next.parentRelativePosition = .init(x: output.relativeX, y: output.relativeY, z: output.relativeZ)
            next.faceAngles.pitch = output.facePitch
            next.faceAngles.yaw = output.faceYaw
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        buttonEffectLog.append(.init(objectID: id, output: output))
        return true
    }

    @discardableResult
    func tick(state engineState: SM64SwiftEngineState, legacyDomainAdvances: Bool = true) -> SM64ObjectSchedulerTickResult {
        beginExternalTick()
        let result = scheduler.update(state: engineState) { [weak self] id, _ in _ = self?.updateInline(id, state: engineState, legacyDomainAdvances: legacyDomainAdvances) }
        pruneExternal(unloaded: result.unloaded, pool: engineState.objects)
        return result
    }
    func remove(_ id: SM64ObjectID) { buttonIDs.remove(id); managerIDs.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}

// The C behavior table exposes these as separate identities even where their
// state ownership is shared. Type aliases keep that identity-level naming
// available to the central dispatch integration without duplicating storage.
typealias SM64MacroUkikiObjectBridge = SM64UkikiObjectBridge
typealias SM64UkikiCageStarObjectBridge = SM64UkikiCageObjectBridge
typealias SM64MenuButtonManagerObjectBridge = SM64MenuButtonObjectBridge
