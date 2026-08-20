import Foundation

struct SM64TiltingPyramidObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TiltingPyramidOutput
}

final class SM64TiltingPyramidObjectBridge {
    static let bitfsBehaviorIdentity: UInt64 = 0x6268_765F_627469
    static let anotherBehaviorIdentity: UInt64 = 0x6268_765F_617470
    static let lllBehaviorIdentity: UInt64 = 0x6268_765F_6C7469
    private var variants: [SM64ObjectID: SM64TiltingPyramidVariant] = [:]
    private var marioOn: [SM64ObjectID: Bool] = [:]
    private var normals: [SM64ObjectID: (Float, Float, Float)] = [:]
    private(set) var effectLog: [SM64TiltingPyramidObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { variants.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawn(in engineState:SM64SwiftEngineState,variant:SM64TiltingPyramidVariant = .bitfs,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let identity:UInt64=switch variant{case .bitfs:Self.bitfsBehaviorIdentity;case .another:Self.anotherBehaviorIdentity;case .lll:Self.lllBehaviorIdentity};let id=try engineState.spawnObject(in:.surface,behaviorIdentity:identity);guard attach(id,variant:variant,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned tilting pyramid could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,variant:SM64TiltingPyramidVariant,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};variants[id]=variant;marioOn[id]=false;normals[id]=(0,1,0);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.collisionDataIdentity=variant == .bitfs ? 0x62697466735F6970 : variant == .lll ? 0x6C6C6C5F69706D : 0;r.collisionDistance=variant == .another ? 1000:4000;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setMarioOn(_ value:Bool,for id:SM64ObjectID)->Bool{guard variants[id] != nil else{return false};marioOn[id]=value;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let variant=variants[id],let record=engineState.objects.record(for:id)else{return false};let current=normals[id] ?? (0,1,0);let output=SM64TiltingPyramidBehavior.update(.init(variant:variant,position:record.position,normalX:current.0,normalY:current.1,normalZ:current.2,marioPosition:engineState.globals.marioObject.flatMap{engineState.objects.record(for:$0)?.position} ?? .zero,marioOnPlatform:marioOn[id] ?? false));normals[id]=(output.normalX,output.normalY,output.normalZ);_ = engineState.objects.mutate(id){n in n.collisionDataIdentity=variant == .bitfs ? 0x62697466735F6970 : variant == .lll ? 0x6C6C6C5F69706D : 0;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:output));return true}
    func remove(_ id:SM64ObjectID){variants.removeValue(forKey:id);marioOn.removeValue(forKey:id);normals.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
