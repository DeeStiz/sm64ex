import Foundation

struct SM64ClamShellObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ClamShellOutput
    let spawnedBubbles: [SM64ObjectID]
}

final class SM64ClamShellObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636C6D
    static let defaultModel: UInt32 = 0x4D // MODEL_CLAM_SHELL

    private struct State {
        var shakeTimer: Int32
        var renderingEnabled: Bool
        var animationFrame25: Bool
        var animationFrame8: Bool
        var animationFrame30: Bool
    }

    private let bubbleBridge: SM64BubbleMaybeObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ClamShellObjectEffectRecord] = []

    init(bubbleBridge: SM64BubbleMaybeObjectBridge) { self.bubbleBridge = bubbleBridge }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnClam(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned clam shell could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(shakeTimer: 0, renderingEnabled: true, animationFrame25: false, animationFrame8: false, animationFrame30: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.interactionType = 1 << 13
            record.damageOrCoinValue = 2
            record.health = 99
            record.hitboxRadius = 150
            record.hitboxHeight = 80
            record.hurtboxRadius = 150
            record.hurtboxHeight = 80
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setAnimationInputs(
        renderingEnabled: Bool = true,
        frame25: Bool = false,
        frame8: Bool = false,
        frame30: Bool = false,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = states[id] else { return false }
        state.renderingEnabled = renderingEnabled
        state.animationFrame25 = frame25
        state.animationFrame8 = frame8
        state.animationFrame30 = frame30
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64ClamShellBehavior.update(.init(
            action: SM64ClamShellAction(rawValue: record.action) ?? .closed,
            timer: record.timer,
            shakeTimer: state.shakeTimer,
            distanceToMario: record.distanceToMario,
            animationFrame25: state.animationFrame25,
            animationFrame8: state.animationFrame8,
            animationFrame30: state.animationFrame30,
            renderingEnabled: state.renderingEnabled
        ))
        state.shakeTimer = output.shakeTimer
        state.animationFrame25 = false
        state.animationFrame8 = false
        state.animationFrame30 = false
        states[id] = state
        var children: [SM64ObjectID] = []
        if output.spawnBubbleCount > 0 {
            for index in 0..<output.spawnBubbleCount {
                let angle = Int16(truncatingIfNeeded: -0x2000 + index * 0x555)
                let position = SM64ObjectVector3(
                    x: record.position.x + SM64CanonicalTrig.sins(angle) * 100,
                    y: record.position.y + 30,
                    z: record.position.z + SM64CanonicalTrig.coss(angle) * 100
                )
                if let child = try? bubbleBridge.spawnBubble(in: engineState, position: position, parent: id) {
                    children.append(child)
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action.rawValue
            next.timer = output.timer
            next.scale = output.scale
            next.intangibleTimer = output.tangible ? -1 : 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, spawnedBubbles: children))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
