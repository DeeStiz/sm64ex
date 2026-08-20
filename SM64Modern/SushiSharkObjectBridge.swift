import Foundation

struct SM64SushiSharkObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SushiSharkOutput
    let collisionChild: SM64ObjectID?
}

/// Owner-thread bridge for the Sushi shark and its invisible collision child.
///
/// Wave trails are intentionally surfaced as a value request in the effect
/// record. The central owner can deliver that request to the existing
/// `SM64WaveTrailObjectBridge` without making this route depend on the shared
/// dispatch file.
final class SM64SushiSharkObjectBridge {
    static let sushiBehaviorIdentity: UInt64 = 0x6268_765F_7375_7368 // bhv_sush
    static let collisionChildBehaviorIdentity: UInt64 = 0x6268_765F_7375_7332 // bhv_sus2
    static let sushiModel: UInt32 = 0x56 // MODEL_SUSHI
    static let collisionChildModel: UInt32 = 0 // MODEL_NONE
    static let damageInteractionType: UInt32 = 1 // INTERACT_DAMAGE

    private struct State {
        var orbitAngle: Int32
        var waterLevel: Float
        var marioY: Float
    }

    private var sharks: [SM64ObjectID: State] = [:]
    private var collisionChildren: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SushiSharkObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        (Array(sharks.keys) + Array(collisionChildren)).sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSushi(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        orbitAngle: Int32 = 0,
        waterLevel: Float = 0,
        marioY: Float = 10_000
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: Self.sushiModel,
            behaviorIdentity: Self.sushiBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            orbitAngle: orbitAngle,
            waterLevel: waterLevel,
            marioY: marioY,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Sushi shark could not attach")
        }

        let child = try engineState.spawnObject(
            in: .generalActor,
            model: Self.collisionChildModel,
            behaviorIdentity: Self.collisionChildBehaviorIdentity,
            parent: id
        )
        guard attachCollisionChild(child, parent: id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(child)
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Sushi collision child could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        orbitAngle: Int32,
        waterLevel: Float,
        marioY: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        sharks[id] = State(orbitAngle: orbitAngle, waterLevel: waterLevel, marioY: marioY)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.hitboxRadius = 100
            record.hitboxHeight = 50
            record.hitboxDownOffset = 50
            record.interactionType = Self.damageInteractionType
            record.damageOrCoinValue = 3
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachCollisionChild(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        collisionChildren.insert(id)
        return pool.mutate(id) { record in
            record.parent = parent
            record.position = position
            record.homePosition = position
            record.graphFlags |= 0x10 // GRAPH_RENDER_INVISIBLE / DISABLE_RENDERING
            record.intangibleTimer = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func setInputs(
        waterLevel: Float? = nil,
        marioY: Float? = nil,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = sharks[id] else { return false }
        if let waterLevel { state.waterLevel = waterLevel }
        if let marioY { state.marioY = marioY }
        sharks[id] = state
        return true
    }

    /// Updates either the shark or its no-op collision child. The child route
    /// is kept registered so central dispatch can route both behavior IDs to
    /// this bridge while retaining C's separate object-list entry.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if collisionChildren.contains(id) {
            guard engineState.objects.record(for: id) != nil else { return false }
            _ = engineState.objects.mutate(id) { record in
                record.interactionStatus = 0
                record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            }
            return true
        }
        guard var state = sharks[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SushiSharkBehavior.update(.init(
            timer: record.timer,
            homePosition: record.homePosition,
            orbitAngle: state.orbitAngle,
            waterLevel: state.waterLevel,
            marioY: state.marioY
        ))
        state.orbitAngle = output.orbitAngle
        sharks[id] = state
        var collisionChild: SM64ObjectID?
        if let child = collisionChildren.first(where: { engineState.objects.record(for: $0)?.parent == id }) {
            collisionChild = child
            _ = engineState.objects.mutate(child) { next in
                next.position = output.position
                next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.timer &+= 1
            next.interactionStatus = 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, collisionChild: collisionChild))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        sharks.removeValue(forKey: id)
        collisionChildren.remove(id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
