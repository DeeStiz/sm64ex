import Foundation

struct SM64BoulderObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BoulderOutput }
struct SM64BoulderGeneratorEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BoulderGeneratorOutput; let spawnedBoulder: SM64ObjectID? }

final class SM64BoulderObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62626F_31
    static let generatorBehaviorIdentity: UInt64 = 0x6268_765F_626267
    static let collisionDistance: Float = 20_000
    private var registered: Set<SM64ObjectID> = []
    private var generators: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64BoulderObjectEffectRecord] = []
    private(set) var generatorEffectLog: [SM64BoulderGeneratorEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true); generatorEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, position: position, moveYaw: moveYaw, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned boulder could not attach") }
        return id
    }

    @discardableResult
    func spawnGenerator(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, timer: Int32 = 0, distanceToMario: Float = 10_000, currentRoomIsFour: Bool = true) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.generatorBehaviorIdentity)
        guard attachGenerator(id, position: position, timer: timer, distanceToMario: distanceToMario, currentRoomIsFour: currentRoomIsFour, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned boulder generator could not attach") }
        return id
    }

    @discardableResult
    func attachGenerator(_ id: SM64ObjectID, position: SM64ObjectVector3, timer: Int32, distanceToMario: Float, currentRoomIsFour: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        generators.insert(id)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.timer = timer; record.distanceToMario = distanceToMario; record.room = currentRoomIsFour ? 4 : 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.collisionDistance = Self.collisionDistance; record.graphYOffset = 180; record.interactionType = 1 << 3; record.damageOrCoinValue = 3; record.hitboxRadius = 210; record.hitboxHeight = 350; record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if generators.contains(id), let record = engineState.objects.record(for: id) {
            let output = SM64BoulderGeneratorBehavior.update(timer: record.timer, distanceToMario: record.distanceToMario, currentRoomIsFour: record.room == 4)
            var child: SM64ObjectID?
            if output.shouldSpawn { child = try? spawn(in: engineState, position: record.position, moveYaw: 0, parent: id) }
            _ = engineState.objects.mutate(id) { $0.timer = output.timer }
            generatorEffectLog.append(.init(objectID: id, output: output, spawnedBoulder: child)); return true
        }
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let action = SM64BoulderAction(rawValue: UInt8(clamping: record.action)) ?? .initialize
        let output = SM64BoulderBehavior.update(.init(action: action, position: record.position, velocityY: record.velocity.y, forwardVelocity: record.forwardVelocity, moveYaw: record.moveAngles.yaw, facePitch: record.faceAngles.pitch, stepFlags: record.moveFlags))
        _ = engineState.objects.mutate(id) { next in
            next.action = Int32(output.action.rawValue); next.forwardVelocity = output.forwardVelocity; next.velocity.y = output.velocityY; next.faceAngles.pitch = output.facePitch; next.faceAngles.yaw = output.moveYaw; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.graphYOffset = output.graphYOffset; next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight; next.interactionType = 1 << 3; next.interactionStatus = 0; next.intangibleTimer = 0; next.collisionDistance = Self.collisionDistance; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id); generators.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) }; for id in generators where pool.record(for: id) == nil { remove(id) } }
}
