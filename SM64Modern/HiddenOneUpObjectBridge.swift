import Foundation

struct SM64HiddenOneUpObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HiddenOneUpOutput
    let targetID: SM64ObjectID?
    let spawnedChildren: [SM64ObjectID]
}

final class SM64HiddenOneUpObjectBridge {
    static let hiddenBehaviorIdentity: UInt64 = 0x6268_765F_683175
    static let triggerBehaviorIdentity: UInt64 = 0x6268_765F_683174
    static let hiddenInPoleBehaviorIdentity: UInt64 = 0x6268_765F_683170
    static let poleTriggerBehaviorIdentity: UInt64 = 0x6268_765F_683171
    static let poleSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_683173
    static let oneUpBehaviorIdentity: UInt64 = 0x6268_765F_317570
    static let walkingBehaviorIdentity: UInt64 = 0x6268_765F_317761
    static let runningAwayBehaviorIdentity: UInt64 = 0x6268_765F_317261
    static let slidingBehaviorIdentity: UInt64 = 0x6268_765F_31736C
    static let jumpOnApproachBehaviorIdentity: UInt64 = 0x6268_765F_31736A

    private struct State {
        let role: SM64HiddenOneUpRole
        var behaviorByte: Int32
        var triggerCount: Int32
        var touchedMario: Bool
        var marioNear: Bool
        var outsideRange: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64HiddenOneUpObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        role: SM64HiddenOneUpRole,
        behaviorByte: Int32 = 0,
        triggerCount: Int32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            behaviorIdentity: Self.identity(for: role)
        )
        guard attach(
            id,
            role: role,
            behaviorByte: behaviorByte,
            triggerCount: triggerCount,
            position: position,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned hidden one-up could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        role: SM64HiddenOneUpRole,
        behaviorByte: Int32,
        triggerCount: Int32 = 0,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            role: role,
            behaviorByte: behaviorByte,
            triggerCount: triggerCount,
            touchedMario: false,
            marioNear: false,
            outsideRange: false
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = behaviorByte
            record.action = 0
            record.timer = 0
            record.hitboxRadius = role == .trigger || role == .poleTrigger ? 100 : 30
            record.hitboxHeight = role == .trigger || role == .poleTrigger ? 100 : 30
            record.interactionType = role == .trigger || role == .poleTrigger ? (1 << 4) : (1 << 3)
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setTouchedMario(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.touchedMario = value
        states[id] = state
        return true
    }

    @discardableResult
    func setMarioNear(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.marioNear = value
        states[id] = state
        return true
    }

    @discardableResult
    func setOutsideRange(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.outsideRange = value
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return false
        }
        let target = state.role == .trigger || state.role == .poleTrigger
            ? nearestTarget(for: state.role, from: record.position, excluding: id, in: engineState.objects)
            : nil
        let output = SM64HiddenOneUpBehavior.update(
            .init(
                role: state.role,
                action: record.action,
                timer: record.timer,
                behaviorByte: state.behaviorByte,
                triggerCount: state.triggerCount,
                touchedMario: state.touchedMario,
                marioNear: state.marioNear,
                outsideRange: state.outsideRange,
                pitch: record.moveAngles.pitch,
                forwardVelocity: record.forwardVelocity
            )
        )
        state.touchedMario = false
        state.marioNear = false
        state.outsideRange = false
        states[id] = state

        var children: [SM64ObjectID] = []
        if output.consumeTrigger, let target {
            incrementTriggerCount(for: target)
        }
        if output.spawnPoleChildren {
            if let child = try? spawn(
                in: engineState,
                role: .hiddenInPole,
                behaviorByte: 2,
                position: SM64ObjectVector3(x: record.position.x, y: record.position.y + 50, z: record.position.z)
            ) {
                children.append(child)
            }
            for index in 0..<2 {
                if let trigger = try? spawn(
                    in: engineState,
                    role: .poleTrigger,
                    behaviorByte: 0,
                    position: SM64ObjectVector3(x: record.position.x, y: record.position.y, z: record.position.z - Float(index * 200))
                ) {
                    children.append(trigger)
                }
            }
        }

        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.moveAngles.pitch = output.pitch
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.verticalVelocity
            next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10
            next.intangibleTimer = output.tangible ? 0 : -1
            next.interactionStatus = 0
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, targetID: target, spawnedChildren: children))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }

    static func identity(for role: SM64HiddenOneUpRole) -> UInt64 {
        switch role {
        case .hidden: return hiddenBehaviorIdentity
        case .trigger: return triggerBehaviorIdentity
        case .hiddenInPole: return hiddenInPoleBehaviorIdentity
        case .poleTrigger: return poleTriggerBehaviorIdentity
        case .poleSpawner: return poleSpawnerBehaviorIdentity
        case .oneUp: return oneUpBehaviorIdentity
        case .walking: return walkingBehaviorIdentity
        case .runningAway: return runningAwayBehaviorIdentity
        case .sliding: return slidingBehaviorIdentity
        case .jumpOnApproach: return jumpOnApproachBehaviorIdentity
        }
    }

    private func incrementTriggerCount(for id: SM64ObjectID) {
        guard var state = states[id] else { return }
        state.triggerCount &+= 1
        states[id] = state
    }

    private func nearestTarget(
        for role: SM64HiddenOneUpRole,
        from position: SM64ObjectVector3,
        excluding id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> SM64ObjectID? {
        let targetRole: SM64HiddenOneUpRole = role == .poleTrigger ? .hiddenInPole : .hidden
        var best: (distance: Float, id: SM64ObjectID)?
        for candidate in states.keys where candidate != id {
            guard let candidateState = states[candidate], candidateState.role == targetRole,
                  let record = pool.record(for: candidate) else { continue }
            let dx = record.position.x - position.x
            let dy = record.position.y - position.y
            let dz = record.position.z - position.z
            let distance = dx * dx + dy * dy + dz * dz
            if best == nil || distance < best!.distance { best = (distance, candidate) }
        }
        return best?.id
    }
}
