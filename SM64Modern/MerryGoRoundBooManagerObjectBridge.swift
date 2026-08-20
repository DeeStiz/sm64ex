import Foundation

struct SM64MerryGoRoundBooManagerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MerryGoRoundBooManagerOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64MerryGoRoundBooManagerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D726D67
    private let booBridge: SM64BooObjectBridge
    private let bigBooBridge: SM64BigBooObjectBridge
    private var boosKilled: [SM64ObjectID: Int32] = [:]
    private var boosSpawned: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64MerryGoRoundBooManagerObjectEffectRecord] = []
    init(booBridge: SM64BooObjectBridge, bigBooBridge: SM64BigBooObjectBridge) { self.booBridge = booBridge; self.bigBooBridge = bigBooBridge }
    var registeredIDs: [SM64ObjectID] { Array(boosKilled.keys).sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawnManager(in engineState:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.default,behaviorIdentity:Self.defaultBehaviorIdentity);boosKilled[id]=0;boosSpawned[id]=0;_ = engineState.objects.mutate(id){$0.position=position;$0.homePosition=position;$0.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};return id}
    @discardableResult func setBoosKilled(_ value:Int32,for id:SM64ObjectID)->Bool{guard boosKilled[id] != nil else{return false};boosKilled[id]=value;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard let record=engineState.objects.record(for:id),var killed=boosKilled[id],var spawned=boosSpawned[id]else{return false};let o=SM64MerryGoRoundBooManagerBehavior.update(action:record.action,timer:record.timer,distanceToMario:record.distanceToMario,boosKilled:killed,boosSpawned:spawned);var children:[SM64ObjectID]=[];if o.spawnSmallBoo{if let child=try? engineState.objects.spawn(in:.generalActor,model:SM64BooObjectBridge.defaultModel,behaviorIdentity:SM64BooObjectBridge.merryGoRoundBehaviorIdentity,parent:id){_ = booBridge.attach(child,in:engineState.objects);children.append(child);spawned += 1}};if o.spawnBigBoo{if let child=try? engineState.objects.spawn(in:.generalActor,model:SM64BigBooObjectBridge.defaultModel,behaviorIdentity:SM64BigBooObjectBridge.defaultBehaviorIdentity,parent:id){_ = bigBooBridge.attach(child,variant:.ghostHunt,in:engineState.objects);children.append(child)}};killed=0;boosKilled[id]=killed;boosSpawned[id]=spawned;_ = engineState.objects.mutate(id){$0.action=o.action;$0.timer=o.timer};effectLog.append(.init(objectID:id,output:o,spawnedChildren:children));return true}
    func remove(_ id:SM64ObjectID){boosKilled.removeValue(forKey:id);boosSpawned.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
