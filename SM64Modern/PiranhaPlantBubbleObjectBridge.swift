import Foundation

struct SM64PiranhaPlantBubbleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64PiranhaPlantBubbleOutput
    let spawnedWakingBubbles: [SM64ObjectID]
}

final class SM64PiranhaPlantBubbleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7070_6231

    private struct State {
        let parentID: SM64ObjectID
        let lastAnimationFrame: Int32
        var action: SM64PiranhaPlantBubbleAction
    }

    private let wakingBubbleBridge: SM64PiranhaPlantWakingBubbleObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64PiranhaPlantBubbleObjectEffectRecord] = []

    init(wakingBubbleBridge: SM64PiranhaPlantWakingBubbleObjectBridge? = nil) {
        self.wakingBubbleBridge = wakingBubbleBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBubble(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        lastAnimationFrame: Int32 = 30
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(
            id,
            parent: parent,
            lastAnimationFrame: lastAnimationFrame,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Piranha Plant bubble could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        lastAnimationFrame: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        states[id] = State(
            parentID: parent,
            lastAnimationFrame: lastAnimationFrame,
            action: .idle
        )
        return pool.mutate(id) { record in
            record.parent = parent
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64PiranhaPlantBubbleObjectEffectRecord? {
        guard var state = states[id], let parent = engineState.objects.record(for: state.parentID),
              let record = engineState.objects.record(for: id) else { return nil }
        let parentSleeping = parent.action == Int32(SM64PiranhaPlantAction.sleeping.rawValue)
        let output = SM64PiranhaPlantBubbleBehavior.update(
            SM64PiranhaPlantBubbleInput(
                parentPosition: parent.position,
                parentYaw: parent.moveAngles.yaw,
                parentSleeping: parentSleeping,
                parentFrame: parent.animationState,
                lastAnimationFrame: state.lastAnimationFrame,
                activeWithinRadius: parent.distanceToMario < parent.drawingDistance,
                action: state.action
            )
        )
        state.action = output.action
        states[id] = state
        var spawned: [SM64ObjectID] = []
        for _ in 0..<output.spawnWakingBubbleCount {
            if let child = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: SM64PiranhaPlantWakingBubbleObjectBridge.defaultBehaviorIdentity,
                parent: id
            ) {
                spawned.append(child)
                _ = wakingBubbleBridge?.attach(
                    child,
                    position: output.position,
                    initialMoveYaw: 0,
                    initialForwardVelocity: 10,
                    initialVelocityY: 10,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.graphFlags = output.hidden ? next.graphFlags | 0x10 : next.graphFlags & ~UInt16(0x10)
            next.action = Int32(output.action.rawValue)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64PiranhaPlantBubbleObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedWakingBubbles: spawned
        )
        effectLog.append(effect)
        _ = record
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
