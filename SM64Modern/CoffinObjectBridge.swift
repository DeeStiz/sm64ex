import Foundation

struct SM64CoffinObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CoffinOutput
    let spawnedCoffins: [SM64ObjectID]
}

final class SM64CoffinObjectBridge {
    static let spawnerBehaviorIdentity: UInt64 = 0x6268_765F_636673
    static let coffinBehaviorIdentity: UInt64 = 0x6268_765F_63666E
    static let collisionDataIdentity: UInt64 = 0x6262685F636F6666

    private var roles: [SM64ObjectID: SM64CoffinRole] = [:]
    private(set) var effectLog: [SM64CoffinObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        roles.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 10_000) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.spawnerBehaviorIdentity)
        guard attach(id, role: .spawner, position: position, distanceToMario: distanceToMario, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned coffin spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, role: SM64CoffinRole, position: SM64ObjectVector3, distanceToMario: Float = 10_000, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        roles[id] = role
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.distanceToMario = distanceToMario
            if role == .coffin {
                record.collisionDataIdentity = Self.collisionDataIdentity
                record.collisionDistance = 4_000
                record.interactionType = 1 << 1
                record.hitboxRadius = 150
                record.hitboxHeight = 250
            }
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let role = roles[id], let record = engineState.objects.record(for: id) else { return false }
        if role == .spawner {
            let output = SM64CoffinBehavior.updateSpawner(timer: record.timer, inDifferentRoom: record.room >= 0 && record.room != 0)
            var children: [SM64ObjectID] = []
            if output.spawnCoffins {
                for (index, relative) in SM64CoffinBehavior.relativePositions.enumerated() {
                    if let child = try? engineState.spawnObject(in: .surface, behaviorIdentity: Self.coffinBehaviorIdentity, parent: id) {
                        roles[child] = .coffin
                        _ = attach(child, role: .coffin, position: .init(x: record.position.x + relative.x, y: record.position.y, z: record.position.z + relative.z), distanceToMario: record.distanceToMario, in: engineState.objects)
                        _ = engineState.objects.mutate(child) { next in
                            next.behaviorParams2ndByte = Int32(index & 1)
                            next.faceAngles.yaw = relative.z > 0 ? 0x8000 : 0
                        }
                        children.append(child)
                    }
                }
            }
            _ = engineState.objects.mutate(id) { $0.timer &+= 1 }
            effectLog.append(.init(objectID: id, output: output, spawnedCoffins: children))
            return true
        }

        let staticCoffin = record.behaviorParams2ndByte == 0
        let output = SM64CoffinBehavior.updateCoffin(
            action: SM64CoffinAction(rawValue: UInt8(clamping: record.action)) ?? .idle,
            timer: record.timer,
            staticCoffin: staticCoffin,
            distanceToMario: record.distanceToMario,
            faceAngles: record.faceAngles
        )
        _ = engineState.objects.mutate(id) { next in
            next.action = Int32(output.action.rawValue)
            next.faceAngles = output.faceAngles
            next.scale = output.scale
            next.collisionDataIdentity = Self.collisionDataIdentity
            next.interactionStatus = 0
            next.timer = output.action == .standUp ? record.timer &+ 1 : 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        _ = engineState.bindPlatformCollisionOwner(id, surfaceIDs: [0x305])
        effectLog.append(.init(objectID: id, output: output, spawnedCoffins: []))
        return true
    }

    func remove(_ id: SM64ObjectID) { roles.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
