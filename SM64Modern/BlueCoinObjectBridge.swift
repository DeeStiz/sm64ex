import Foundation

struct SM64BlueCoinSwitchObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BlueCoinSwitchOutput
    let hiddenCoinCount: Int32
}

struct SM64HiddenBlueCoinObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HiddenBlueCoinOutput
    let switchID: SM64ObjectID?
    let spawnedSparkles: SM64ObjectID?
}

/// Owner-thread bridge for the source-authored blue-coin switch/coin pair.
/// The nearest switch is retained as a generation-safe value reference; the
/// C object pointer field `oHiddenBlueCoinSwitch` never crosses this boundary.
final class SM64BlueCoinObjectBridge {
    static let blueCoinSwitchBehaviorIdentity: UInt64 = 0x6268_765F_626373
    static let hiddenBlueCoinBehaviorIdentity: UInt64 = 0x6268_765F_686263
    static let coinInteractionType: UInt32 = 1 << 4 // INTERACT_COIN

    private struct SwitchState {
        var action: SM64BlueCoinSwitchAction
        var marioGroundPoundOnPlatform: Bool
        var marioPositionY: Float
    }

    private struct HiddenCoinState {
        var action: SM64HiddenBlueCoinAction
        var switchID: SM64ObjectID?
        var interacted: Bool
    }

    private let goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge?
    private var switches: [SM64ObjectID: SwitchState] = [:]
    private var hiddenCoins: [SM64ObjectID: HiddenCoinState] = [:]
    private(set) var switchEffectLog: [SM64BlueCoinSwitchObjectEffectRecord] = []
    private(set) var hiddenCoinEffectLog: [SM64HiddenBlueCoinObjectEffectRecord] = []

    init(goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge? = nil) {
        self.goldenCoinSparklesBridge = goldenCoinSparklesBridge
    }

    var registeredIDs: [SM64ObjectID] {
        let ids = Array(switches.keys) + Array(hiddenCoins.keys)
        return ids.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        switchEffectLog.removeAll(keepingCapacity: true)
        hiddenCoinEffectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSwitch(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        action: SM64BlueCoinSwitchAction = .idle
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            behaviorIdentity: Self.blueCoinSwitchBehaviorIdentity
        )
        guard attachSwitch(id, position: position, action: action, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned blue-coin switch could not attach")
        }
        return id
    }

    @discardableResult
    func spawnHiddenCoin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        action: SM64HiddenBlueCoinAction = .inactive
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            behaviorIdentity: Self.hiddenBlueCoinBehaviorIdentity
        )
        guard attachHiddenCoin(id, position: position, action: action, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned hidden blue coin could not attach")
        }
        return id
    }

    @discardableResult
    func attachSwitch(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        action: SM64BlueCoinSwitchAction = .idle,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        switches[id] = SwitchState(action: action, marioGroundPoundOnPlatform: false, marioPositionY: position.y)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.action = action.rawValue
            record.scale = .init(x: 3, y: 3, z: 3)
            record.collisionDistance = 4_000
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachHiddenCoin(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        action: SM64HiddenBlueCoinAction = .inactive,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        hiddenCoins[id] = HiddenCoinState(action: action, switchID: nil, interacted: false)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.action = action.rawValue
            record.interactionType = Self.coinInteractionType
            record.damageOrCoinValue = 5
            record.hitboxRadius = 100
            record.hitboxHeight = 64
            record.intangibleTimer = 1
            record.graphFlags |= 0x10
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setMarioGroundPound(
        _ groundPound: Bool,
        positionY: Float,
        for switchID: SM64ObjectID
    ) -> Bool {
        guard var state = switches[switchID] else { return false }
        state.marioGroundPoundOnPlatform = groundPound
        state.marioPositionY = positionY
        switches[switchID] = state
        return true
    }

    @discardableResult
    func setSwitchAction(_ action: SM64BlueCoinSwitchAction, for id: SM64ObjectID) -> Bool {
        guard var state = switches[id] else { return false }
        state.action = action
        switches[id] = state
        return true
    }

    @discardableResult
    func setInteraction(_ interacted: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = hiddenCoins[id] else { return false }
        state.interacted = interacted
        hiddenCoins[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if switches[id] != nil {
            return updateSwitch(id, state: engineState)
        }
        if hiddenCoins[id] != nil {
            return updateHiddenCoin(id, state: engineState)
        }
        return false
    }

    private func updateSwitch(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var switchState = switches[id], let record = engineState.objects.record(for: id) else { return false }
        let hiddenCoinCount = Int32(hiddenCoins.keys.reduce(into: 0) { count, coinID in
            if let coin = engineState.objects.record(for: coinID), coin.activeFlags & SM64ObjectPool.activeFlagActive != 0 {
                count += 1
            }
        })
        let output = SM64BlueCoinSwitchBehavior.update(.init(
            action: switchState.action,
            timer: record.timer,
            positionY: record.position.y,
            velocityY: record.velocity.y,
            marioPositionY: switchState.marioPositionY,
            marioGroundPoundOnPlatform: switchState.marioGroundPoundOnPlatform,
            hiddenCoinCount: hiddenCoinCount
        ))
        switchState.action = output.action
        switchState.marioGroundPoundOnPlatform = false
        switches[id] = switchState
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action.rawValue
            next.timer = output.timer
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10
            next.collisionDistance = 4_000
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        switchEffectLog.append(.init(objectID: id, output: output, hiddenCoinCount: hiddenCoinCount))
        return true
    }

    private func updateHiddenCoin(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var coinState = hiddenCoins[id], let record = engineState.objects.record(for: id) else { return false }
        if coinState.action == .inactive, coinState.switchID == nil {
            coinState.switchID = nearestLiveSwitch(to: record.position, in: engineState.objects)
        }
        let switchAction = coinState.switchID.flatMap { switches[$0]?.action }
        let output = SM64HiddenBlueCoinBehavior.update(.init(
            action: coinState.action,
            timer: record.timer,
            switchAction: switchAction,
            interacted: coinState.interacted
        ))
        coinState.action = output.action
        coinState.interacted = false
        hiddenCoins[id] = coinState
        var spawnedSparkles: SM64ObjectID?
        if output.spawnGoldenSparkles, let goldenCoinSparklesBridge {
            spawnedSparkles = try? goldenCoinSparklesBridge.spawnSparkles(in: engineState, position: record.position)
        }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action.rawValue
            next.timer = output.timer
            next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | 0x10
            next.intangibleTimer = output.tangible ? -1 : 1
            next.interactionStatus = 0
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        hiddenCoinEffectLog.append(.init(objectID: id, output: output, switchID: coinState.switchID, spawnedSparkles: spawnedSparkles))
        return true
    }

    private func nearestLiveSwitch(to position: SM64ObjectVector3, in pool: SM64ObjectPool) -> SM64ObjectID? {
        var candidates: [(distance: Float, id: SM64ObjectID)] = []
        for id in switches.keys {
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
        switches.removeValue(forKey: id)
        hiddenCoins.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
