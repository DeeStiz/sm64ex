import Foundation

struct SM64BlueFlamesGroupObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BlueFlamesGroupOutput
    let spawnedFlames: [SM64ObjectID]
}

final class SM64BlueFlamesGroupObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626667
    private let flameBridge: SM64FlameBouncingObjectBridge
    private struct State { let moveYaw: Int32; var scale: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BlueFlamesGroupObjectEffectRecord] = []

    init(flameBridge: SM64FlameBouncingObjectBridge) { self.flameBridge = flameBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnGroup(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, scale: Float = 5) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, scale: scale, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned blue-flame group could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, scale: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, scale: scale)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.scale = .init(x: scale, y: scale, z: scale); record.interactionType = 1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BlueFlamesGroupObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BlueFlamesGroupBehavior.update(.init(position: record.position, timer: record.timer, moveYaw: state.moveYaw, scale: state.scale))
        var spawned: [SM64ObjectID] = []
        if output.spawnCount > 0 {
            for index in 0..<Int(output.spawnCount) {
                let yaw = output.moveYaw &+ Int32(index * 0x5555)
                if let flame = try? flameBridge.spawnFlame(in: engineState, position: output.position, moveYaw: yaw, initialScale: output.scale) { spawned.append(flame) }
            }
            state.scale -= 0.5
            states[id] = state
        }
        _ = engineState.objects.mutate(id) { next in next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 } }
        let effect = SM64BlueFlamesGroupObjectEffectRecord(objectID: id, output: output, spawnedFlames: spawned); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
