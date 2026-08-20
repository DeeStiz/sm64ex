import Foundation
struct SM64BetaHoldableObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BetaHoldableOutput }
final class SM64BetaHoldableObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62686F
    private var registered:Set<SM64ObjectID>=[];private(set) var effectLog:[SM64BetaHoldableObjectEffectRecord]=[]
    var registeredIDs:[SM64ObjectID]{registered.sorted{$0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot}}
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawn(in engineState:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.generalActor,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned beta holdable could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};registered.insert(id);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.heldState=0;r.interactionType=1<<1;r.hitboxRadius=40;r.hitboxHeight=50;r.gravity=2.5;r.friction=0.8;r.buoyancy=1.3;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setState(_ state:SM64BetaHoldableState,for id:SM64ObjectID)->Bool{guard registered.contains(id)else{return false};return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard registered.contains(id),let r=engineState.objects.record(for:id)else{return false};let output=SM64BetaHoldableBehavior.update(state:SM64BetaHoldableState(rawValue:UInt8(clamping:r.heldState)) ?? .free,forwardVelocity:r.forwardVelocity,velocityY:r.velocity.y);_ = engineState.objects.mutate(id){n in n.heldState=UInt32(output.state.rawValue);n.forwardVelocity=output.forwardVelocity;n.velocity.y=output.velocityY;n.graphFlags=output.visible ? n.graphFlags & ~SM64ObjectScheduler.graphRenderHasAnimation : n.graphFlags | SM64ObjectScheduler.graphRenderHasAnimation;n.interactionStatus=0;n.intangibleTimer=0;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:output));return true}
    func remove(_ id:SM64ObjectID){registered.remove(id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
