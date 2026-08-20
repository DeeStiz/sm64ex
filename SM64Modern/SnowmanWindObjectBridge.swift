import Foundation

struct SM64SnowmanWindObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SnowmanWindOutput }

final class SM64SnowmanWindObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736C77
    private struct State: Sendable { var originalYaw: Int32; var angleToMario: Int32; var distanceToMario: Float; var marioY: Float; var canActivateText: Bool; var dialogComplete: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SnowmanWindObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, originalYaw: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = originalYaw; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Snowman wind could not attach") }
        states[id] = State(originalYaw: originalYaw, angleToMario: originalYaw, distanceToMario: 10_000, marioY: position.y, canActivateText: false, dialogComplete: false); return id
    }

    @discardableResult
    func setInput(angleToMario: Int32 = 0, distanceToMario: Float = 10_000, marioY: Float = 0, canActivateText: Bool = false, dialogComplete: Bool = false, for id: SM64ObjectID) -> Bool { guard states[id] != nil else { return false }; states[id] = State(originalYaw: states[id]!.originalYaw, angleToMario: angleToMario, distanceToMario: distanceToMario, marioY: marioY, canActivateText: canActivateText, dialogComplete: dialogComplete); return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SnowmanWindBehavior.update(.init(subAction: record.subAction, timer: record.timer, originalYaw: state.originalYaw, moveYaw: record.moveAngles.yaw, angleToMario: state.angleToMario, distanceToMario: state.distanceToMario, marioY: state.marioY, homeY: record.homePosition.y, canActivateText: state.canActivateText, dialogComplete: state.dialogComplete))
        states[id] = State(originalYaw: state.originalYaw, angleToMario: 0, distanceToMario: 10_000, marioY: 0, canActivateText: false, dialogComplete: false)
        _ = engineState.objects.mutate(id) { next in next.subAction = output.subAction; next.timer = output.timer; next.moveAngles.yaw = output.moveYaw; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
