import Foundation

struct SM64SpindriftObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SpindriftOutput }

final class SM64SpindriftObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737064
    private struct State: Sendable { var lateralDistanceToHome: Float; var distanceToMario: Float; var angleToMario: Int32; var angleToHome: Int32; var attacked: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SpindriftObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.hitboxRadius = 90; record.hitboxHeight = 80; record.damageOrCoinValue = 2; record.health = 1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Spindrift could not attach") }
        states[id] = State(lateralDistanceToHome: 0, distanceToMario: 10_000, angleToMario: 0, angleToHome: 0, attacked: false); return id
    }

    @discardableResult
    func setInput(lateralDistanceToHome: Float = 0, distanceToMario: Float = 10_000, angleToMario: Int32 = 0, angleToHome: Int32 = 0, attacked: Bool = false, for id: SM64ObjectID) -> Bool { guard states[id] != nil else { return false }; states[id] = State(lateralDistanceToHome: lateralDistanceToHome, distanceToMario: distanceToMario, angleToMario: angleToMario, angleToHome: angleToHome, attacked: attacked); return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SpindriftBehavior.update(.init(action: record.action, timer: record.timer, position: record.position, homePosition: record.homePosition, moveYaw: record.moveAngles.yaw, forwardVelocity: record.forwardVelocity, lateralDistanceToHome: state.lateralDistanceToHome, distanceToMario: state.distanceToMario, angleToMario: state.angleToMario, angleToHome: state.angleToHome, attacked: state.attacked))
        states[id] = State(lateralDistanceToHome: 0, distanceToMario: 10_000, angleToMario: 0, angleToHome: 0, attacked: false)
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.forwardVelocity = output.forwardVelocity; next.intangibleTimer = output.interactable ? 0 : 1; next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight; next.damageOrCoinValue = output.damageOrCoinValue; next.health = output.health; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
