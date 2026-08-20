import Foundation

struct SM64FlamethrowerObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64FlamethrowerOutput; let spawnedFlame: SM64ObjectID? }

final class SM64FlamethrowerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_667468
    private struct State { let behaviorParam: Int32; let distanceToMario: Float; let activationAllowed: Bool; var action: Int32; var timer: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FlamethrowerObjectEffectRecord] = []
    private let flameBridge: SM64FlamethrowerFlameObjectBridge
    init(flameBridge: SM64FlamethrowerFlameObjectBridge) { self.flameBridge = flameBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnFlamethrower(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0, distanceToMario: Float = .greatestFiniteMagnitude, activationAllowed: Bool = true) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, behaviorParam: behaviorParam, distanceToMario: distanceToMario, activationAllowed: activationAllowed, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned flamethrower could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, behaviorParam: Int32, distanceToMario: Float, activationAllowed: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; states[id] = State(behaviorParam: behaviorParam, distanceToMario: distanceToMario, activationAllowed: activationAllowed, action: 0, timer: 0); return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.behaviorParams2ndByte = behaviorParam; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FlamethrowerObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FlamethrowerBehavior.update(.init(position: record.position, action: state.action, timer: state.timer, behaviorParam: state.behaviorParam, distanceToMario: state.distanceToMario, activationAllowed: state.activationAllowed))
        state.action = output.action; state.timer = output.timer; states[id] = state
        var child: SM64ObjectID?
        if output.spawnFlame { child = try? flameBridge.spawnFlame(in: engineState, position: output.position, forwardVelocity: output.flameVelocity, behaviorParam: output.flameBehaviorParam, parentLifetime: output.flameLifetime, parent: id) }
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer }
        let effect = SM64FlamethrowerObjectEffectRecord(objectID: id, output: output, spawnedFlame: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
