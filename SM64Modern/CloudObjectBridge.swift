import Foundation

struct SM64CloudObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CloudOutput; let spawnedParts: [SM64ObjectID]; let spawnedWindParticles: [SM64ObjectID] }

final class SM64CloudObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636C64
    private struct State { let kind: SM64CloudKind; let homePosition: SM64ObjectVector3; let parentPosition: SM64ObjectVector3; let parentActive: Bool; let parentFaceYaw: Int32; let distanceToMario: Float; var action: SM64CloudAction; var scale: Float; var movementRadius: Int32; var timer: Int32; var blowing: Bool; var growSpeed: Float; var children: [SM64ObjectID] }
    private let partBridge: SM64CloudPartObjectBridge
    private let windBridge: SM64StrongWindParticleObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CloudObjectEffectRecord] = []
    init(partBridge: SM64CloudPartObjectBridge, windBridge: SM64StrongWindParticleObjectBridge? = nil) { self.partBridge = partBridge; self.windBridge = windBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnCloud(in engineState: SM64SwiftEngineState, kind: SM64CloudKind = .fwoosh, position: SM64ObjectVector3 = .zero, parentPosition: SM64ObjectVector3 = .zero, parentActive: Bool = true, parentFaceYaw: Int32 = 0, distanceToMario: Float = 1_000, scale: Float = 3, action: SM64CloudAction = .spawnParts, timer: Int32 = 0, blowing: Bool = false, growSpeed: Float = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, kind: kind, position: position, parentPosition: parentPosition, parentActive: parentActive, parentFaceYaw: parentFaceYaw, distanceToMario: distanceToMario, scale: scale, action: action, timer: timer, blowing: blowing, growSpeed: growSpeed, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned cloud could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64CloudKind, position: SM64ObjectVector3, parentPosition: SM64ObjectVector3, parentActive: Bool, parentFaceYaw: Int32, distanceToMario: Float, scale: Float, action: SM64CloudAction, timer: Int32 = 0, blowing: Bool = false, growSpeed: Float = 0, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, homePosition: position, parentPosition: parentPosition, parentActive: parentActive, parentFaceYaw: parentFaceYaw, distanceToMario: distanceToMario, action: action, scale: scale, movementRadius: 0, timer: timer, blowing: blowing, growSpeed: growSpeed, children: [])
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.scale = .init(x: scale, y: scale, z: scale); record.action = action.rawValue; record.timer = timer; record.behaviorParams2ndByte = Int32(kind.rawValue); record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CloudObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64CloudBehavior.update(.init(kind: state.kind, action: state.action, position: record.position, homePosition: state.homePosition, parentPosition: state.parentPosition, parentActive: state.parentActive, parentFaceYaw: state.parentFaceYaw, distanceToMario: state.distanceToMario, scale: state.scale, movementRadius: state.movementRadius, globalFrame: engineState.globals.frame, timer: state.timer, blowing: state.blowing, growSpeed: state.growSpeed))
        var parts: [SM64ObjectID] = []
        var windParticles: [SM64ObjectID] = []
        if output.childPartCount > 0 {
            for index in 0..<output.childPartCount { if let part = try? partBridge.spawnPart(in: engineState, parentCenterX: output.centerX, parentCenterY: output.centerY, parentPositionZ: output.position.z, parentFaceYaw: output.faceYaw, parentScale: output.scale, partIndex: index, parent: id) { parts.append(part) } }
            state.children = parts
        } else { for part in state.children { _ = partBridge.updateParentState(part, centerX: output.centerX, centerY: output.centerY, positionZ: output.position.z, faceYaw: output.faceYaw, scale: output.scale, unloading: output.hidden) } }
        if output.spawnWindParticles, let windBridge {
            let windOrigin = SM64ObjectVector3(x: output.position.x, y: output.position.y - 50, z: output.position.z + 120)
            let spawnTiny = engineState.globals.frame & 1 != 0
            let spawnCount = spawnTiny ? 3 : 2
            for index in 0..<spawnCount {
                let kind: SM64StrongWindParticleKind = spawnTiny && index == 0 ? .tiny : .visible
                if let particle = try? windBridge.spawnParticle(in: engineState, kind: kind, position: windOrigin, moveYaw: output.faceYaw, movePitch: 0, initialRandomX: 0, initialRandomY: 0, initialRandomZ: 0, initialYawJitter: 0, windSpread: 12, penguinCollisionPosition: nil, parent: id) { windParticles.append(particle) }
            }
        }
        state.action = output.action; state.scale = output.scale; state.movementRadius = output.movementRadius; state.timer = output.timer; state.blowing = output.blowing; state.growSpeed = output.growSpeed; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.action = output.action.rawValue; next.timer = output.timer &+ 1; if output.shouldDelete { next.activeFlags = 0 }; next.graphFlags = output.hidden ? next.graphFlags | 0x10 : next.graphFlags & ~UInt16(0x10); next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64CloudObjectEffectRecord(objectID: id, output: output, spawnedParts: parts, spawnedWindParticles: windParticles); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
