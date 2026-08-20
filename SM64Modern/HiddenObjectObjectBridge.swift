import Foundation

struct SM64HiddenObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64HiddenObjectOutput }
final class SM64HiddenObjectObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_686F62
    private struct State { let variant: Int32; var switchAction: Int32?; var attacked: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64HiddenObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnObject(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, variant: Int32 = 0, switchAction: Int32? = nil) throws -> SM64ObjectID { let id=try engineState.spawnObject(in:.surface,behaviorIdentity:Self.defaultBehaviorIdentity); guard attach(id,position:position,variant:variant,switchAction:switchAction,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned hidden object could not attach")};return id }
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,variant:Int32,switchAction:Int32?,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(variant:variant,switchAction:switchAction,attacked:false);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.behaviorParams2ndByte=variant;r.action=0;r.hitboxRadius=150;r.hitboxHeight=200;r.hurtboxRadius=150;r.hurtboxHeight=200;r.collisionDistance=300;r.intangibleTimer=1;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setSwitchAction(_ action:Int32?,for id:SM64ObjectID)->Bool{guard var s=states[id]else{return false};s.switchAction=action;states[id]=s;return true}
    @discardableResult func setAttacked(_ attacked:Bool,for id:SM64ObjectID)->Bool{guard var s=states[id]else{return false};s.attacked=attacked;states[id]=s;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard var s=states[id],let r=engineState.objects.record(for:id)else{return false};let o=SM64HiddenObjectBehavior.update(.init(action:SM64HiddenObjectAction(rawValue:r.action) ?? .hidden,timer:r.timer,variant:s.variant,switchAction:s.switchAction,attackedOrGroundPounded:s.attacked));s.attacked=false;states[id]=s;_ = engineState.objects.mutate(id){n in n.action=o.action.rawValue;n.timer=o.timer;n.scale=SM64ObjectVector3(x:o.scale,y:o.scale,z:o.scale);n.intangibleTimer=o.tangible ? -1 : 1;n.graphFlags=o.visible ? n.graphFlags & ~UInt16(0x10) : n.graphFlags | 0x10;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:o));return true}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
