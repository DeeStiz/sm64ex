import Foundation

struct SM64CoinObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CoinOutput
    let spawnedSparkles: SM64ObjectID?
}

struct SM64CoinSpawnerEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let count: Int
    let spawnedCoins: [SM64ObjectID]
    let deactivated: Bool
    let pattern: Int32
    let childPositions: [SM64ObjectVector3]
}

final class SM64CoinObjectBridge {
    static let oneCoinBehaviorIdentity: UInt64 = 0x6268_765F_6F6E63
    static let yellowCoinBehaviorIdentity: UInt64 = 0x6268_765F_79636F
    static let temporaryYellowCoinBehaviorIdentity: UInt64 = 0x6268_765F_74636F
    static let threeCoinsSpawnBehaviorIdentity: UInt64 = 0x6268_765F_337370
    static let tenCoinsSpawnBehaviorIdentity: UInt64 = 0x6268_765F_317370
    static let singleCoinGetsSpawnedBehaviorIdentity: UInt64 = 0x6268_765F_736367
    static let coinFormationBehaviorIdentity: UInt64 = 0x6268_765F_63666D
    static let coinFormationSpawnBehaviorIdentity: UInt64 = 0x6268_765F_63666D63
    static let coinInsideBooBehaviorIdentity: UInt64 = 0x6268_765F_636962
    static let interactionType: UInt32 = 1 << 4

    private struct State { let kind: SM64CoinKind; var interacted: Bool; let floorDistance: Float }
    private struct PatternState { var pattern: Int32; var respawnMask: UInt8; var action: Int32; var timer: Int32; var distanceToMario: Float }
    private struct InsideBooState { var parent: SM64ObjectID; var parentDying: Bool; var marioMoveYaw: Int32; var levelIsBBH: Bool; var landed: Bool; var interacted: Bool }
    private let goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge?
    private var states: [SM64ObjectID: State] = [:]
    private var spawners: [SM64ObjectID: Int] = [:]
    private var patternSpawners: [SM64ObjectID: PatternState] = [:]
    private var insideBoo: [SM64ObjectID: InsideBooState] = [:]
    private(set) var effectLog: [SM64CoinObjectEffectRecord] = []
    private(set) var spawnerEffectLog: [SM64CoinSpawnerEffectRecord] = []

    init(goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge? = nil) { self.goldenCoinSparklesBridge = goldenCoinSparklesBridge }
    var registeredIDs: [SM64ObjectID] {
        var ids = Array(states.keys)
        ids.append(contentsOf: spawners.keys)
        ids.append(contentsOf: patternSpawners.keys)
        ids.append(contentsOf: insideBoo.keys)
        return ids.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot }
    }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true); spawnerEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnCoin(in engineState: SM64SwiftEngineState, kind: SM64CoinKind = .yellow, position: SM64ObjectVector3 = .zero, floorDistance: Float = 0, identity: UInt64? = nil) throws -> SM64ObjectID {
        let behavior = identity ?? (kind == .temporary ? Self.temporaryYellowCoinBehaviorIdentity : Self.yellowCoinBehaviorIdentity)
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: behavior)
        guard attach(id, kind: kind, position: position, floorDistance: floorDistance, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned coin could not attach") }
        return id
    }

    @discardableResult
    func spawnFormation(in engineState: SM64SwiftEngineState, count: Int, position: SM64ObjectVector3 = .zero, identity: UInt64) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: identity)
        guard attachSpawner(id, count: count, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned coin formation could not attach") }
        return id
    }

    @discardableResult
    func spawnPatternFormation(
        in engineState: SM64SwiftEngineState,
        pattern: Int32,
        respawnMask: UInt8 = 0,
        distanceToMario: Float = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .spawner, behaviorIdentity: Self.coinFormationBehaviorIdentity)
        guard attachPatternSpawner(id, pattern: pattern, respawnMask: respawnMask, distanceToMario: distanceToMario, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned patterned coin formation could not attach")
        }
        return id
    }

    @discardableResult
    func attachSpawner(_ id: SM64ObjectID, count: Int, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard count > 0, pool.record(for: id) != nil else { return false }
        spawners[id] = count
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachPatternSpawner(
        _ id: SM64ObjectID,
        pattern: Int32,
        respawnMask: UInt8,
        distanceToMario: Float,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        patternSpawners[id] = PatternState(pattern: pattern, respawnMask: respawnMask, action: 0, timer: 0, distanceToMario: distanceToMario)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.distanceToMario = distanceToMario
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func spawnCoinInsideBoo(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        levelIsBBH: Bool = false
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.coinInsideBooBehaviorIdentity, parent: parent)
        guard attachCoinInsideBoo(id, parent: parent, position: position, levelIsBBH: levelIsBBH, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned coin-inside-Boo object could not attach")
        }
        return id
    }

    @discardableResult
    func attachCoinInsideBoo(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        position: SM64ObjectVector3,
        levelIsBBH: Bool,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        insideBoo[id] = InsideBooState(parent: parent, parentDying: false, marioMoveYaw: 0, levelIsBBH: levelIsBBH, landed: false, interacted: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.interactionType = Self.interactionType
            record.damageOrCoinValue = 1
            record.hitboxRadius = 100
            record.hitboxHeight = 64
            record.intangibleTimer = 1
            record.gravity = 4
            record.friction = 1
            record.buoyancy = 2
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setCoinInsideBooInput(
        parentDying: Bool,
        marioMoveYaw: Int32 = 0,
        landed: Bool = false,
        interacted: Bool = false,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = insideBoo[id] else { return false }
        state.parentDying = parentDying
        state.marioMoveYaw = marioMoveYaw
        state.landed = landed
        state.interacted = interacted
        insideBoo[id] = state
        return true
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64CoinKind, position: SM64ObjectVector3, floorDistance: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, interacted: false, floorDistance: floorDistance)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.interactionType = Self.interactionType; record.damageOrCoinValue = 1; record.hitboxRadius = 100; record.hitboxHeight = 64; record.intangibleTimer = 0; record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult func setInteraction(_ value: Bool, for id: SM64ObjectID) -> Bool { guard var state = states[id] else { return false }; state.interacted = value; states[id] = state; return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if var inside = insideBoo[id], let record = engineState.objects.record(for: id) {
            let parentPosition = engineState.objects.record(for: inside.parent)?.position ?? record.position
            let output = SM64CoinInsideBooBehavior.update(.init(
                action: SM64CoinInsideBooAction(rawValue: record.action) ?? .inside,
                timer: record.timer,
                position: record.position,
                velocity: record.velocity,
                parentPosition: parentPosition,
                parentDying: inside.parentDying,
                marioMoveYaw: inside.marioMoveYaw,
                levelIsBBH: inside.levelIsBBH,
                landed: inside.landed,
                interacted: inside.interacted
            ))
            inside.parentDying = false
            inside.landed = false
            inside.interacted = false
            insideBoo[id] = inside
            var sparkle: SM64ObjectID?
            if output.spawnGoldenSparkles, let goldenCoinSparklesBridge {
                sparkle = try? goldenCoinSparklesBridge.spawnSparkles(in: engineState, position: record.position)
            }
            _ = engineState.objects.mutate(id) { next in
                next.action = output.action.rawValue
                next.timer = output.timer
                next.position = output.position
                next.velocity = output.velocity
                next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
                if output.blueModel { next.model = 0x76 }
                next.intangibleTimer = output.tangible ? -1 : 1
                next.interactionStatus = 0
                if output.shouldDelete { next.activeFlags = 0 }
                next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            }
            effectLog.append(.init(
                objectID: id,
                output: .init(
                    kind: .yellow,
                    timer: output.timer,
                    animationState: record.animationState &+ 1,
                    visible: true,
                    modelNoShadow: output.blueModel,
                    spawnGoldenSparkles: output.spawnGoldenSparkles,
                    shouldDelete: output.shouldDelete,
                    hitboxRadius: 100,
                    hitboxHeight: 64,
                    damageOrCoinValue: 1
                ),
                spawnedSparkles: sparkle
            ))
            return true
        }
        if var patternState = patternSpawners[id], let record = engineState.objects.record(for: id) {
            var children: [SM64ObjectID] = []
            var childPositions: [SM64ObjectVector3] = []
            if patternState.action == 0, patternState.distanceToMario < 2_000 {
                let formation = SM64CoinFormationBehavior.updatePattern(pattern: patternState.pattern, respawnMask: patternState.respawnMask)
                for child in formation.children {
                    let position = SM64ObjectVector3(
                        x: record.position.x + child.offsetX,
                        y: record.position.y + child.offsetY + (child.aboveFloor ? 300 : 0),
                        z: record.position.z + child.offsetZ
                    )
                    if let childID = try? spawnCoin(in: engineState, kind: .yellow, position: position, floorDistance: child.aboveFloor ? 0 : 300, identity: Self.coinFormationSpawnBehaviorIdentity) {
                        children.append(childID)
                        childPositions.append(position)
                    }
                }
                patternState.action = 1
            } else if patternState.action == 1, patternState.distanceToMario > 2_100 {
                patternState.action = 2
            } else if patternState.action == 2 {
                patternState.action = 0
            }
            patternState.timer &+= 1
            patternSpawners[id] = patternState
            _ = engineState.objects.mutate(id) { $0.action = patternState.action; $0.timer = patternState.timer }
            spawnerEffectLog.append(.init(objectID: id, count: children.count, spawnedCoins: children, deactivated: false, pattern: patternState.pattern, childPositions: childPositions))
            return true
        }
        if let count = spawners[id], let record = engineState.objects.record(for: id) {
            let formation = SM64CoinFormationBehavior.update(count: count)
            var children: [SM64ObjectID] = []
            if formation.spawnChildCoins {
                for _ in 0..<formation.count { if let child = try? spawnCoin(in: engineState, position: record.position, identity: Self.singleCoinGetsSpawnedBehaviorIdentity) { children.append(child) } }
            }
            if formation.deactivateParent { _ = engineState.objects.mutate(id) { $0.activeFlags = 0 } }
            spawnerEffectLog.append(.init(objectID: id, count: formation.count, spawnedCoins: children, deactivated: formation.deactivateParent, pattern: 0, childPositions: children.compactMap { engineState.objects.record(for: $0)?.position }))
            return true
        }
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64CoinBehavior.update(.init(kind: state.kind, timer: record.timer, animationState: record.animationState, interacted: state.interacted, floorDistance: state.floorDistance))
        state.interacted = false; states[id] = state
        var sparkle: SM64ObjectID?
        if output.spawnGoldenSparkles, let golden = goldenCoinSparklesBridge { sparkle = try? golden.spawnSparkles(in: engineState, position: record.position) }
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer; next.animationState = output.animationState; next.model = output.modelNoShadow ? 0x4B : next.model; next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10; next.interactionStatus = 0; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, spawnedSparkles: sparkle)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id); spawners.removeValue(forKey: id); patternSpawners.removeValue(forKey: id); insideBoo.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
