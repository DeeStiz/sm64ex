import Foundation

struct SM64BitfsSinkingPlatformObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BitfsSinkingPlatformOutput }

/// Shared owner route for BITFS sinking platform and cage identities.
final class SM64BitfsSinkingPlatformObjectBridge {
    static let platformBehaviorIdentity: UInt64 = 0x6268_765F_627370
    static let cageBehaviorIdentity: UInt64 = 0x6268_765F_627363
    static let defaultModel: UInt32 = 0
    private let poleBridge: SM64DddMovingPoleObjectBridge
    private struct State { let kind: SM64BitfsSinkingPlatformKind; let cageParameter: UInt8; var platformTimer: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BitfsSinkingPlatformObjectEffectRecord] = []

    init(poleBridge: SM64DddMovingPoleObjectBridge) { self.poleBridge = poleBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}

    @discardableResult func spawnPlatform(in engineState: SM64SwiftEngineState, positionY: Float = 0, model: UInt32 = SM64BitfsSinkingPlatformObjectBridge.defaultModel) throws -> SM64ObjectID { try spawn(in:engineState,kind:.platform,positionY:positionY,cageParameter:0,model:model,identity:Self.platformBehaviorIdentity) }
    @discardableResult func spawnCage(in engineState: SM64SwiftEngineState, positionY: Float = 0, cageParameter: UInt8 = 0, model: UInt32 = SM64BitfsSinkingPlatformObjectBridge.defaultModel) throws -> SM64ObjectID { let cage = try spawn(in:engineState,kind:.cage,positionY:positionY,cageParameter:cageParameter,model:model,identity:Self.cageBehaviorIdentity); _ = try? poleBridge.spawnPole(in:engineState,parent:cage); return cage }
    private func spawn(in e: SM64SwiftEngineState, kind: SM64BitfsSinkingPlatformKind, positionY: Float, cageParameter: UInt8, model: UInt32, identity: UInt64) throws -> SM64ObjectID { let id=try e.spawnObject(in:.level,model:model,behaviorIdentity:identity);guard attach(id,kind:kind,positionY:positionY,cageParameter:cageParameter,in:e.objects) else{_ = e.objects.despawn(id);preconditionFailure("newly spawned BITFS sinking object could not attach")};return id }
    @discardableResult func attach(_ id: SM64ObjectID,kind: SM64BitfsSinkingPlatformKind,positionY:Float,cageParameter:UInt8,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};states[id]=State(kind:kind,cageParameter:cageParameter,platformTimer:0);return pool.mutate(id){r in r.position.y=positionY;r.homePosition.y=positionY;r.behaviorParams2ndByte=Int32(cageParameter);r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id:SM64ObjectID,state e:SM64SwiftEngineState)->SM64BitfsSinkingPlatformObjectEffectRecord?{guard var s=states[id],let r=e.objects.record(for:id) else{return nil};let o=SM64BitfsSinkingPlatformBehavior.update(.init(kind:s.kind,timer:r.timer,positionY:r.position.y,platformTimer:s.platformTimer,cageParameter:s.cageParameter));s.platformTimer=o.platformTimer;states[id]=s;_ = e.objects.mutate(id){n in n.position.y=o.positionY;n.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform};let effect=SM64BitfsSinkingPlatformObjectEffectRecord(objectID:id,output:o);effectLog.append(effect);return effect}
    func remove(_ id:SM64ObjectID){states.removeValue(forKey:id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
