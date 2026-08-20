import Foundation
struct SM64WaterLevelDiamondObjectEffectRecord: Equatable, Sendable { let objectID:SM64ObjectID; let output:SM64WaterLevelDiamondOutput }
struct SM64ChangingWaterLevelObjectEffectRecord: Equatable, Sendable { let objectID:SM64ObjectID; let output:SM64ChangingWaterLevelOutput }
final class SM64WaterLevelObjectBridge {
    static let diamondBehaviorIdentity:UInt64=0x6268_765F_776C64
    static let initializerBehaviorIdentity:UInt64=0x6268_765F_776369
    private struct DiamondState{var action:SM64WaterLevelDiamondAction;var targetLevel:Int32;var collided:Bool}
    private struct InitState{var phase:Int32;let regionsAvailable:Bool}
    private var diamonds:[SM64ObjectID:DiamondState]=[:];private var initializers:[SM64ObjectID:InitState]=[:]
    private(set)var diamondEffectLog:[SM64WaterLevelDiamondObjectEffectRecord]=[];private(set)var initializerEffectLog:[SM64ChangingWaterLevelObjectEffectRecord]=[]
    private(set)var globalLevel:Int32=0;private(set)var globalChanging=false
    var registeredIDs:[SM64ObjectID]{(Array(diamonds.keys)+Array(initializers.keys)).sorted{$0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot}}
    func beginExternalTick(){diamondEffectLog.removeAll(keepingCapacity:true);initializerEffectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnDiamond(in e:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero,currentLevel:Int32 = 0)throws->SM64ObjectID{globalLevel=currentLevel;let id=try e.spawnObject(in:.surface,behaviorIdentity:Self.diamondBehaviorIdentity);guard attachDiamond(id,position:position,in:e.objects)else{_ = e.objects.despawn(id);preconditionFailure("newly spawned water-level diamond could not attach")};return id}
    @discardableResult func spawnInitializer(in e:SM64SwiftEngineState,regionsAvailable:Bool=true,phase:Int32=0)throws->SM64ObjectID{let id=try e.spawnObject(in:.default,behaviorIdentity:Self.initializerBehaviorIdentity);guard e.objects.mutate(id,{r in r.action=0})else{throw SM64ObjectPoolError.invalidReference(id)};initializers[id]=InitState(phase:phase,regionsAvailable:regionsAvailable);return id}
    @discardableResult func attachDiamond(_ id:SM64ObjectID,position:SM64ObjectVector3,in p:SM64ObjectPool)->Bool{guard p.record(for:id) != nil else{return false};diamonds[id]=DiamondState(action:.initialize,targetLevel:Int32(position.y),collided:false);return p.mutate(id){r in r.position=position;r.homePosition=position;r.action=0;r.hitboxRadius=70;r.hitboxHeight=30;r.intangibleTimer=0;r.collisionDistance=200;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setMarioCollision(_ v:Bool,for id:SM64ObjectID)->Bool{guard var s=diamonds[id]else{return false};s.collided=v;diamonds[id]=s;return true}
    @discardableResult func setGlobalWaterLevel(_ level:Int32)->Bool{globalLevel=level;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->Bool{if diamonds[id] != nil{return updateDiamond(id,state:e)};if initializers[id] != nil{return updateInitializer(id,state:e)};return false}
    private func updateDiamond(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->Bool{guard var s=diamonds[id],let r=e.objects.record(for:id)else{return false};let o=SM64WaterLevelDiamondBehavior.update(.init(action:s.action,timer:r.timer,targetLevel:s.targetLevel,currentLevel:globalLevel,faceYaw:r.faceAngles.yaw,angleVelocityYaw:r.angleVelocity.yaw,collidedWithMario:s.collided,globalChanging:globalChanging));s.action=o.action;s.collided=false;diamonds[id]=s;globalLevel=o.currentLevel;globalChanging=o.globalChanging;_ = e.objects.mutate(id){n in n.action=o.action.rawValue;n.timer=o.timer;n.faceAngles.yaw=o.faceYaw;n.angleVelocity.yaw=o.angleVelocityYaw;n.hitboxRadius=o.hitboxRadius;n.hitboxHeight=o.hitboxHeight;n.collisionDistance=o.collisionDistance};diamondEffectLog.append(.init(objectID:id,output:o));return true}
    private func updateInitializer(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->Bool{guard var s=initializers[id],let r=e.objects.record(for:id)else{return false};let o=SM64ChangingWaterLevelBehavior.update(.init(action:r.action,timer:r.timer,phase:s.phase,globalLevel:globalLevel,regionsAvailable:s.regionsAvailable));s.phase=o.phase;initializers[id]=s;_ = e.objects.mutate(id){n in n.action=o.action;n.timer=o.timer};initializerEffectLog.append(.init(objectID:id,output:o));return true}
    func remove(_ id:SM64ObjectID){diamonds.removeValue(forKey:id);initializers.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
