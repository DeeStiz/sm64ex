import Foundation
struct SM64LllWoodPieceObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let parentID: SM64ObjectID; let output: SM64LllWoodPieceOutput }
struct SM64LllFloatingWoodBridgeObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64LllFloatingWoodBridgeOutput; let spawnedChildren: [SM64ObjectID] }

final class SM64LllWoodPieceObjectBridge {
    static let behaviorIdentity: UInt64 = 0x6268_765F_6C7770
    private struct State { let parentID: SM64ObjectID; var oscillationTimer: Int32 }
    private var states:[SM64ObjectID:State]=[:]; private(set) var effectLog:[SM64LllWoodPieceObjectEffectRecord]=[]
    var registeredIDs:[SM64ObjectID]{states.keys.sorted{$0.slot==$1.slot ? $0.generation<$1.generation:$0.slot<$1.slot}}
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnPiece(in e:SM64SwiftEngineState,parent:SM64ObjectID,position:SM64ObjectVector3,oscillationTimer:Int32)throws->SM64ObjectID{let id=try e.spawnObject(in:.surface,model:0,behaviorIdentity:Self.behaviorIdentity,parent:parent);guard attach(id,parent:parent,position:position,oscillationTimer:oscillationTimer,in:e.objects)else{_ = e.objects.despawn(id);preconditionFailure("wood piece attach failed")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,parent:SM64ObjectID,position:SM64ObjectVector3,oscillationTimer:Int32,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil,pool.record(for:parent) != nil else{return false};states[id]=State(parentID:parent,oscillationTimer:oscillationTimer);return pool.mutate(id){r in r.parent=parent;r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->SM64LllWoodPieceObjectEffectRecord?{guard var s=states[id],let p=e.objects.record(for:s.parentID),let r=e.objects.record(for:id)else{return nil};let o=SM64LllWoodPieceBehavior.update(.init(timer:r.timer,positionY:r.position.y,homeY:r.homePosition.y,oscillationTimer:s.oscillationTimer,parentAction:p.action));s.oscillationTimer=o.oscillationTimer;states[id]=s;_ = e.objects.mutate(id){n in n.position.y=o.positionY;n.timer=r.timer&+1;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform;if o.shouldDelete{n.activeFlags=0}};let x=SM64LllWoodPieceObjectEffectRecord(objectID:id,parentID:s.parentID,output:o);effectLog.append(x);return x}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}

final class SM64LllFloatingWoodBridgeObjectBridge {
    static let behaviorIdentity: UInt64 = 0x6268_765F_6C7762
    private let pieceBridge:SM64LllWoodPieceObjectBridge;private var groups:Set<SM64ObjectID>=[];private(set) var effectLog:[SM64LllFloatingWoodBridgeObjectEffectRecord]=[]
    init(pieceBridge:SM64LllWoodPieceObjectBridge){self.pieceBridge=pieceBridge}
    var registeredIDs:[SM64ObjectID]{groups.sorted{$0.slot==$1.slot ? $0.generation<$1.generation:$0.slot<$1.slot}}
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnBridge(in e:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try e.spawnObject(in:.default,model:0,behaviorIdentity:Self.behaviorIdentity);guard attach(id,position:position,in:e.objects)else{_ = e.objects.despawn(id);preconditionFailure("wood bridge attach failed")};return id}
    @discardableResult func attach(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};groups.insert(id);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->SM64LllFloatingWoodBridgeObjectEffectRecord?{guard groups.contains(id),let r=e.objects.record(for:id)else{return nil};let o=SM64LllFloatingWoodBridgeBehavior.update(.init(action:r.action,distanceToMario:r.distanceToMario));var children:[SM64ObjectID]=[];if o.spawnChildren{for i in 1...3{if let c=try? pieceBridge.spawnPiece(in:e,parent:id,position:.init(x:r.position.x+Float((i-2)*300),y:r.position.y,z:r.position.z),oscillationTimer:Int32(i*4096)){children.append(c)}}};_ = e.objects.mutate(id){n in n.action=o.action;n.timer=r.timer&+1};let x=SM64LllFloatingWoodBridgeObjectEffectRecord(objectID:id,output:o,spawnedChildren:children);effectLog.append(x);return x}
    func remove(_ id:SM64ObjectID){groups.remove(id)};func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
