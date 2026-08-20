import Foundation

struct SM64CannonBarrelObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CannonBarrelOutput
}

final class SM64CannonBarrelObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636272
    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64CannonBarrelObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { parents.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawnBarrel(in engineState:SM64SwiftEngineState,parent:SM64ObjectID,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.default,behaviorIdentity:Self.defaultBehaviorIdentity,parent:parent);guard attach(id,parent:parent,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned cannon barrel could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,parent:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil,pool.record(for:parent) != nil else{return false};parents[id]=parent;return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let parentID=parents[id],let parent=engineState.objects.record(for:parentID),let record=engineState.objects.record(for:id)else{return false};let o=SM64CannonBarrelBehavior.update(.init(parentPosition:parent.position,parentMoveYaw:parent.moveAngles.yaw,parentMovePitch:parent.faceAngles.pitch,parentActive:parent.activeFlags & SM64ObjectPool.activeFlagActive != 0));_ = engineState.objects.mutate(id){n in n.position=o.position;n.moveAngles.yaw=o.moveYaw;n.faceAngles.pitch=o.facePitch;n.graphFlags=o.visible ? n.graphFlags & ~UInt16(0x10):n.graphFlags | UInt16(0x10);n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};_ = record;effectLog.append(.init(objectID:id,output:o));return true}
    func remove(_ id:SM64ObjectID){parents.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
