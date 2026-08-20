import Foundation

struct SM64FerrisWheelPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let platformIndex: Int32
    let output: SM64FerrisWheelPlatformOutput
}

/// Owner-thread bridge for a Ferris-wheel axle and its four parent-relative
/// platform children. The axle has no native loop; its authored behavior
/// script remains the source of roll changes.
final class SM64FerrisWheelPlatformObjectBridge {
    static let axleBehaviorIdentity: UInt64 = 0x6268_765F_667761
    static let platformBehaviorIdentity: UInt64 = 0x6268_765F_667770
    static let defaultModel: UInt32 = 0

    private enum Kind { case axle, platform }
    private struct State {
        let kind: Kind
        let parentID: SM64ObjectID?
        let platformIndex: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FerrisWheelPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    /// Spawns the authored axle plus four platform children in source order.
    @discardableResult
    func spawnAxle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64FerrisWheelPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let axle = try engineState.spawnObject(in: .level, model: model,
                                               behaviorIdentity: Self.axleBehaviorIdentity)
        guard attachAxle(axle, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(axle)
            preconditionFailure("newly spawned Ferris wheel axle could not attach")
        }
        for index in 0..<4 {
            let child = try engineState.spawnObject(
                in: .level,
                model: model,
                behaviorIdentity: Self.platformBehaviorIdentity,
                parent: axle
            )
            guard attachPlatform(child, parent: axle, index: Int32(index), in: engineState.objects) else {
                _ = engineState.objects.despawn(child)
                preconditionFailure("newly spawned Ferris wheel platform could not attach")
            }
        }
        return axle
    }

    @discardableResult
    func attachAxle(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero,
                    in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: .axle, parentID: nil, platformIndex: -1)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachPlatform(_ id: SM64ObjectID, parent: SM64ObjectID, index: Int32,
                        in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil,
              (0..<4).contains(index) else { return false }
        states[id] = State(kind: .platform, parentID: parent, platformIndex: index)
        return pool.mutate(id) { record in
            record.parent = parent
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState)
        -> SM64FerrisWheelPlatformObjectEffectRecord?
    {
        guard let child = states[id], child.kind == .platform,
              let parentID = child.parentID,
              let parent = engineState.objects.record(for: parentID),
              let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FerrisWheelPlatformBehavior.update(
            SM64FerrisWheelPlatformInput(
                parentPosition: SM64FerrisWheelVector3(
                    x: parent.position.x, y: parent.position.y, z: parent.position.z
                ),
                parentRoll: Int16(truncatingIfNeeded: parent.faceAngles.roll),
                parentMoveYaw: Int16(truncatingIfNeeded: parent.moveAngles.yaw),
                platformIndex: child.platformIndex,
                previousPosition: SM64FerrisWheelVector3(
                    x: record.position.x, y: record.position.y, z: record.position.z
                )
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = SM64ObjectVector3(
                x: output.position.x, y: output.position.y, z: output.position.z
            )
            next.velocity = SM64ObjectVector3(
                x: output.velocity.x, y: output.velocity.y, z: output.velocity.z
            )
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64FerrisWheelPlatformObjectEffectRecord(
            objectID: id, parentID: parentID, platformIndex: child.platformIndex, output: output
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs {
            guard let state = states[id], pool.record(for: id) != nil else { remove(id); continue }
            if let parent = state.parentID, pool.record(for: parent) == nil { remove(id) }
        }
    }
}
