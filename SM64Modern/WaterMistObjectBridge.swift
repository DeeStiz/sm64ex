import Foundation

struct SM64WaterMistObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterMistOutput
}

final class SM64WaterMistObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_776D73
    private struct State { var opacity: Int32; var timer: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaterMistObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnMist(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, randomOffsetX: Float = 0, randomOffsetZ: Float = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, randomOffsetX: randomOffsetX, randomOffsetZ: randomOffsetZ, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned water mist could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, randomOffsetX: Float, randomOffsetZ: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(opacity: 254, timer: 0)
        return pool.mutate(id) { record in record.position = position; record.moveAngles.yaw = moveYaw; record.behaviorParams = Int32(bitPattern: randomOffsetX.bitPattern); record.behaviorParams2ndByte = Int32(bitPattern: randomOffsetZ.bitPattern); record.forwardVelocity = 20; record.velocity.y = -8; record.opacity = 254; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64WaterMistObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64WaterMistBehavior.update(SM64WaterMistInput(position: record.position, moveYaw: record.moveAngles.yaw, forwardVelocity: record.forwardVelocity, velocityY: record.velocity.y, opacity: state.opacity, timer: state.timer, randomOffsetX: Float(bitPattern: UInt32(bitPattern: record.behaviorParams)), randomOffsetZ: Float(bitPattern: UInt32(bitPattern: record.behaviorParams2ndByte))))
        state.opacity = output.opacity; state.timer &+= 1; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.opacity = output.opacity; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.timer = state.timer; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform; if output.shouldDelete { next.activeFlags = 0 } }
        let effect = SM64WaterMistObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
