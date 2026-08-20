import Foundation

struct SM64WaterAirBubbleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterAirBubbleOutput
    let spawnedBubbles: [SM64ObjectID]
}

final class SM64WaterAirBubbleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_776162
    static let bubbleMaybeBehaviorIdentity: UInt64 = SM64BubbleMaybeObjectBridge.defaultBehaviorIdentity
    static let defaultModel: UInt32 = 0

    private let bubbleMaybeBridge: SM64BubbleMaybeObjectBridge?

    private struct State {
        let waterLevel: Float
        var angleF4: Int32
        var velocityY: Float
        var forwardVelocity: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaterAirBubbleObjectEffectRecord] = []

    init(bubbleMaybeBridge: SM64BubbleMaybeObjectBridge? = nil) {
        self.bubbleMaybeBridge = bubbleMaybeBridge
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
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: Self.defaultModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, waterLevel: waterLevel, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water-air bubble could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        waterLevel: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(waterLevel: waterLevel, angleF4: 0, velocityY: 0, forwardVelocity: 0)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: 4, y: 4, z: 4)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WaterAirBubbleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let marioPosition = engineState.globals.marioObject.flatMap {
            engineState.objects.record(for: $0)?.position
        } ?? .zero
        let output = SM64WaterAirBubbleBehavior.update(
            SM64WaterAirBubbleInput(
                position: record.position,
                angleF4: state.angleF4,
                timer: record.timer,
                velocityY: state.velocityY,
                forwardVelocity: state.forwardVelocity,
                moveYaw: record.moveAngles.yaw,
                marioPosition: marioPosition,
                randomJitterX: 0,
                randomJitterZ: 0,
                waterLevel: state.waterLevel,
                interacted: record.interactionStatus != 0
            )
        )
        state.angleF4 = output.angleF4
        state.velocityY = output.velocityY
        state.forwardVelocity = output.forwardVelocity
        states[id] = state
        var spawned: [SM64ObjectID] = []
        if output.spawnBubbleCount > 0 {
            for _ in 0..<output.spawnBubbleCount {
                if let child = try? engineState.spawnObject(
                    in: .unimportant,
                    model: 0,
                    behaviorIdentity: Self.bubbleMaybeBehaviorIdentity,
                    parent: id
                ) {
                    spawned.append(child)
                    _ = bubbleMaybeBridge?.attach(
                        child,
                        position: record.position,
                        randomOffsetX: 0,
                        randomOffsetY: 0,
                        randomOffsetZ: 0,
                        randomStepX: 0,
                        randomStepY: 0,
                        randomStepZ: 0,
                        angleF4: 0,
                        angleF8: 0,
                        expansionRateX: 0x800,
                        expansionRateY: 0x800,
                        in: engineState.objects
                    )
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale.x = output.scaleX
            next.scale.y = output.scaleY
            next.moveAngles.yaw = output.moveYaw
            next.timer = output.timer
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.interactionStatus = 0
            next.intangibleTimer = output.intangible ? 1 : -1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64WaterAirBubbleObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedBubbles: spawned
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
