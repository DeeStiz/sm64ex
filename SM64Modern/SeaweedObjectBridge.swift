import Foundation
struct SM64SeaweedObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let descriptor: SM64SeaweedDescriptor; let spawnedChildren:[SM64ObjectID] }
final class SM64SeaweedObjectBridge {
    static let seaweedBehaviorIdentity:UInt64=0x6268_765F_736577
    // Keep the bundle identity distinct from Scuttlebug's `...736275` bug
    // identity; both routes share the historical `bhv_` prefix.
    static let bundleBehaviorIdentity:UInt64=0x6268_765F_736562
    private var descriptors:[SM64ObjectID:SM64SeaweedDescriptor]=[:];private var bundles:Set<SM64ObjectID>=[];private(set) var effectLog:[SM64SeaweedObjectEffectRecord]=[]
    var registeredIDs:[SM64ObjectID]{var ids=Array(descriptors.keys);ids.append(contentsOf:bundles);return ids.sorted{$0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot}}
    func beginExternalTick(){effectLog.removeAll(keepingCapacity:true)}
    @discardableResult func spawnBundle(in engineState:SM64SwiftEngineState,position:SM64ObjectVector3 = .zero)throws->SM64ObjectID{let id=try engineState.spawnObject(in:.level,behaviorIdentity:Self.bundleBehaviorIdentity);guard attachBundle(id,position:position,in:engineState.objects)else{_ = engineState.objects.despawn(id);preconditionFailure("newly spawned seaweed bundle could not attach")};return id}
    @discardableResult func attachBundle(_ id:SM64ObjectID,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};bundles.insert(id);return pool.mutate(id){r in r.position=position;r.homePosition=position;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func attachSeaweed(_ id:SM64ObjectID,descriptor:SM64SeaweedDescriptor,position:SM64ObjectVector3,in pool:SM64ObjectPool)->Bool{guard pool.record(for:id) != nil else{return false};descriptors[id]=descriptor;return pool.mutate(id){r in r.position=position;r.homePosition=position;r.faceAngles=descriptor.faceAngles;r.scale=descriptor.scale;r.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle|SM64ObjectScheduler.objectFlagBuildTransform}}
    @discardableResult func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if bundles.contains(id), let record = engineState.objects.record(for: id) {
            var children: [SM64ObjectID] = []
            if record.timer == 0 {
                for descriptor in SM64SeaweedBehavior.bundleDescriptors {
                    if let child = try? engineState.spawnObject(in: .level, behaviorIdentity: Self.seaweedBehaviorIdentity, parent: id),
                       attachSeaweed(child, descriptor: descriptor, position: record.position, in: engineState.objects) {
                        children.append(child)
                    }
                }
                _ = engineState.objects.mutate(id) { $0.timer = 1 }
            }
            effectLog.append(.init(objectID: id, descriptor: .init(faceAngles: .zero, scale: .one), spawnedChildren: children))
            return true
        }
        if let descriptor = descriptors[id] {
            effectLog.append(.init(objectID: id, descriptor: descriptor, spawnedChildren: []))
            return true
        }
        return false
    }
    func remove(_ id:SM64ObjectID){descriptors.removeValue(forKey:id);bundles.remove(id)}
    func pruneExternal(unloaded:[SM64ObjectID],pool:SM64ObjectPool){for id in unloaded{remove(id)};for id in registeredIDs where pool.record(for:id)==nil{remove(id)}}
}
