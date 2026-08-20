import Foundation
struct SM64RecoveryHeartObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64RecoveryHeartOutput }
final class SM64RecoveryHeartObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_726863
    private struct State { var soundPlayed: Bool; var yawVelocity: Int32; var totalSpin: Int32; var collided: Bool; var marioForwardVelocity: Float }
    private var states:[SM64ObjectID:State]=[:]
    private(set) var effectLog:[SM64RecoveryHeartObjectEffectRecord]=[]
    var registeredIDs:[SM64ObjectID]{states.keys.sorted{$0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot}}
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnHeart(in engineState:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero)->SM64ObjectID{let id=try! engineState.spawnObject(in:.generalActor,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,in:engineState.objects)else{preconditionFailure("newly spawned recovery heart could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(soundPlayed:false,yawVelocity:400,totalSpin:0,collided:false,marioForwardVelocity:0);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.hitboxRadius=50;r.hitboxHeight=50;r.hurtboxRadius=50;r.hurtboxHeight=50;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setMarioCollision(_ collided:Bool,forwardVelocity:Float,for id:SM64ObjectID)->Bool{guard var s=states[id]else{return false};s.collided=collided;s.marioForwardVelocity=forwardVelocity;states[id]=s;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard var s=states[id],let r=engineState.objects.record(for:id)else{return false};let o=SM64RecoveryHeartBehavior.update(.init(collidedWithMario:s.collided,marioForwardVelocity:s.marioForwardVelocity,soundPlayed:s.soundPlayed,yawVelocity:s.yawVelocity,totalSpin:s.totalSpin,faceYaw:r.faceAngles.yaw));s.soundPlayed=o.soundPlayed;s.yawVelocity=o.yawVelocity;s.totalSpin=o.totalSpin;s.collided=false;states[id]=s;_ = engineState.objects.mutate(id){n in n.faceAngles.yaw=o.faceYaw;n.angleVelocity.yaw=o.yawVelocity;n.hitboxRadius=o.hitboxRadius;n.hitboxHeight=o.hitboxHeight;n.hurtboxRadius=o.hurtboxRadius;n.hurtboxHeight=o.hurtboxHeight;n.timer &+= 1;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:o));return true}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
