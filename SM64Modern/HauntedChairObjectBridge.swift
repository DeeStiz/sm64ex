import Foundation

struct SM64HauntedChairObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HauntedChairOutput
}

final class SM64HauntedChairObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_686368
    private struct State { var hasPianoParent: Bool; var nearPiano: Bool; var distanceToMario: Float; var launchCountdown: Int32; var hitGroundOrWall: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64HauntedChairObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnChair(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hasPianoParent: Bool = false) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.interactionType = 1 << 17; record.damageOrCoinValue = 2; record.hitboxRadius = 50; record.hitboxHeight = 50; record.hurtboxRadius = 50; record.hurtboxHeight = 50; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned haunted chair could not attach") }
        states[id] = State(hasPianoParent: hasPianoParent, nearPiano: false, distanceToMario: 10_000, launchCountdown: hasPianoParent ? 0 : 1, hitGroundOrWall: false)
        return id
    }

    @discardableResult
    func setInput(nearPiano: Bool? = nil, distanceToMario: Float? = nil, launchCountdown: Int32? = nil, hitGroundOrWall: Bool? = nil, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        if let nearPiano { state.nearPiano = nearPiano }
        if let distanceToMario { state.distanceToMario = distanceToMario }
        if let launchCountdown { state.launchCountdown = launchCountdown }
        if let hitGroundOrWall { state.hitGroundOrWall = hitGroundOrWall }
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64HauntedChairBehavior.update(.init(action: record.action, timer: record.timer, position: record.position, velocityY: record.velocity.y, forwardVelocity: record.forwardVelocity, hasPianoParent: state.hasPianoParent, nearPiano: state.nearPiano, distanceToMario: state.distanceToMario, launchCountdown: state.launchCountdown, hitGroundOrWall: state.hitGroundOrWall))
        state.launchCountdown = output.launchCountdown; state.nearPiano = false; state.hitGroundOrWall = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.velocity.y = output.velocityY; next.forwardVelocity = output.forwardVelocity; next.faceAngles.pitch = output.facePitch; next.faceAngles.roll = output.faceRoll; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform; if output.shouldDelete { next.activeFlags = 0 } }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
