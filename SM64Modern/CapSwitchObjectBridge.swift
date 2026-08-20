import Foundation

struct SM64CapSwitchObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CapSwitchOutput
    let spawnedBase: SM64ObjectID?
}
struct SM64CapSwitchBaseObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CapSwitchBaseOutput
}

final class SM64CapSwitchObjectBridge {
    static let capSwitchBehaviorIdentity: UInt64 = 0x6268_765F_637370
    static let capSwitchBaseBehaviorIdentity: UInt64 = 0x6268_765F_637362

    private struct SwitchState {
        let variant: Int32
        var saveFlags: UInt32
        let levelIsUnknown32: Bool
        var marioOnPlatform: Bool
        var dialogComplete: Bool
    }
    private var switches: [SM64ObjectID: SwitchState] = [:]
    private var bases: Set<SM64ObjectID> = []
    private(set) var switchEffectLog: [SM64CapSwitchObjectEffectRecord] = []
    private(set) var baseEffectLog: [SM64CapSwitchBaseObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        let ids = Array(switches.keys) + Array(bases)
        return ids.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }
    func beginExternalTick() { switchEffectLog.removeAll(keepingCapacity: true); baseEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSwitch(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, variant: Int32 = 0, saveFlags: UInt32 = 0, levelIsUnknown32: Bool = false) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.capSwitchBehaviorIdentity)
        guard attachSwitch(id, position: position, variant: variant, saveFlags: saveFlags, levelIsUnknown32: levelIsUnknown32, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned cap switch could not attach") }
        return id
    }

    @discardableResult
    func spawnBase(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.capSwitchBaseBehaviorIdentity, parent: parent)
        guard attachBase(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned cap switch base could not attach") }
        return id
    }

    @discardableResult
    func attachSwitch(_ id: SM64ObjectID, position: SM64ObjectVector3, variant: Int32, saveFlags: UInt32, levelIsUnknown32: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        switches[id] = SwitchState(variant: variant, saveFlags: saveFlags, levelIsUnknown32: levelIsUnknown32, marioOnPlatform: false, dialogComplete: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = variant
            record.action = SM64CapSwitchAction.initialize.rawValue
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachBase(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        bases.insert(id)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult func setMarioOnPlatform(_ value: Bool, for id: SM64ObjectID) -> Bool { guard var state = switches[id] else { return false }; state.marioOnPlatform = value; switches[id] = state; return true }
    @discardableResult func setDialogComplete(_ value: Bool, for id: SM64ObjectID) -> Bool { guard var state = switches[id] else { return false }; state.dialogComplete = value; switches[id] = state; return true }
    @discardableResult func setSaveFlags(_ value: UInt32, for id: SM64ObjectID) -> Bool { guard var state = switches[id] else { return false }; state.saveFlags = value; switches[id] = state; return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if switches[id] != nil { return updateSwitch(id, state: engineState) }
        if bases.contains(id) { return updateBase(id, state: engineState) }
        return false
    }
    private func updateSwitch(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var switchState = switches[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64CapSwitchBehavior.update(.init(action: SM64CapSwitchAction(rawValue: record.action) ?? .initialize, timer: record.timer, variant: switchState.variant, positionY: record.position.y, saveFlags: switchState.saveFlags, levelIsUnknown32: switchState.levelIsUnknown32, marioOnPlatform: switchState.marioOnPlatform, dialogComplete: switchState.dialogComplete))
        switchState.marioOnPlatform = false
        switchState.dialogComplete = false
        if output.saveFlagToSet != 0 { switchState.saveFlags |= output.saveFlagToSet }
        switches[id] = switchState
        var base: SM64ObjectID?
        if output.spawnBase { base = try? spawnBase(in: engineState, position: .init(x: record.position.x, y: output.positionY - 71, z: record.position.z), parent: id) }
        _ = engineState.objects.mutate(id) { next in next.action = output.action.rawValue; next.timer = output.timer; next.position.y = output.positionY; next.scale = .init(x: output.scaleX, y: output.scaleY, z: output.scaleZ); next.animationState = output.animationState; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        switchEffectLog.append(.init(objectID: id, output: output, spawnedBase: base))
        return true
    }
    private func updateBase(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id) else { return false }
        let output = SM64CapSwitchBaseBehavior.update(.init(timer: record.timer))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer }
        baseEffectLog.append(.init(objectID: id, output: output))
        return true
    }
    func remove(_ id: SM64ObjectID) { switches.removeValue(forKey: id); bases.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
