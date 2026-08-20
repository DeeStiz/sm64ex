import Foundation

struct SM64FlameMovingForwardGrowingObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64FlameMovingForwardGrowingOutput; let spawnedBowserFlame: SM64ObjectID? }

final class SM64FlameMovingForwardGrowingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_666D67
    private struct State { let moveYaw: Int32; var movePitch: Int32; let forwardVelocity: Float; var scaleFactor: Float; let initialOffset: SM64ObjectVector3; let floorHeight: Float; let initialAnimationState: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FlameMovingForwardGrowingObjectEffectRecord] = []
    private let bowserFlameBridge: SM64BowserFlameObjectBridge
    init(bowserFlameBridge: SM64BowserFlameObjectBridge) { self.bowserFlameBridge = bowserFlameBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, movePitch: Int32 = 0, forwardVelocity: Float = 30, scaleFactor: Float = 3, initialOffset: SM64ObjectVector3 = .zero, floorHeight: Float = 0, initialAnimationState: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, movePitch: movePitch, forwardVelocity: forwardVelocity, scaleFactor: scaleFactor, initialOffset: initialOffset, floorHeight: floorHeight, initialAnimationState: initialAnimationState, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned growing flame could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, movePitch: Int32, forwardVelocity: Float, scaleFactor: Float, initialOffset: SM64ObjectVector3, floorHeight: Float, initialAnimationState: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, movePitch: movePitch, forwardVelocity: forwardVelocity, scaleFactor: scaleFactor, initialOffset: initialOffset, floorHeight: floorHeight, initialAnimationState: initialAnimationState)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.moveAngles.pitch = movePitch; record.forwardVelocity = forwardVelocity; record.scale = .init(x: scaleFactor, y: scaleFactor, z: scaleFactor); record.interactionType = 1; record.hitboxRadius = 50; record.hitboxHeight = 25; record.hitboxDownOffset = 25; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FlameMovingForwardGrowingObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FlameMovingForwardGrowingBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, movePitch: state.movePitch, forwardVelocity: state.forwardVelocity, scaleFactor: state.scaleFactor, timer: record.timer, animationState: record.animationState, initialOffset: state.initialOffset, floorHeight: state.floorHeight, initialAnimationState: state.initialAnimationState, floorBelowPosition: record.floorHeight > record.position.y))
        state.movePitch = output.movePitch; state.scaleFactor = output.scaleFactor; states[id] = state
        var child: SM64ObjectID?
        if output.spawnBowserFlame { child = try? bowserFlameBridge.spawnFlame(in: engineState, kind: .normal, position: output.position) }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.pitch = output.movePitch; next.scale = .init(x: output.scaleFactor, y: output.scaleFactor, z: output.scaleFactor); next.animationState = output.animationState; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64FlameMovingForwardGrowingObjectEffectRecord(objectID: id, output: output, spawnedBowserFlame: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
