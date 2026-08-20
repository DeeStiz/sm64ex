import Foundation
struct SM64SnowmanCheckpointObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SnowmanCheckpointOutput; let parent: SM64ObjectID }
final class SM64SnowmanCheckpointObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736263
    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private var counters: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64SnowmanCheckpointObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { parents.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawn(in engineState:SM64SwiftEngineState,parent:SM64ObjectID,position:SM64ObjectVector3 = .zero)->SM64ObjectID?{guard engineState.objects.record(for:parent) != nil else{return nil};let id=try? engineState.spawnObject(in:.default,behaviorIdentity:Self.defaultBehaviorIdentity,parent:parent);guard let id else{return nil};guard attach(id,parent:parent,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);return nil};return id}
    @discardableResult func attach(_ id:SM64ObjectID,parent:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil,pool.record(for:parent) != nil else{return false};parents[id]=parent;counters[parent,default:0]=counters[parent,default:0];return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let parent=parents[id],let record=engineState.objects.record(for:id),let parentRecord=engineState.objects.record(for:parent)else{return false};let output=SM64SnowmanCheckpointBehavior.update(distanceToMario:record.distanceToMario,parentActive:parentRecord.activeFlags & SM64ObjectPool.activeFlagActive != 0);if output.counterIncrement != 0{counters[parent,default:0] += output.counterIncrement};_ = engineState.objects.mutate(id){if output.shouldDeactivate{$0.activeFlags=0}};effectLog.append(.init(objectID:id,output:output,parent:parent));return true}
    func counter(for parent:SM64ObjectID)->Int32{counters[parent] ?? 0}
    func remove(_ id:SM64ObjectID){parents.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
