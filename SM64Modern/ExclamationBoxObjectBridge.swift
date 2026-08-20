import Foundation

struct SM64ExclamationBoxObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ExclamationBoxOutput
    let rotatingMarkID: SM64ObjectID?
}

final class SM64ExclamationBoxObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_657862

    private struct State {
        var saveCollected: Bool
        var overrideActive: Bool
        var attacked: Bool
        var phase: Int32
    }

    private let rotatingMarkBridge: SM64RotatingExclamationMarkObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ExclamationBoxObjectEffectRecord] = []

    init(rotatingMarkBridge: SM64RotatingExclamationMarkObjectBridge? = nil) {
        self.rotatingMarkBridge = rotatingMarkBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, behaviorByte: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, behaviorByte: behaviorByte, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned exclamation box could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, behaviorByte: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(saveCollected: false, overrideActive: false, attacked: false, phase: 0)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position
            record.behaviorParams2ndByte = behaviorByte; record.model = 0x89
            record.hitboxRadius = 40; record.hitboxHeight = 30
            record.collisionDistance = 300; record.intangibleTimer = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInputs(for id: SM64ObjectID, saveCollected: Bool? = nil, overrideActive: Bool? = nil, attacked: Bool? = nil) -> Bool {
        guard var state = states[id] else { return false }
        if let saveCollected { state.saveCollected = saveCollected }
        if let overrideActive { state.overrideActive = overrideActive }
        if let attacked { state.attacked = attacked }
        states[id] = state; return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64ExclamationBoxBehavior.update(.init(action: record.action, timer: record.timer, behaviorByte: record.behaviorParams2ndByte, saveCollected: state.saveCollected, overrideActive: state.overrideActive, attacked: state.attacked, phase: state.phase))
        state.attacked = false; state.phase = output.phase; states[id] = state
        var rotatingMarkID: SM64ObjectID?
        if output.spawnRotatingMark, let rotatingMarkBridge {
            rotatingMarkID = try? rotatingMarkBridge.spawnMark(in: engineState, parent: id, moveYaw: record.faceAngles.yaw)
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action; next.timer = output.timer; next.animationState = output.animationState
            next.model = output.model; next.graphYOffset = output.graphYOffset
            next.scale = .init(x: output.scaleX, y: output.scaleY, z: output.scaleX)
            next.velocity.y = output.velocityY; next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10
            next.intangibleTimer = output.tangible ? 0 : -1; next.interactionStatus = 0
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, rotatingMarkID: rotatingMarkID)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
