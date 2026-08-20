import Foundation
struct SM64NormalCapObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64NormalCapOutput }
final class SM64NormalCapObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6E636170
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64NormalCapObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0, course: SM64NormalCapCourse = .other) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.forwardVelocity = forwardVelocity; record.behaviorParams = course.rawValue; record.gravity = 0.7; record.friction = 0.89; record.buoyancy = 0.9; record.opacity = 255; record.hitboxRadius = 80; record.hitboxHeight = 80; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned normal cap could not attach") }
        registered.insert(id); return id
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let course = SM64NormalCapCourse(rawValue: record.behaviorParams) ?? .other
        let output = SM64NormalCapBehavior.update(.init(action: record.action, timer: record.timer, faceYaw: record.faceAngles.yaw, facePitch: record.faceAngles.pitch, forwardVelocity: record.forwardVelocity, verticalVelocity: record.velocity.y, capPhase: record.subAction, floorLanded: (record.moveFlags & 1) != 0, interacted: record.interactionStatus != 0, deactivated: record.activeFlags == 0, course: course))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.faceAngles.yaw = output.faceYaw; next.faceAngles.pitch = output.facePitch; next.velocity.y = output.verticalVelocity; next.subAction = output.capPhase; next.gravity = output.gravity; next.friction = output.friction; next.buoyancy = output.buoyancy; next.opacity = output.opacity; next.hitboxRadius = 80; next.hitboxHeight = 80; next.interactionStatus = 0; if output.deactivated { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
