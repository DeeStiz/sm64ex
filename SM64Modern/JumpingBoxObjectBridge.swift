import Foundation

struct SM64JumpingBoxObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64JumpingBoxOutput }

final class SM64JumpingBoxObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6A626F
    private struct State { var countdown: Int32; let threshold: Int32; var marioPosition: SM64ObjectVector3; var onGround: Bool; var hitWall: Bool; var inWater: Bool; var landed: Bool; var stopRiding: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64JumpingBoxObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, threshold: Int32 = 60) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .destructive, model: 0x3B, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.hitboxRadius = 150; record.hitboxHeight = 250; record.hurtboxRadius = 150; record.hurtboxHeight = 250; record.interactionType = 1; record.damageOrCoinValue = 0; record.health = 1; record.numLootCoins = 5; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned jumping box could not attach") }
        states[id] = State(countdown: 30, threshold: threshold, marioPosition: .zero, onGround: false, hitWall: false, inWater: false, landed: false, stopRiding: false)
        return id
    }

    @discardableResult
    func setInput(marioPosition: SM64ObjectVector3? = nil, onGround: Bool? = nil, hitWall: Bool? = nil, inWater: Bool? = nil, landed: Bool? = nil, stopRiding: Bool? = nil, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        if let marioPosition { state.marioPosition = marioPosition }; if let onGround { state.onGround = onGround }; if let hitWall { state.hitWall = hitWall }; if let inWater { state.inWater = inWater }; if let landed { state.landed = landed }; if let stopRiding { state.stopRiding = stopRiding }; states[id] = state; return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64JumpingBoxBehavior.update(.init(action: record.action, timer: record.timer, subAction: record.subAction, heldState: record.heldState, position: record.position, marioPosition: state.marioPosition, velocityY: record.velocity.y, countdown: state.countdown, threshold: state.threshold, onGround: state.onGround, hitWall: state.hitWall, inWater: state.inWater, landed: state.landed, stopRiding: state.stopRiding))
        state.countdown = output.countdown; state.onGround = false; state.hitWall = false; state.inWater = false; state.landed = false; state.stopRiding = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.subAction = output.subAction; next.position = output.position; next.velocity.y = output.velocityY; next.model = output.model; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | UInt16(0x10); if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
