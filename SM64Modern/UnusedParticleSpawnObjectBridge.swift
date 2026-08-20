import Foundation

struct SM64UnusedParticleSpawnEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let spawnedParticles: [SM64ObjectID]; let deactivated: Bool }

final class SM64UnusedParticleSpawnObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_757073
    private let purpleParticleBridge: SM64PurpleParticleObjectBridge
    private var registered: Set<SM64ObjectID> = []
    private var collided: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64UnusedParticleSpawnEffectRecord] = []
    init(purpleParticleBridge: SM64PurpleParticleObjectBridge) { self.purpleParticleBridge = purpleParticleBridge }
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id=try engineState.spawnObject(in:.generalActor,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned unused particle spawner could not attach")};return id }
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};registered.insert(id);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.hitboxRadius=40;r.hitboxHeight=40;r.interactionType=1;r.intangibleTimer=0;r.gravity = -4;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setCollision(_ value:Bool,for id:SM64ObjectID)->Bool{guard registered.contains(id)else{return false};if value{collided.insert(id)}else{collided.remove(id)};return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard registered.contains(id),let r=engineState.objects.record(for:id)else{return false};let collidedNow=collided.remove(id) != nil;let output=SM64UnusedParticleSpawnBehavior.update(onGround:r.moveFlags & 1 != 0,collidedWithMario:collidedNow);if output.shouldRetire{var children:[SM64ObjectID]=[];for _ in 0..<output.spawnCount{if let child=try? purpleParticleBridge.spawnParticle(in:engineState,position:r.position,moveYaw:r.moveAngles.yaw,randomForwardUnit:0.5,randomVerticalUnit:0.5){children.append(child)}};_ = engineState.objects.mutate(id){$0.activeFlags=0};effectLog.append(.init(objectID:id,spawnedParticles:children,deactivated:true));return true};return true}
    func remove(_ id:SM64ObjectID){registered.remove(id);collided.remove(id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
