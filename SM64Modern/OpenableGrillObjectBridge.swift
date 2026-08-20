import Foundation

struct SM64OpenableGrillObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64OpenableGrillOutput
    let spawnedChildren: [SM64ObjectID]
}
struct SM64OpenableCageDoorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64OpenableCageDoorOutput
    let parentID: SM64ObjectID?
}

final class SM64OpenableGrillObjectBridge {
    static let grillBehaviorIdentity: UInt64 = 0x6268_765F_6F6772
    static let cageDoorBehaviorIdentity: UInt64 = 0x6268_765F_6F6364

    private struct GrillState { var action: SM64OpenableGrillAction; let variant: Int32; var floorSwitchFound: Bool; var floorSwitchAction: Int32?; var openSignal: Int32 }
    private struct CageState { let parentID: SM64ObjectID; let yawDirection: Int32 }
    private var grills: [SM64ObjectID: GrillState] = [:]
    private var cages: [SM64ObjectID: CageState] = [:]
    private(set) var grillEffectLog: [SM64OpenableGrillObjectEffectRecord] = []
    private(set) var cageEffectLog: [SM64OpenableCageDoorObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { let ids = Array(grills.keys) + Array(cages.keys); return ids.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { grillEffectLog.removeAll(keepingCapacity: true); cageEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnGrill(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, variant: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.grillBehaviorIdentity)
        guard attachGrill(id, position: position, variant: variant, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned openable grill could not attach") }
        return id
    }

    @discardableResult
    func attachGrill(_ id: SM64ObjectID, position: SM64ObjectVector3, variant: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        grills[id] = GrillState(action: .spawnChildren, variant: variant, floorSwitchFound: false, floorSwitchAction: nil, openSignal: 0)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.behaviorParams2ndByte = variant; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func setFloorSwitch(found: Bool, action: Int32?, for id: SM64ObjectID) -> Bool { guard var state = grills[id] else { return false }; state.floorSwitchFound = found; state.floorSwitchAction = action; grills[id] = state; return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if grills[id] != nil { return updateGrill(id, state: engineState) }
        if cages[id] != nil { return updateCage(id, state: engineState) }
        return false
    }
    private func updateGrill(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var grill = grills[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64OpenableGrillBehavior.update(.init(action: grill.action, timer: record.timer, variant: grill.variant, floorSwitchFound: grill.floorSwitchFound, floorSwitchAction: grill.floorSwitchAction))
        var children: [SM64ObjectID] = []
        if output.spawnChildren {
            let halfWidth: Float = grill.variant == 0 ? 320 : 410
            if let left = try? spawnCage(in: engineState, parent: id, position: .init(x: record.position.x + halfWidth, y: record.position.y, z: record.position.z), yawDirection: -1) { children.append(left) }
            if let right = try? spawnCage(in: engineState, parent: id, position: .init(x: record.position.x - halfWidth, y: record.position.y, z: record.position.z), yawDirection: 1) { children.append(right) }
        }
        grill.action = output.action
        if output.signalChildren { grill.openSignal = 2 }
        grill.floorSwitchFound = false
        grill.floorSwitchAction = nil
        grills[id] = grill
        _ = engineState.objects.mutate(id) { next in next.action = output.action.rawValue; next.timer = output.timer }
        grillEffectLog.append(.init(objectID: id, output: output, spawnedChildren: children))
        return true
    }
    private func spawnCage(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3, yawDirection: Int32) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.cageDoorBehaviorIdentity, parent: parent)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.parent = parent; record.faceAngles.yaw = yawDirection == -1 ? 0x8000 : 0; record.behaviorParams2ndByte = yawDirection; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { throw SM64ObjectPoolError.invalidReference(id) }
        cages[id] = CageState(parentID: parent, yawDirection: yawDirection)
        return id
    }
    private func updateCage(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let cage = cages[id], let parent = grills[cage.parentID], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64OpenableCageDoorBehavior.update(.init(action: record.action, timer: record.timer, faceYaw: record.faceAngles.yaw, yawDirection: cage.yawDirection, parentOpenSignal: parent.openSignal))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.faceAngles.yaw = output.faceYaw }
        cageEffectLog.append(.init(objectID: id, output: output, parentID: cage.parentID))
        return true
    }
    func remove(_ id: SM64ObjectID) { grills.removeValue(forKey: id); cages.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
