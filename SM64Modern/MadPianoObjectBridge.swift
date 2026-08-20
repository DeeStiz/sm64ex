import Foundation

struct SM64MadPianoObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MadPianoOutput
}

/// Generation-safe owner for `bhvMadPiano`. Collision, animation delivery,
/// and sound presentation remain explicit downstream consumers; this bridge
/// only commits the value result to the Swift object record.
final class SM64MadPianoObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D7069
    static let defaultModel: UInt32 = 0x00 // MODEL_MAD_PIANO
    static let interactionMrBlizzard: UInt32 = 1 << 21

    private struct State: Equatable, Sendable {
        var distanceToMario: Float = 10_000
        var marioForwardVelocity: Float = 0
        var angleToMario: Int32 = 0
        var animationNearEnd = false
        var floorAndWallsUpdated = false
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64MadPianoObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnPiano(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        homePosition: SM64ObjectVector3? = nil,
        model: UInt32 = SM64MadPianoObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64MadPianoObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            homePosition: homePosition ?? position,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Mad Piano could not attach")
        }
        _ = engineState.objects.mutate(id) { record in
            // `ADD_INT(oMoveAngleYaw, 0x4000)` is part of the behavior script
            // and applies to freshly allocated level objects.
            record.moveAngles.yaw = 0x4000
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        homePosition: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State()
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = homePosition
            record.interactionType = Self.interactionMrBlizzard
            record.damageOrCoinValue = 3
            record.health = 99
            record.hitboxRadius = 200
            record.hitboxHeight = 150
            record.hurtboxRadius = 200
            record.hurtboxHeight = 150
            record.wallHitboxRadius = 40
            record.gravity = 0
            record.dragStrength = 1000
            record.friction = 1000
            record.buoyancy = 200
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setInput(
        distanceToMario: Float? = nil,
        marioForwardVelocity: Float? = nil,
        angleToMario: Int32? = nil,
        animationNearEnd: Bool? = nil,
        floorAndWallsUpdated: Bool? = nil,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = states[id] else { return false }
        if let distanceToMario { state.distanceToMario = distanceToMario }
        if let marioForwardVelocity { state.marioForwardVelocity = marioForwardVelocity }
        if let angleToMario { state.angleToMario = angleToMario }
        if let animationNearEnd { state.animationNearEnd = animationNearEnd }
        if let floorAndWallsUpdated { state.floorAndWallsUpdated = floorAndWallsUpdated }
        states[id] = state
        return true
    }

    /// Called by the shared dispatcher while it owns the external tick. This
    /// method does not create a nested scheduler or call back into C.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let inputState = states[id], let record = engineState.objects.record(for: id) else {
            return false
        }
        let output = SM64MadPianoBehavior.update(
            .init(
                action: record.action,
                timer: record.timer,
                position: record.position,
                homePosition: record.homePosition,
                moveYaw: record.moveAngles.yaw,
                angleToMario: inputState.angleToMario,
                distanceToMario: inputState.distanceToMario,
                marioForwardVelocity: inputState.marioForwardVelocity,
                animationNearEnd: inputState.animationNearEnd,
                floorAndWallsUpdated: inputState.floorAndWallsUpdated
            )
        )
        states[id] = State()
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.forwardVelocity = output.forwardVelocity
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.yaw = output.faceYaw
            next.animationState = output.animation
            next.intangibleTimer = output.tangible ? -1 : 1
            next.interactionStatus = 0
            next.objectFlags |=
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
