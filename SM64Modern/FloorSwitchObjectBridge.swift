import Foundation
struct SM64FloorSwitchObjectEffectRecord:Equatable,Sendable{let objectID:SM64ObjectID;let output:SM64FloorSwitchOutput}
final class SM64FloorSwitchObjectBridge{
 static let hardcodedBehaviorIdentity:UInt64=0x6268_765F_667368
 static let grillsBehaviorIdentity:UInt64=0x6268_765F_667367
 static let animatesBehaviorIdentity:UInt64=0x6268_765F_667361
 static let hiddenObjectsBehaviorIdentity:UInt64=0x6268_765F_66736F
 static let purpleSwitchHiddenBoxesBehaviorIdentity:UInt64=0x6268_765F_707368
 enum Variant { case hardcoded; case grills; case animates; case hiddenObjects; var identity: UInt64 { switch self { case .hardcoded: return SM64FloorSwitchObjectBridge.hardcodedBehaviorIdentity; case .grills: return SM64FloorSwitchObjectBridge.grillsBehaviorIdentity; case .animates: return SM64FloorSwitchObjectBridge.animatesBehaviorIdentity; case .hiddenObjects: return SM64FloorSwitchObjectBridge.hiddenObjectsBehaviorIdentity } } }
 private struct State{let behaviorByte:Int32;var platformOn:Bool;var lateral:Float;var unknown13:Bool}
 private var states:[SM64ObjectID:State]=[:];private(set)var effectLog:[SM64FloorSwitchObjectEffectRecord]=[]
 var registeredIDs:[SM64ObjectID]{states.keys.sorted{$0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot}}
 func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
 @discardableResult func spawnSwitch(in e:SM64SwiftEngineState,behaviorByte:Int32 = 0,position:SM64ObjectVector3 = .zero,identity:UInt64? = nil)throws->SM64ObjectID{let b=identity ?? Self.hardcodedBehaviorIdentity;let id=try e.spawnObject(in:.surface,behaviorIdentity:b);guard attach(id,behaviorByte:behaviorByte,position:position,in:e.objects)else{_ = e.objects.despawn(id);preconditionFailure("newly spawned floor switch could not attach")};return id}
 @discardableResult func attach(_ id:SM64ObjectID,behaviorByte:Int32,position:SM64ObjectVector3,in p:SM64ObjectPool)->Bool{guard p.record(for:id) != nil else{return false};states[id]=State(behaviorByte:behaviorByte,platformOn:false,lateral:0,unknown13:false);return p.mutate(id){r in r.position=position;r.homePosition=position;r.action=0;r.scale=SM64ObjectVector3(x:1.5,y:1.5,z:1.5);r.collisionDistance=4000;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
 @discardableResult func setMarioState(platformOn:Bool,lateralDistance:Float=0,unknown13:Bool=false,for id:SM64ObjectID)->Bool{guard var s=states[id]else{return false};s.platformOn=platformOn;s.lateral=lateralDistance;s.unknown13=unknown13;states[id]=s;return true}
 @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->Bool{guard let s=states[id],let r=e.objects.record(for:id)else{return false};let o=SM64FloorSwitchBehavior.update(.init(action:SM64FloorSwitchAction(rawValue:r.action) ?? .idle,timer:r.timer,behaviorByte:s.behaviorByte,platformOn:s.platformOn,lateralDistance:s.lateral,marioUnknown13:s.unknown13));_ = e.objects.mutate(id){n in n.action=o.action.rawValue;n.timer=o.timer;n.scale=SM64ObjectVector3(x:o.scale,y:o.scale,z:o.scale)};effectLog.append(.init(objectID:id,output:o));return true}
 func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
