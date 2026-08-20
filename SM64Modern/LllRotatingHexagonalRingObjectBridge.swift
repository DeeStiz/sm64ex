import Foundation

struct SM64LllRotatingHexagonalRingObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LllRotatingHexagonalRingOutput
    let spawnedFlame: SM64ObjectID?
}

/// Owner route for the LLL rotating ring. Volcano-flame children are spawned
/// as explicit C fallback identities until their own behavior is migrated.
final class SM64LllRotatingHexagonalRingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C6872
    static let volcanoFlamesBehaviorIdentity: UInt64 = 0x6268_765F_76666C
    static let defaultModel: UInt32 = 0
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64LllRotatingHexagonalRingObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}

    @discardableResult func spawnRing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, model: UInt32 = SM64LllRotatingHexagonalRingObjectBridge.defaultModel) throws -> SM64ObjectID { let id=try engineState.spawnObject(in:.level,model:model,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned LLL ring could not attach")};return id }
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3 = .zero,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};registered.insert(id);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->SM64LllRotatingHexagonalRingObjectEffectRecord?{guard registered.contains(id),let r=e.objects.record(for:id)else{return nil};let o=SM64LllRotatingHexagonalRingBehavior.update(.init(action:r.action,timer:r.timer,marioOnPlatform:r.platform==id,moveYaw:r.moveAngles.yaw));var child:SM64ObjectID?;if o.spawnVolcanoFlame{child=try? e.spawnObject(in:.unimportant,model:0,behaviorIdentity:Self.volcanoFlamesBehaviorIdentity,parent:id)};let nt=o.action==r.action ? r.timer &+ 1 : 0;_ = e.objects.mutate(id){n in n.action=o.action;n.timer=nt;n.moveAngles.yaw=o.moveYaw;n.faceAngles.yaw=o.moveYaw;n.angleVelocity.yaw=o.angleVelocityYaw;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};let effect=SM64LllRotatingHexagonalRingObjectEffectRecord(objectID:id,output:o,spawnedFlame:child);effectLog.append(effect);return effect}
    func remove(_ id:SM64ObjectID){registered.remove(id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
