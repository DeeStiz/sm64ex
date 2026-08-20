import Foundation

struct SM64TextSurfaceObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64TextSurfaceOutput }
final class SM64TextSurfaceObjectBridge {
    static let messagePanelBehaviorIdentity: UInt64 = 0x6268_765F_6D706C
    static let signOnWallBehaviorIdentity: UInt64 = 0x6268_765F_736977
    private var kinds: [SM64ObjectID: SM64TextSurfaceKind] = [:]; private(set) var effectLog: [SM64TextSurfaceObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { kinds.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, kind: SM64TextSurfaceKind, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.identity(for: kind)); guard attach(id, kind: kind, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned text surface could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64TextSurfaceKind, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; kinds[id] = kind; return pool.mutate(id) { record in record.position = position; record.hitboxRadius = 150; record.hitboxHeight = 80; record.interactionType = 0x80000; record.interactionSubtype = 1; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard let kind = kinds[id], let record = engineState.objects.record(for: id) else { return false }; let output = SM64TextSurfaceBehavior.update(.init(kind: kind, timer: record.timer)); _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight; next.interactionStatus = 0 }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { kinds.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
    static func identity(for kind: SM64TextSurfaceKind) -> UInt64 { kind == .messagePanel ? messagePanelBehaviorIdentity : signOnWallBehaviorIdentity }
}
