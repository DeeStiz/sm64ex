import Foundation

struct SM64ButterflyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ButterflyOutput
}

final class SM64ButterflyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_627466
    static let defaultModel: UInt32 = 0x5A // MODEL_BUTTERFLY
    private struct State { var yPhase: Int32; var distanceToMario: Float; var homeDistance: Float; var angleToMario: Int32; var angleToHome: Int32; var pitchToHome: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ButterflyObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawnButterfly(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id=try engineState.spawnObject(in:.default,model:Self.defaultModel,behaviorIdentity:Self.defaultBehaviorIdentity);guard attach(id,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned butterfly could not attach")};return id }
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(yPhase:0,distanceToMario:10_000,homeDistance:0,angleToMario:0,angleToHome:0,pitchToHome:0);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func setInput(distanceToMario:Float,homeDistance:Float,angleToMario:Int32,angleToHome:Int32=0,pitchToHome:Int32=0,for id:SM64ObjectID)->Bool{guard var s=states[id]else{return false};s.distanceToMario=distanceToMario;s.homeDistance=homeDistance;s.angleToMario=angleToMario;s.angleToHome=angleToHome;s.pitchToHome=pitchToHome;states[id]=s;return true}
    @discardableResult func updateInline(_ id:SM64ObjectID,state engineState:SM64SwiftEngineState)->Bool{guard var s=states[id],let r=engineState.objects.record(for:id)else{return false};let dx=r.position.x-r.homePosition.x;let dy=r.position.y-r.homePosition.y;let dz=r.position.z-r.homePosition.z;let output=SM64ButterflyBehavior.update(.init(action:SM64ButterflyAction(rawValue:r.action) ?? .resting,position:r.position,homePosition:r.homePosition,moveYaw:r.moveAngles.yaw,movePitch:r.faceAngles.pitch,yPhase:s.yPhase,distanceToMario:s.distanceToMario,homeDistance:s.homeDistance == 0 ? (dx*dx+dy*dy+dz*dz).squareRoot():s.homeDistance,angleToMario:s.angleToMario,angleToHome:s.angleToHome,pitchToHome:s.pitchToHome));s.yPhase=output.yPhase;s.distanceToMario=10_000;states[id]=s;_ = engineState.objects.mutate(id){n in n.action=output.action.rawValue;n.position=output.position;n.moveAngles.yaw=output.moveYaw;n.faceAngles.pitch=output.movePitch;n.animationState=output.animationState;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};effectLog.append(.init(objectID:id,output:output));return true}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
