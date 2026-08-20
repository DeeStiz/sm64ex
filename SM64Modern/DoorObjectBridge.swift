import Foundation

struct SM64DoorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64DoorOutput
}

final class SM64DoorObjectBridge {
    static let normalBehaviorIdentity: UInt64 = 0x6268_765F_64726E
    static let warpBehaviorIdentity: UInt64 = 0x6268_765F_647277

    private struct State {
        let metalDoor: Bool
        let warpDoor: Bool
        var interactionStatus: UInt32
        var animationNearEnd: Bool
        var roomVisible: Bool
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64DoorObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnDoor(in engineState: SM64SwiftEngineState, warp: Bool = false, metalDoor: Bool = false, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let identity = warp ? Self.warpBehaviorIdentity : Self.normalBehaviorIdentity
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: identity, drawingDistance: 20_000)
        guard attach(id, warp: warp, metalDoor: metalDoor, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned door could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, warp: Bool, metalDoor: Bool, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(metalDoor: metalDoor, warpDoor: warp, interactionStatus: 0, animationNearEnd: false, roomVisible: true)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.interactionType = 1 << 2; record.hitboxRadius = 80; record.hitboxHeight = 100; record.collisionDistance = 20_000; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult func setInteractionStatus(_ status: UInt32, for id: SM64ObjectID) -> Bool { guard var s=states[id] else{return false}; s.interactionStatus=status; states[id]=s; return true }
    @discardableResult func setAnimationNearEnd(_ value: Bool, for id: SM64ObjectID) -> Bool { guard var s=states[id] else{return false}; s.animationNearEnd=value; states[id]=s; return true }
    @discardableResult func setRoomVisible(_ value: Bool, for id: SM64ObjectID) -> Bool { guard var s=states[id] else{return false}; s.roomVisible=value; states[id]=s; return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var objectState=states[id], let record=engineState.objects.record(for:id) else{return false}
        let output=SM64DoorBehavior.update(.init(action: SM64DoorAction(rawValue:record.action) ?? .closed,timer:record.timer,interactionStatus:objectState.interactionStatus,animationNearEnd:objectState.animationNearEnd,metalDoor:objectState.metalDoor,warpDoor:objectState.warpDoor,roomVisible:objectState.roomVisible))
        objectState.interactionStatus=0; objectState.animationNearEnd=false; states[id]=objectState
        _=engineState.objects.mutate(id){next in next.action=output.action.rawValue; next.timer=output.timer; next.animationState=output.animationState; next.graphFlags=output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10; next.interactionStatus=output.clearInteractionStatus ? 0 : next.interactionStatus; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform}
        effectLog.append(.init(objectID:id,output:output)); return true
    }
    func remove(_ id: SM64ObjectID){states.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
