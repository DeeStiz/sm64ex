import Foundation

struct SM64CannonBarrelBubblesObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CannonBarrelBubblesOutput; let spawnedBomb: SM64ObjectID? }

final class SM64CannonBarrelBubblesObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636262
    private struct State { let parentPosition: SM64ObjectVector3; let relativePosition: SM64ObjectVector3; let parentFaceYaw: Int32; let parentMovePitch: Int32; let parentAction: Int32; let cannonActive: Bool; var accumulatedDistance: Float; var forwardVelocity: Float }
    private let waterBombBridge: SM64WaterBombObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CannonBarrelBubblesObjectEffectRecord] = []
    init(waterBombBridge: SM64WaterBombObjectBridge) { self.waterBombBridge = waterBombBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnBarrel(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, parentPosition: SM64ObjectVector3 = .zero, relativePosition: SM64ObjectVector3 = .zero, parentFaceYaw: Int32 = 0, parentMovePitch: Int32 = 0, parentAction: Int32 = 0, accumulatedDistance: Float = 0, forwardVelocity: Float = 0, cannonActive: Bool = false) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, parentPosition: parentPosition, relativePosition: relativePosition, parentFaceYaw: parentFaceYaw, parentMovePitch: parentMovePitch, parentAction: parentAction, accumulatedDistance: accumulatedDistance, forwardVelocity: forwardVelocity, cannonActive: cannonActive, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned cannon barrel bubbles could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, parentPosition: SM64ObjectVector3, relativePosition: SM64ObjectVector3, parentFaceYaw: Int32, parentMovePitch: Int32, parentAction: Int32, accumulatedDistance: Float, forwardVelocity: Float, cannonActive: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(parentPosition: parentPosition, relativePosition: relativePosition, parentFaceYaw: parentFaceYaw, parentMovePitch: parentMovePitch, parentAction: parentAction, cannonActive: cannonActive, accumulatedDistance: accumulatedDistance, forwardVelocity: forwardVelocity)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.forwardVelocity = forwardVelocity; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CannonBarrelBubblesObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64CannonBarrelBubblesBehavior.update(.init(position: record.position, parentPosition: state.parentPosition, relativePosition: state.relativePosition, parentFaceYaw: state.parentFaceYaw, parentMovePitch: state.parentMovePitch, parentAction: state.parentAction, accumulatedDistance: state.accumulatedDistance, forwardVelocity: state.forwardVelocity, cannonActive: state.cannonActive))
        state.accumulatedDistance = output.accumulatedDistance; state.forwardVelocity = output.forwardVelocity; states[id] = state
        var bomb: SM64ObjectID?
        if output.spawnBomb { bomb = try? waterBombBridge.spawnBomb(in: engineState, action: .initialize, positionX: output.bombPosition.x, positionY: output.bombPosition.y, positionZ: output.bombPosition.z, parent: id); if let bomb { _ = engineState.objects.mutate(bomb) { $0.forwardVelocity = -100; $0.scale.y = 1.7 } } }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.moveAngles.pitch = output.movePitch; next.faceAngles.pitch = output.facePitch; next.forwardVelocity = output.forwardVelocity; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64CannonBarrelBubblesObjectEffectRecord(objectID: id, output: output, spawnedBomb: bomb); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
