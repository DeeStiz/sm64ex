import Foundation

struct SM64ActivatedBackAndForthPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ActivatedBackAndForthPlatformOutput
}

/// Owner-thread adapter for the activated BitS/BitFS platform.
final class SM64ActivatedBackAndForthPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_616266
    static let defaultModel: UInt32 = 0
    private struct State {
        var offset: Float
        var velocity: Float
        var countdown: Int32
        let maxOffset: Float
        let vertical: Bool
        let flipRotation: Int32
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ActivatedBackAndForthPlatformObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPlatform(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero,
                      faceYaw: Int32 = 0, behaviorByte: UInt8 = 0,
                      model: UInt32 = SM64ActivatedBackAndForthPlatformObjectBridge.defaultModel) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, faceYaw: faceYaw, behaviorByte: behaviorByte, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned activated platform could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero, faceYaw: Int32 = 0,
                behaviorByte: UInt8, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initialization = SM64ActivatedBackAndForthPlatformBehavior.initialize(behaviorByte: behaviorByte, faceYaw: faceYaw)
        states[id] = State(offset: 0, velocity: 0, countdown: 0, maxOffset: initialization.maxOffset, vertical: initialization.vertical, flipRotation: initialization.flipRotation)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.faceAngles.yaw = faceYaw; record.moveAngles.yaw = faceYaw
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64ActivatedBackAndForthPlatformObjectEffectRecord? {
        guard var platform = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64ActivatedBackAndForthPlatformBehavior.update(SM64ActivatedBackAndForthPlatformInput(
            offset: platform.offset, platformVelocity: platform.velocity, countdown: platform.countdown,
            marioOnPlatform: record.platform == id, distanceToMario: record.distanceToMario,
            positionX: record.position.x, positionY: record.position.y, positionZ: record.position.z,
            homeX: record.homePosition.x, homeY: record.homePosition.y, homeZ: record.homePosition.z,
            moveYaw: record.moveAngles.yaw, faceYaw: record.faceAngles.yaw, maxOffset: platform.maxOffset,
            vertical: platform.vertical, flipRotation: platform.flipRotation
        ))
        platform.offset = output.offset; platform.velocity = output.platformVelocity; platform.countdown = output.countdown; states[id] = platform
        _ = engineState.objects.mutate(id) { next in
            next.position = .init(x: output.positionX, y: output.positionY, z: output.positionZ); next.velocity.y = output.velocityY; next.faceAngles.yaw = output.faceYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64ActivatedBackAndForthPlatformObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
