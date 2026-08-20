import Foundation

struct SM64FallingBowserPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64FallingBowserPlatformOutput
}

final class SM64FallingBowserPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_666270
    static let collisionDataIdentity: UInt64 = 0x6662705F636F6C6C

    private struct State {
        let variant: Int32
        var bowserPresent: Bool
        var bowserOnPlatform: Bool
        var bowserAction: Int32
        var bowserFireFlag: Bool
        var bowserHealth: Int32
        var bowserHeld: Bool
        var debugValue: Int32
        var shakeCounter: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FallingBowserPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPlatform(in engineState: SM64SwiftEngineState, variant: Int32 = 1, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, variant: variant, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned falling Bowser platform could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, variant: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(variant: variant, bowserPresent: false, bowserOnPlatform: false, bowserAction: 0, bowserFireFlag: false, bowserHealth: 3, bowserHeld: false, debugValue: 0, shakeCounter: 0)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = variant
            record.collisionDataIdentity = Self.collisionDataIdentity ^ UInt64(UInt32(bitPattern: variant))
            record.collisionDistance = 20_000
            record.drawingDistance = 20_000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setBowserInput(
        bowserPresent: Bool? = nil,
        bowserOnPlatform: Bool? = nil,
        bowserAction: Int32? = nil,
        bowserFireFlag: Bool? = nil,
        bowserHealth: Int32? = nil,
        bowserHeld: Bool? = nil,
        debugValue: Int32? = nil,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = states[id] else { return false }
        if let bowserPresent { state.bowserPresent = bowserPresent }
        if let bowserOnPlatform { state.bowserOnPlatform = bowserOnPlatform }
        if let bowserAction { state.bowserAction = bowserAction }
        if let bowserFireFlag { state.bowserFireFlag = bowserFireFlag }
        if let bowserHealth { state.bowserHealth = bowserHealth }
        if let bowserHeld { state.bowserHeld = bowserHeld }
        if let debugValue { state.debugValue = debugValue }
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64FallingBowserPlatformBehavior.update(.init(
            action: record.action,
            subAction: record.subAction,
            timer: record.timer,
            position: record.position,
            velocityY: record.velocity.y,
            gravity: record.gravity,
            variant: state.variant,
            bowserPresent: state.bowserPresent,
            bowserOnPlatform: state.bowserOnPlatform,
            bowserAction: state.bowserAction,
            bowserFireFlag: state.bowserFireFlag,
            bowserHealth: state.bowserHealth,
            bowserHeld: state.bowserHeld,
            debugValue: state.debugValue,
            shakeCounter: state.shakeCounter
        ))
        state.shakeCounter = output.shakeCounter
        state.bowserOnPlatform = false
        state.bowserFireFlag = false
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.subAction = output.subAction
            next.timer = output.timer
            next.position = output.position
            next.velocity.y = output.velocityY
            next.gravity = output.gravity
            next.collisionDataIdentity = Self.collisionDataIdentity ^ UInt64(UInt32(bitPattern: output.collisionVariant))
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
