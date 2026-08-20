import Foundation

struct SM64ThiIslandTopObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64ThiIslandTopOutput }

final class SM64ThiIslandTopObjectBridge {
    static let hugeBehaviorIdentity: UInt64 = 0x6268_765F_746869
    static let tinyBehaviorIdentity: UInt64 = 0x6268_765F_747469
    private var roles: [SM64ObjectID: SM64ThiIslandTopRole] = [:]
    private(set) var effectLog: [SM64ThiIslandTopObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { roles.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, role: SM64ThiIslandTopRole, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let identity = role == .huge ? Self.hugeBehaviorIdentity : Self.tinyBehaviorIdentity
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: identity)
        guard engineState.objects.mutate(id, { record in
            record.position = position; record.homePosition = position; record.action = 0; record.timer = 0; record.behaviorParams = 0; record.behaviorParams2ndByte = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned THI island top could not attach") }
        roles[id] = role; return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let role = roles[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64ThiIslandTopBehavior.update(.init(role: role, action: record.action, timer: record.timer, waterDrained: record.behaviorParams != 0, distanceToMario: record.distanceToMario, marioGroundPound: record.behaviorParams2ndByte != 0))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.behaviorParams = output.waterDrained ? 1 : 0; next.activeParticleFlags = output.spawnParticles || output.spawnTriangleParticles ? 1 : 0; if output.hidden { next.graphFlags |= 0x10 }; if output.loadCollisionModel { next.collisionDataIdentity = 1 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { roles.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
