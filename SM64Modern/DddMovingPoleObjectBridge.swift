import Foundation

struct SM64DddMovingPoleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let output: SM64DddMovingPoleOutput
}

/// Owner-thread bridge for the BITFS cage's parent-relative pole child.
final class SM64DddMovingPoleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_646D70
    static let defaultModel: UInt32 = 0
    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64DddMovingPoleObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { parents.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnPole(in engineState: SM64SwiftEngineState,parent:SM64ObjectID,model:UInt32=SM64DddMovingPoleObjectBridge.defaultModel)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.polelike,model:model,behaviorIdentity:Self.defaultBehaviorIdentity,parent:parent);guard attach(id,parent:parent,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned DDD moving pole could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,parent:SM64ObjectID,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil,pool.record(for:parent) != nil else{return false};parents[id]=parent;return pool.mutate(id){r in r.parent=parent;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->SM64DddMovingPoleObjectEffectRecord?{guard let parentID=parents[id],let parent=e.objects.record(for:parentID),e.objects.record(for:id) != nil else{return nil};let o=SM64DddMovingPoleBehavior.update(.init(parentPosition:parent.position,parentFaceAngles:parent.faceAngles,parentMoveAngles:parent.moveAngles));_ = e.objects.mutate(id){n in n.position=o.position;n.faceAngles=o.faceAngles;n.moveAngles=o.moveAngles;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};let effect=SM64DddMovingPoleObjectEffectRecord(objectID:id,parentID:parentID,output:o);effectLog.append(effect);return effect}
    func remove(_ id:SM64ObjectID){parents.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
