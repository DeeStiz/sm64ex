import Foundation

struct SM64BowserFlameSpawnObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BowserFlameSpawnOutput; let spawnedFlame: SM64ObjectID? }

final class SM64BowserFlameSpawnObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62667370
    private struct State { let bowserObject: SM64ObjectID; let animationEndFrame: Int32; let sampleX: Float; let sampleY: Float; let sampleZ: Float; let samplePitch: Int32; let sampleYaw: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BowserFlameSpawnObjectEffectRecord] = []
    private let movingFlameBridge: SM64FlameMovingForwardGrowingObjectBridge
    init(movingFlameBridge: SM64FlameMovingForwardGrowingObjectBridge) { self.movingFlameBridge = movingFlameBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, bowserObject: SM64ObjectID, animationEndFrame: Int32 = 100, sampleX: Float = 0, sampleY: Float = 0, sampleZ: Float = 0, samplePitch: Int32 = 0, sampleYaw: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity, parent: bowserObject)
        guard attach(id, bowserObject: bowserObject, animationEndFrame: animationEndFrame, sampleX: sampleX, sampleY: sampleY, sampleZ: sampleZ, samplePitch: samplePitch, sampleYaw: sampleYaw, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Bowser flame spawner could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, bowserObject: SM64ObjectID, animationEndFrame: Int32, sampleX: Float, sampleY: Float, sampleZ: Float, samplePitch: Int32, sampleYaw: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; states[id] = State(bowserObject: bowserObject, animationEndFrame: animationEndFrame, sampleX: sampleX, sampleY: sampleY, sampleZ: sampleZ, samplePitch: samplePitch, sampleYaw: sampleYaw); return pool.mutate(id) { record in record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BowserFlameSpawnObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id), let bowser = engineState.objects.record(for: state.bowserObject) else { return nil }
        let output = SM64BowserFlameSpawnBehavior.update(.init(objectPosition: record.position, bowserPosition: bowser.position, bowserYaw: bowser.moveAngles.yaw, bowserSoundState: bowser.soundStateID, animationFrame: record.animationState, animationEndFrame: state.animationEndFrame, sampleX: state.sampleX, sampleY: state.sampleY, sampleZ: state.sampleZ, samplePitch: state.samplePitch, sampleYaw: state.sampleYaw))
        var child: SM64ObjectID?
        if output.shouldSpawnFlame { child = try? movingFlameBridge.spawnFlame(in: engineState, position: output.position, moveYaw: output.moveYaw, movePitch: output.movePitch) }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.moveAngles.pitch = output.movePitch; next.animationState &+= 1 }
        let effect = SM64BowserFlameSpawnObjectEffectRecord(objectID: id, output: output, spawnedFlame: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
