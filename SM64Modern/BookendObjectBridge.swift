import Foundation

struct SM64BookendObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BookendOutput
    let spawnedChild: SM64ObjectID?
}

final class SM64BookendObjectBridge {
    static let spawnerBehaviorIdentity: UInt64 = 0x6268_765F_626573
    static let flyingBehaviorIdentity: UInt64 = 0x6268_765F_66626B
    static let bookendModel: UInt32 = 0x71 // MODEL_BOOKEND
    private struct State { let role: SM64BookendRole; var distanceToMario: Float; var facingMario: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BookendObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawnSpawner(in engineState:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.generalActor,behaviorIdentity:Self.spawnerBehaviorIdentity);guard attach(id,role:.spawner,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned bookend spawner could not attach")};return id}
    @discardableResult func spawnFlying(in engineState:SM64SwiftEngineState,parent:SM64ObjectID? = nil,position:SM64ObjectVector3 = .zero,action:Int32 = 3,moveYaw:Int32 = 0)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.generalActor,model:Self.bookendModel,behaviorIdentity:Self.flyingBehaviorIdentity,parent:parent);guard attach(id,role:.flying,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned flying bookend could not attach")};_ = engineState.objects.mutate(id){$0.action=action;$0.moveAngles.yaw=moveYaw};return id}
    @discardableResult func attach(_ id:SM64ObjectID,role:SM64BookendRole,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(role:role,distanceToMario:10_000,facingMario:false);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setSpawnerInput(distanceToMario:Float,facingMario:Bool,for id:SM64ObjectID)->Bool{guard var s=states[id],s.role == .spawner else{return false};s.distanceToMario=distanceToMario;s.facingMario=facingMario;states[id]=s;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let s=states[id],let record=engineState.objects.record(for:id)else{return false};if s.role == .spawner{let o=SM64BookendBehavior.updateSpawner(timer:record.timer,distanceToMario:s.distanceToMario,facingMario:s.facingMario);var child:SM64ObjectID?;if o.spawnChild{child=try? spawnFlying(in:engineState,parent:id,position:record.position,action:3,moveYaw:record.moveAngles.yaw)};_ = engineState.objects.mutate(id){$0.timer=o.timer};effectLog.append(.init(objectID:id,output:o,spawnedChild:child));return true};let o=SM64BookendBehavior.updateFlying(action:record.action,timer:record.timer,position:record.position,moveYaw:record.moveAngles.yaw,forwardVelocity:record.forwardVelocity);_ = engineState.objects.mutate(id){n in n.action=o.action;n.timer=o.timer;n.position=o.position;n.forwardVelocity=o.forwardVelocity;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:o,spawnedChild:nil));return true}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
