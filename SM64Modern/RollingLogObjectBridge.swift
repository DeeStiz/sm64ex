import Foundation

struct SM64RollingLogObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RollingLogOutput
}

final class SM64RollingLogObjectBridge {
    static let ttmBehaviorIdentity: UInt64 = 0x6268_765F_726C67
    static let lllBehaviorIdentity: UInt64 = 0x6268_765F_6C7267
    private var variants: [SM64ObjectID: SM64RollingLogVariant] = [:]
    private(set) var effectLog: [SM64RollingLogObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { variants.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, variant: SM64RollingLogVariant, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let identity = variant == .ttm ? Self.ttmBehaviorIdentity : Self.lllBehaviorIdentity
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: identity)
        let yaw: Int32 = variant == .ttm ? 8_810 : 0x3FFF
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = yaw
            record.angleVelocity.pitch = 0
            record.faceAngles.pitch = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned rolling log could not attach") }
        variants[id] = variant
        return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let variant = variants[id], let record = engineState.objects.record(for: id) else { return false }
        let marioRecord = engineState.globals.marioObject.flatMap { engineState.objects.record(for: $0) }
        let dx = record.position.x - record.homePosition.x
        let dy = record.position.y - record.homePosition.y
        let dz = record.position.z - record.homePosition.z
        let output = SM64RollingLogBehavior.update(.init(
            variant: variant,
            position: record.position,
            homePosition: record.homePosition,
            moveYaw: record.moveAngles.yaw,
            angleVelocityPitch: record.angleVelocity.pitch,
            facePitch: record.faceAngles.pitch,
            marioIsPlatform: marioRecord?.platform == id,
            marioPosition: marioRecord?.position ?? .zero,
            nearHome: (dx * dx + dy * dy + dz * dz).squareRoot() < 100
        ))
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.velocity = output.velocity
            next.forwardVelocity = output.forwardVelocity
            next.angleVelocity.pitch = output.angleVelocityPitch
            next.faceAngles.pitch = output.facePitch
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { variants.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
