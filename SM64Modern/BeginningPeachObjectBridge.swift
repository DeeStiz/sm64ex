import Foundation

struct SM64BeginningPeachObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BeginningPeachOutput
}

final class SM64BeginningPeachObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_627063
    static let defaultModel: UInt32 = 0x53
    private var cameraTargetPositions: [SM64ObjectID: SM64ObjectVector3] = [:]
    private var dialogIDs: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64BeginningPeachObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { cameraTargetPositions.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPeach(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, cameraTargetPosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, cameraTargetPosition: cameraTargetPosition, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned beginning Peach could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, cameraTargetPosition: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        cameraTargetPositions[id] = cameraTargetPosition
        dialogIDs[id] = -1
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.opacity = 255
            record.animationState = 100
            record.faceAngles = .init(pitch: 0x400, yaw: 0x7500, roll: -0x3700)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInput(cameraTargetPosition: SM64ObjectVector3? = nil, dialogID: Int32? = nil, for id: SM64ObjectID) -> Bool {
        guard cameraTargetPositions[id] != nil else { return false }
        if let cameraTargetPosition { cameraTargetPositions[id] = cameraTargetPosition }
        if let dialogID { dialogIDs[id] = dialogID }
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id), let target = cameraTargetPositions[id] else { return false }
        let output = SM64BeginningPeachBehavior.update(.init(action: record.action, timer: record.timer, opacity: record.opacity, position: record.position, cameraTargetPosition: target, dialogID: dialogIDs[id] ?? -1))
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.opacity = output.opacity
            next.position = output.position
            next.faceAngles = output.faceAngles
            next.animationState = output.animationFrame
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { cameraTargetPositions.removeValue(forKey: id); dialogIDs.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
