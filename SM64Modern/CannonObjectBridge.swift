import Foundation

struct SM64CannonObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CannonOutput
    let spawnedBarrel: SM64ObjectID?
}

final class SM64CannonObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_63616E
    private let barrelBridge: SM64CannonBarrelObjectBridge
    private var inputs: [SM64ObjectID: (Float, Bool, Bool)] = [:]
    private var cannons: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64CannonObjectEffectRecord] = []
    init(barrelBridge: SM64CannonBarrelObjectBridge) { self.barrelBridge = barrelBridge }
    var registeredIDs: [SM64ObjectID] { cannons.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawnCannon(in engineState:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero,behaviorByte:Int32=0)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.level,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned cannon could not attach")};_ = engineState.objects.mutate(id){$0.behaviorParams2ndByte=behaviorByte};_ = try? barrelBridge.spawnBarrel(in:engineState,parent:id,position:position);return id}
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};cannons.insert(id);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.interactionType=1 << 14;r.hitboxRadius=150;r.hitboxHeight=150;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setInput(distanceToMario:Float,interacted:Bool=false,touchedBobomb:Bool=false,for id:SM64ObjectID)->Bool{guard cannons.contains(id) else{return false};inputs[id]=(distanceToMario,interacted,touchedBobomb);return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let record=engineState.objects.record(for:id)else{return false};let input=inputs.removeValue(forKey:id) ?? (record.distanceToMario,false,false);let o=SM64CannonBehavior.update(.init(action:record.action,timer:record.timer,position:record.position,homePosition:record.homePosition,moveYaw:record.moveAngles.yaw,movePitch:record.moveAngles.pitch,cannonPhase:record.behaviorParams, distanceToMario:input.0,interacted:input.1,touchedBobomb:input.2,behaviorByte:record.behaviorParams2ndByte));_ = engineState.objects.mutate(id){n in n.action=o.action;n.timer=o.timer;n.position=o.position;n.moveAngles.yaw=o.moveYaw;n.moveAngles.pitch=o.movePitch;n.behaviorParams=o.cannonPhase;n.intangibleTimer=o.tangible ? -1:1;n.graphFlags=o.visible ? n.graphFlags & ~UInt16(0x10):n.graphFlags | UInt16(0x10);n.interactionStatus=0;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:o,spawnedBarrel:nil));return true}
    func remove(_ id:SM64ObjectID){inputs.removeValue(forKey:id);cannons.remove(id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
