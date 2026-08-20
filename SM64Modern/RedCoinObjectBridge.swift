import Foundation

struct SM64HiddenRedCoinStarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HiddenRedCoinStarOutput
    let spawnedStar: SM64ObjectID?
    let spawnedMarker: SM64ObjectID?
}

struct SM64RedCoinStarMarkerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RedCoinStarMarkerOutput
}

struct SM64RedCoinObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RedCoinOutput
    let parentID: SM64ObjectID?
    let spawnedSparkles: SM64ObjectID?
}

/// Owner-thread bridge for the red-coin star chain. The C parent pointer and
/// nearest-object queries are represented as generation-safe IDs and local
/// value state; effect sinks remain separate from the reducers.
final class SM64RedCoinObjectBridge {
    static let hiddenRedCoinStarBehaviorIdentity: UInt64 = 0x6268_765F_687273
    static let redCoinStarMarkerBehaviorIdentity: UInt64 = 0x6268_765F_72736D
    static let redCoinBehaviorIdentity: UInt64 = 0x6268_765F_72636F
    static let coinInteractionType: UInt32 = 1 << 4 // INTERACT_COIN

    private struct HiddenState {
        var action: SM64HiddenRedCoinStarAction
        var counter: Int32
        let redCoinCount: Int32
        let courseIsJrb: Bool
        var pendingStar: SM64ObjectID?
        var pendingMarker: SM64ObjectID?
    }

    private struct MarkerState {}
    private struct CoinState { var parentID: SM64ObjectID?; var interacted: Bool }

    private let starSpawnBridge: SM64StarSpawnCoordinatesObjectBridge?
    private let collectStarBridge: SM64CollectStarObjectBridge?
    private let goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge?
    private var hiddenStars: [SM64ObjectID: HiddenState] = [:]
    private var markers: [SM64ObjectID: MarkerState] = [:]
    private var coins: [SM64ObjectID: CoinState] = [:]
    private(set) var hiddenStarEffectLog: [SM64HiddenRedCoinStarObjectEffectRecord] = []
    private(set) var markerEffectLog: [SM64RedCoinStarMarkerObjectEffectRecord] = []
    private(set) var coinEffectLog: [SM64RedCoinObjectEffectRecord] = []

    init(
        starSpawnBridge: SM64StarSpawnCoordinatesObjectBridge? = nil,
        collectStarBridge: SM64CollectStarObjectBridge? = nil,
        goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge? = nil
    ) {
        self.starSpawnBridge = starSpawnBridge
        self.collectStarBridge = collectStarBridge
        self.goldenCoinSparklesBridge = goldenCoinSparklesBridge
    }

    var registeredIDs: [SM64ObjectID] {
        let ids = Array(hiddenStars.keys) + Array(markers.keys) + Array(coins.keys)
        return ids.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        hiddenStarEffectLog.removeAll(keepingCapacity: true)
        markerEffectLog.removeAll(keepingCapacity: true)
        coinEffectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnHiddenRedCoinStar(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        redCoinCount: Int32 = 8,
        courseIsJrb: Bool = false
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            behaviorIdentity: Self.hiddenRedCoinStarBehaviorIdentity
        )
        guard attachHiddenRedCoinStar(id, position: position, redCoinCount: redCoinCount, courseIsJrb: courseIsJrb, in: engineState) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned hidden red-coin star could not attach")
        }
        return id
    }

    @discardableResult
    func spawnRedCoinStarMarker(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.redCoinStarMarkerBehaviorIdentity)
        guard attachMarker(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned red-coin star marker could not attach")
        }
        return id
    }

    @discardableResult
    func spawnRedCoin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.redCoinBehaviorIdentity)
        let resolvedParent = parent ?? nearestHiddenStar(to: position, in: engineState.objects)
        guard attachRedCoin(id, position: position, parent: resolvedParent, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned red coin could not attach")
        }
        return id
    }

    @discardableResult
    func attachHiddenRedCoinStar(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        redCoinCount: Int32,
        courseIsJrb: Bool,
        in engineState: SM64SwiftEngineState
    ) -> Bool {
        guard engineState.objects.record(for: id) != nil else { return false }
        let clampedCount = min(max(redCoinCount, 0), 8)
        var state = HiddenState(
            action: .waiting,
            counter: 8 &- clampedCount,
            redCoinCount: clampedCount,
            courseIsJrb: courseIsJrb,
            pendingStar: nil,
            pendingMarker: nil
        )
        if clampedCount == 0 {
            if let collectStarBridge {
                state.pendingStar = try? collectStarBridge.spawnStar(in: engineState, position: position)
            }
        } else if !courseIsJrb {
            state.pendingMarker = try? spawnRedCoinStarMarker(in: engineState, position: position)
        }
        hiddenStars[id] = state
        return engineState.objects.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.action = state.action.rawValue
            record.behaviorParams = clampedCount
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func attachMarker(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        markers[id] = MarkerState()
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.position.y += 60
            record.scale = .init(x: 1, y: 1, z: 0.75)
            record.faceAngles.pitch = 0x4000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachRedCoin(_ id: SM64ObjectID, position: SM64ObjectVector3, parent: SM64ObjectID?, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        if let parent, pool.record(for: parent) == nil { return false }
        coins[id] = CoinState(parentID: parent, interacted: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.parent = parent ?? record.parent
            record.interactionType = Self.coinInteractionType
            record.damageOrCoinValue = 2
            record.hitboxRadius = 100
            record.hitboxHeight = 64
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setRedCoinInteraction(_ interacted: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = coins[id] else { return false }
        state.interacted = interacted
        coins[id] = state
        return true
    }

    @discardableResult
    func setRedCoinCounter(_ counter: Int32, for id: SM64ObjectID) -> Bool {
        guard var state = hiddenStars[id] else { return false }
        state.counter = counter
        hiddenStars[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if hiddenStars[id] != nil { return updateHiddenStar(id, state: engineState) }
        if markers[id] != nil { return updateMarker(id, state: engineState) }
        if coins[id] != nil { return updateCoin(id, state: engineState) }
        return false
    }

    private func updateHiddenStar(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var hiddenState = hiddenStars[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64HiddenRedCoinStarBehavior.update(.init(
            action: hiddenState.action,
            timer: record.timer,
            redCoinCounter: hiddenState.counter
        ))
        var spawnedStar = hiddenState.pendingStar
        let spawnedMarker = hiddenState.pendingMarker
        if output.spawnNoExitStar, let starSpawnBridge {
            spawnedStar = try? starSpawnBridge.spawnStar(in: engineState, position: record.position, homePosition: record.position)
        }
        hiddenState.pendingStar = nil
        hiddenState.pendingMarker = nil
        hiddenState.action = output.action
        hiddenStars[id] = hiddenState
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action.rawValue
            next.timer = output.timer
            next.animationState = output.redCoinsCollected
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        hiddenStarEffectLog.append(.init(objectID: id, output: output, spawnedStar: spawnedStar, spawnedMarker: spawnedMarker))
        return true
    }

    private func updateMarker(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard markers[id] != nil, let record = engineState.objects.record(for: id) else { return false }
        let output = SM64RedCoinStarMarkerBehavior.update(.init(timer: record.timer, faceYaw: record.faceAngles.yaw))
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.faceAngles.yaw = output.faceYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        markerEffectLog.append(.init(objectID: id, output: output))
        return true
    }

    private func updateCoin(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var coinState = coins[id], let record = engineState.objects.record(for: id) else { return false }
        let parentCounter = coinState.parentID.flatMap { hiddenStars[$0]?.counter }
        let output = SM64RedCoinBehavior.update(.init(parentCounter: parentCounter, interacted: coinState.interacted))
        if let parentID = coinState.parentID, let nextCounter = output.parentCounter, var parent = hiddenStars[parentID] {
            parent.counter = nextCounter
            hiddenStars[parentID] = parent
        }
        coinState.interacted = false
        coins[id] = coinState
        var spawnedSparkles: SM64ObjectID?
        if output.spawnGoldenSparkles, let goldenCoinSparklesBridge {
            spawnedSparkles = try? goldenCoinSparklesBridge.spawnSparkles(in: engineState, position: record.position)
        }
        _ = engineState.objects.mutate(id) { next in
            next.interactionStatus = 0
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
        }
        coinEffectLog.append(.init(objectID: id, output: output, parentID: coinState.parentID, spawnedSparkles: spawnedSparkles))
        return true
    }

    private func nearestHiddenStar(to position: SM64ObjectVector3, in pool: SM64ObjectPool) -> SM64ObjectID? {
        var candidates: [(distance: Float, id: SM64ObjectID)] = []
        for id in hiddenStars.keys {
            guard let record = pool.record(for: id) else { continue }
            guard record.activeFlags & SM64ObjectPool.activeFlagActive != 0 else { continue }
            let dx = record.position.x - position.x
            let dy = record.position.y - position.y
            let dz = record.position.z - position.z
            candidates.append((dx * dx + dy * dy + dz * dz, id))
        }
        return candidates.min { lhs, rhs in
            lhs.0 == rhs.0
                ? (lhs.1.slot == rhs.1.slot ? lhs.1.generation < rhs.1.generation : lhs.1.slot < rhs.1.slot)
                : lhs.0 < rhs.0
        }?.1
    }

    func remove(_ id: SM64ObjectID) {
        hiddenStars.removeValue(forKey: id)
        markers.removeValue(forKey: id)
        coins.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
