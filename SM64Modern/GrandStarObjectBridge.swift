import Foundation

struct SM64GrandStarObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64GrandStarOutput }
final class SM64GrandStarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_677374
    private var registered: Set<SM64ObjectID> = []; private(set) var effectLog: [SM64GrandStarObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, homeY: Float = 0) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity); guard attach(id, position: position, homeY: homeY, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned grand star could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, homeY: Float, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; registered.insert(id); return pool.mutate(id) { record in record.position = position; record.homePosition.y = homeY; record.hitboxRadius = 160; record.hitboxHeight = 100; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }; let output = SM64GrandStarBehavior.update(.init(action: record.action, timer: record.timer, subAction: record.subAction, position: record.position, homeY: record.homePosition.y, velocityY: record.velocity.y, forwardVelocity: record.forwardVelocity, yaw: record.faceAngles.yaw, angleVelocityYaw: record.angleVelocity.yaw, interacted: record.interactionStatus != 0)); _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.subAction = output.subAction; next.position = output.position; next.velocity.y = output.velocityY; next.forwardVelocity = output.forwardVelocity; next.faceAngles.yaw = output.yaw; next.angleVelocity.yaw = output.angleVelocityYaw; next.intangibleTimer = output.tangible ? 0 : -1; if output.shouldDelete { next.activeFlags = 0 } }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
