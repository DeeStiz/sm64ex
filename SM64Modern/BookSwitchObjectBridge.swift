import Foundation

struct SM64BookSwitchObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BookSwitchOutput
    let spawnedBookend: SM64ObjectID?
}

final class SM64BookSwitchObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6273776B
    private let bookendBridge: SM64BookendObjectBridge
    private struct State { var parent: SM64ObjectID?; var parentAction: Int32; var parentSequence: Int32; var parentEnabled: Bool; var attacked: Bool; var behaviorParam: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BookSwitchObjectEffectRecord] = []
    init(bookendBridge: SM64BookendObjectBridge) { self.bookendBridge = bookendBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawnSwitch(in engineState:SM64SwiftEngineState,parent:SM64ObjectID?=nil,position:SM64ObjectVector3 = .zero,behaviorParam:Int32=0)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.generalActor,behaviorIdentity:Self.defaultBehaviorIdentity,parent:parent);guard attach(id,parent:parent,position:position,behaviorParam:behaviorParam,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned book switch could not attach")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,parent:SM64ObjectID?,position:SM64ObjectVector3,behaviorParam:Int32,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(parent:parent,parentAction:0,parentSequence:0,parentEnabled:false,attacked:false,behaviorParam:behaviorParam);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.scale=SM64ObjectVector3(x:2,y:0.9,z:1);r.graphYOffset=30;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setInput(parentAction:Int32=0,parentSequence:Int32=0,parentEnabled:Bool=false,attacked:Bool=false,distanceToMario:Float=1000,for id:SM64ObjectID)->Bool{guard var s=states[id]else{return false};s.parentAction=parentAction;s.parentSequence=parentSequence;s.parentEnabled=parentEnabled;s.attacked=attacked;inputs[id]=distanceToMario;states[id]=s;return true}
    private var inputs:[SM64ObjectID:Float]=[:]
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard var s=states[id],let r=engineState.objects.record(for:id)else{return false};let distance=inputs[id] ?? r.distanceToMario;let o=SM64BookSwitchBehavior.update(.init(action:r.action,timer:r.timer,progress:r.position.z == r.homePosition.z ? 0 : r.homePosition.z-r.position.z,parentAction:s.parentAction,parentSequence:s.parentSequence,parentEnabled:s.parentEnabled,distanceToMario:distance,attacked:s.attacked,behaviorParam:s.behaviorParam,parentForwardVelocity:0,homeZ:r.homePosition.z,positionZ:r.position.z));s.parentAction=0;s.parentSequence=0;s.parentEnabled=false;s.attacked=false;states[id]=s;inputs.removeValue(forKey:id);var child:SM64ObjectID?;if o.spawnFlyingBookend{child=try? bookendBridge.spawnFlying(in:engineState,parent:id,position:r.position,action:3)};_ = engineState.objects.mutate(id){n in n.action=o.action;n.timer=o.timer;n.position.z=o.positionZ;n.intangibleTimer=o.tangible ? -1:1;if o.shouldDelete{n.activeFlags=0};n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:o,spawnedBookend:child));return true}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id);inputs.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
