import Foundation

struct SM64BubbleMaybeObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BubbleMaybeOutput
}

final class SM64BubbleMaybeObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626D_6231

    private struct State {
        let randomOffsetX: Float
        let randomOffsetY: Float
        let randomOffsetZ: Float
        let randomStepX: Float
        let randomStepY: Float
        let randomStepZ: Float
        var angleF4: Int32
        var angleF8: Int32
        let expansionRateX: Int32
        let expansionRateY: Int32
        var timer: Int32
        var animationState: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BubbleMaybeObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBubble(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil,
        randomOffsetX: Float = 0,
        randomOffsetY: Float = 0,
        randomOffsetZ: Float = 0,
        randomStepX: Float = 0,
        randomStepY: Float = 0,
        randomStepZ: Float = 0,
        angleF4: Int32 = 0,
        angleF8: Int32 = 0,
        expansionRateX: Int32 = 0x800,
        expansionRateY: Int32 = 0x800
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(
            id,
            position: position,
            randomOffsetX: randomOffsetX,
            randomOffsetY: randomOffsetY,
            randomOffsetZ: randomOffsetZ,
            randomStepX: randomStepX,
            randomStepY: randomStepY,
            randomStepZ: randomStepZ,
            angleF4: angleF4,
            angleF8: angleF8,
            expansionRateX: expansionRateX,
            expansionRateY: expansionRateY,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned bubble-maybe could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        randomOffsetX: Float,
        randomOffsetY: Float,
        randomOffsetZ: Float,
        randomStepX: Float,
        randomStepY: Float,
        randomStepZ: Float,
        angleF4: Int32,
        angleF8: Int32,
        expansionRateX: Int32,
        expansionRateY: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            randomOffsetX: randomOffsetX,
            randomOffsetY: randomOffsetY,
            randomOffsetZ: randomOffsetZ,
            randomStepX: randomStepX,
            randomStepY: randomStepY,
            randomStepZ: randomStepZ,
            angleF4: angleF4,
            angleF8: angleF8,
            expansionRateX: expansionRateX,
            expansionRateY: expansionRateY,
            timer: 0,
            animationState: -1
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.animationState = -1
            record.scale = .one
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64BubbleMaybeObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64BubbleMaybeBehavior.update(
            SM64BubbleMaybeInput(
                position: record.position,
                randomOffsetX: state.timer == 0 ? state.randomOffsetX : 0,
                randomOffsetY: state.timer == 0 ? state.randomOffsetY : 0,
                randomOffsetZ: state.timer == 0 ? state.randomOffsetZ : 0,
                randomStepX: state.randomStepX,
                randomStepY: state.randomStepY,
                randomStepZ: state.randomStepZ,
                angleF4: state.angleF4,
                angleF8: state.angleF8,
                expansionRateX: state.expansionRateX,
                expansionRateY: state.expansionRateY,
                timer: state.timer,
                animationState: state.animationState
            )
        )
        state.angleF4 = output.angleF4
        state.angleF8 = output.angleF8
        state.timer &+= 1
        state.animationState = output.animationState
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale = SM64ObjectVector3(x: output.scaleX, y: output.scaleY, z: 1)
            next.animationState = output.animationState
            next.timer = state.timer
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64BubbleMaybeObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
