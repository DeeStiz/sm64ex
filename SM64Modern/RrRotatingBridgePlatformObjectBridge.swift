import Foundation

struct SM64RrRotatingBridgePlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let rotation: SM64RrRotatingBridgePlatformOutput
    let flamethrower: SM64FlamethrowerObjectEffectRecord?
}

final class SM64RrRotatingBridgePlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_727262
    private let flameBridge: SM64FlamethrowerObjectBridge
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64RrRotatingBridgePlatformObjectEffectRecord] = []

    init(flameBridge: SM64FlamethrowerObjectBridge) { self.flameBridge = flameBridge }
    var registeredIDs: [SM64ObjectID] { registered.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0, distanceToMario: Float = .greatestFiniteMagnitude, activationAllowed: Bool = true) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard flameBridge.attach(id, position: position, behaviorParam: behaviorParam, distanceToMario: distanceToMario, activationAllowed: activationAllowed, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned RR rotating bridge platform could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let rotation = SM64RrRotatingBridgePlatformBehavior.update(.init(moveYaw: record.moveAngles.yaw))
        _ = engineState.objects.mutate(id) { next in next.moveAngles.yaw = rotation.moveYaw; next.angleVelocity.yaw = rotation.angleVelocityYaw }
        let flame = flameBridge.updateInline(id, state: engineState)
        effectLog.append(.init(objectID: id, rotation: rotation, flamethrower: flame)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
