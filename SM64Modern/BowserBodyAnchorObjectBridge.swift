import Foundation
struct SM64BowserBodyAnchorObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BowserBodyAnchorOutput; let parent: SM64ObjectID }
final class SM64BowserBodyAnchorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626261_31
    private var parents:[SM64ObjectID:SM64ObjectID]=[:]
    private(set) var effectLog:[SM64BowserBodyAnchorObjectEffectRecord]=[]
    var registeredIDs:[SM64ObjectID]{parents.keys.sorted{$0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot}}
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawn(in engineState:SM64SwiftEngineState,parent:SM64ObjectID,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.generalActor,behaviorIdentity:Self.defaultBehaviorIdentity,parent:parent);guard attach(id,parent:parent,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned Bowser body anchor could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,parent:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil,pool.record(for:parent) != nil else{return false};parents[id]=parent;return pool.mutate(id){r in r.position=position;r.hitboxRadius=100;r.hitboxHeight=300;r.damageOrCoinValue=2;r.interactionSubtype=1<<11;r.interactionType=1<<3;r.intangibleTimer=0;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let parent=parents[id],let p=engineState.objects.record(for:parent)else{return false};let o=SM64BowserBodyAnchorBehavior.update(position:p.position,faceAngles:p.faceAngles,parentAction:p.action,parentSubAction:p.subAction,parentOpacity:p.opacity,parentHeld:p.heldState != 0);_ = engineState.objects.mutate(id){n in n.position=o.position;n.faceAngles=o.faceAngles;n.interactionType=o.interactionType;n.interactionStatus=0;n.intangibleTimer=o.tangible ? 0:1;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:o,parent:parent));return true}
    func remove(_ id:SM64ObjectID){parents.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
