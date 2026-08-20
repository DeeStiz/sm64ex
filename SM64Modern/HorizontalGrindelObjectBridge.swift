import Foundation

struct SM64HorizontalGrindelObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64HorizontalGrindelOutput }

final class SM64HorizontalGrindelObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_686772
    static let collisionIdentity: UInt64 = 0x73736C5F67726E64
    private struct State: Equatable { var wasOnGround: Bool; var targetYaw: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64HorizontalGrindelObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, onGround: Bool = true, lateralDistanceHome: Float = 0) throws -> SM64ObjectID { let id=try engineState.spawnObject(in:.surface,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,moveYaw:moveYaw,onGround:onGround,lateralDistanceHome:lateralDistanceHome,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned horizontal Grindel could not attach")};return id }
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,moveYaw:Int32,onGround:Bool,lateralDistanceHome:Float,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(wasOnGround:onGround,targetYaw:moveYaw);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.moveAngles.yaw=moveYaw;r.faceAngles.yaw=moveYaw+0x4000;r.scale=SM64ObjectVector3(x:0.9,y:0.9,z:0.9);r.collisionDataIdentity=Self.collisionIdentity;r.collisionDistance=1000;r.wallHitboxRadius=40;r.gravity = -4;r.forwardVelocity=0;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard var s=states[id],let r=engineState.objects.record(for:id)else{return false};let o=SM64HorizontalGrindelBehavior.update(.init(onGround:r.moveFlags & 1 != 0,wasOnGround:s.wasOnGround,lateralDistanceHome:r.angleToHome == 0 ? 0 : Float(abs(r.angleToHome)),timer:r.timer,moveYaw:r.moveAngles.yaw,targetYaw:s.targetYaw,forwardVelocity:r.forwardVelocity,velocityY:r.velocity.y,gravity:r.gravity));s.wasOnGround=o.onGround;s.targetYaw=o.targetYaw;states[id]=s;_ = engineState.objects.mutate(id){n in n.timer=o.timer;n.moveAngles.yaw=o.moveYaw;n.faceAngles.yaw=o.faceYaw;n.forwardVelocity=o.forwardVelocity;n.velocity.y=o.velocityY;n.gravity=o.gravity;n.collisionDataIdentity=Self.collisionIdentity;n.collisionDistance=1000;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};_ = engineState.bindPlatformCollisionOwner(id,surfaceIDs:[0x401]);effectLog.append(.init(objectID:id,output:o));return true}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
