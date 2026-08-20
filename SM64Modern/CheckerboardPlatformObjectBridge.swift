import Foundation

struct SM64CheckerboardPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let output: SM64CheckerboardPlatformOutput
}

/// Owner bridge for the checkerboard spawner and its two moving children.
final class SM64CheckerboardPlatformObjectBridge {
    static let groupBehaviorIdentity: UInt64 = 0x6268_765F_636267
    static let childBehaviorIdentity: UInt64 = 0x6268_765F_636273
    static let defaultModel: UInt32 = 0

    private struct State {
        let kind: SM64CheckerboardPlatformKind
        let parentID: SM64ObjectID?
        let waitTime: Int32
        let childParameter: Int32
        let speed: Float
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CheckerboardPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnGroup(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        variant: UInt8 = 0,
        waitTime: Int32 = 65,
        model: UInt32 = SM64CheckerboardPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let actualWait = waitTime == 0 ? 65 : waitTime
        let center: Float = variant == 0 ? 145 : 235
        let speed: Float = variant == 0 ? 7 : 11.6
        let group = try engineState.spawnObject(in: .spawner, model: model,
                                                behaviorIdentity: Self.groupBehaviorIdentity)
        guard attachGroup(group, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(group); preconditionFailure("checkerboard group attach failed")
        }
        for index in 0..<2 {
            let child = try engineState.spawnObject(in: .surface, model: model,
                                                    behaviorIdentity: Self.childBehaviorIdentity,
                                                    parent: group)
            let childPosition = SM64ObjectVector3(
                x: position.x,
                y: position.y + Float(index) * Float(actualWait * 10),
                z: position.z + (index == 0 ? -center : center)
            )
            guard attachChild(child, parent: group, index: Int32(index), waitTime: actualWait,
                              speed: speed, position: childPosition, in: engineState.objects) else {
                _ = engineState.objects.despawn(child); preconditionFailure("checkerboard child attach failed")
            }
        }
        return group
    }

    @discardableResult
    func attachGroup(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: .group, parentID: nil, waitTime: 0, childParameter: 0, speed: 0)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position
            record.activeFlags = 0
        }
    }

    @discardableResult
    func attachChild(_ id: SM64ObjectID, parent: SM64ObjectID, index: Int32,
                     waitTime: Int32, speed: Float, position: SM64ObjectVector3,
                     in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil,
              (0...1).contains(index), waitTime >= 0, speed.isFinite else { return false }
        states[id] = State(kind: .child, parentID: parent, waitTime: waitTime,
                            childParameter: index, speed: speed)
        return pool.mutate(id) { record in
            record.parent = parent; record.position = position; record.homePosition = position
            record.scale = index == 0 ? .init(x: 0.7, y: 1.5, z: 0.7) : .init(x: 1.2, y: 2, z: 1.2)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState)
        -> SM64CheckerboardPlatformObjectEffectRecord?
    {
        guard let child = states[id], child.kind == .child,
              let parentID = child.parentID,
              let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64CheckerboardPlatformBehavior.update(
            SM64CheckerboardPlatformInput(
                kind: .child, action: record.action, timer: record.timer,
                waitTime: child.waitTime, childParameter: child.childParameter, speed: child.speed,
                positionX: record.position.x, positionY: record.position.y, positionZ: record.position.z,
                moveYaw: record.moveAngles.yaw, movePitch: record.moveAngles.pitch,
                facePitch: record.faceAngles.pitch, angleVelocityPitch: record.angleVelocity.pitch,
                forwardVelocity: record.forwardVelocity, velocityY: record.velocity.y
            )
        )
        let nextTimer = output.timer == record.timer && output.action == record.action
            ? record.timer &+ 1 : output.timer
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action; next.timer = nextTimer
            next.position = .init(x: output.positionX, y: output.positionY, z: output.positionZ)
            next.moveAngles.pitch = output.movePitch; next.faceAngles.pitch = output.facePitch
            next.angleVelocity.pitch = output.angleVelocityPitch; next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY; next.moveAngles.yaw = output.moveYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64CheckerboardPlatformObjectEffectRecord(objectID: id, parentID: parentID, output: output)
        effectLog.append(effect); return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
