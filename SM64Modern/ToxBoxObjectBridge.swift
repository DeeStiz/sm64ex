import Foundation

struct SM64ToxBoxObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64ToxBoxOutput }

final class SM64ToxBoxObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_746F78
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64ToxBoxObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, initialDirectionAction: Int32 = 4, nextDirectionAction: Int32 = 4, behaviorVariant: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in
            record.position = position; record.homePosition = position; record.action = 0; record.timer = 0; record.behaviorParams = initialDirectionAction; record.behaviorParams2ndByte = nextDirectionAction; record.subAction = behaviorVariant; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Tox Box could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64ToxBoxBehavior.update(.init(action: record.action, timer: record.timer, positionY: record.position.y, homeY: record.homePosition.y, facePitch: record.faceAngles.pitch, faceRoll: record.faceAngles.roll, initialDirectionAction: record.behaviorParams, nextDirectionAction: record.behaviorParams2ndByte, behaviorVariant: record.subAction))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.position.y = output.positionY; next.forwardVelocity = output.forwardVelocity; next.faceAngles.pitch = output.facePitch; next.faceAngles.roll = output.faceRoll; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
