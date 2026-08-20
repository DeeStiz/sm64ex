import Foundation

struct SM64KickableBoardObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64KickableBoardOutput }

final class SM64KickableBoardObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6B6264
    private struct State { var attacked: Bool; var attackType: Int32; var attackAbove: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64KickableBoardObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.interactionType = 1; record.hitboxRadius = 100; record.hitboxHeight = 100; record.collisionDistance = 4_000; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned kickable board could not attach") }
        states[id] = State(attacked: false, attackType: 0, attackAbove: false)
        return id
    }

    @discardableResult
    func setInput(attacked: Bool, attackType: Int32 = 1, attackAboveBoard: Bool = false, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        states[id] = State(attacked: attacked, attackType: attackType, attackAbove: attackAboveBoard)
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64KickableBoardBehavior.update(.init(action: record.action, timer: record.timer, phase: record.behaviorParams, rockSpeed: record.forwardVelocity == 0 ? 1600 : record.forwardVelocity, facePitch: record.faceAngles.pitch, angleVelocityPitch: record.angleVelocity.pitch, attacked: state.attacked, attackType: state.attackType, attackAboveBoard: state.attackAbove))
        state.attacked = false; state.attackType = 0; state.attackAbove = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.behaviorParams = output.phase; next.forwardVelocity = output.rockSpeed; next.faceAngles.pitch = output.facePitch; next.angleVelocity.pitch = output.angleVelocityPitch; next.intangibleTimer = output.tangible ? -1 : 1; next.model = output.fellModel ? 0x40 : next.model; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
