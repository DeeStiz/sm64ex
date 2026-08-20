import Foundation

/// The three native object identities are kept distinct because the same
/// child puzzle is used by DDD, JRB, and the sunken-ship room.  The values are
/// short `bhv_` fingerprints, matching the identities used by the other
/// migrated object bridges.
enum SM64TreasureChestObjectRole: UInt8, Equatable, Sendable {
    case root = 0
    case bottom = 1
    case top = 2
}

enum SM64TreasureChestObjectOutput: Equatable, Sendable {
    case root(SM64TreasureChestRootOutput)
    case bottom(SM64TreasureChestBottomOutput)
    case top(SM64TreasureChestTopOutput)
}

struct SM64TreasureChestObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let role: SM64TreasureChestObjectRole
    let variant: SM64TreasureChestVariant
    let output: SM64TreasureChestObjectOutput
    let spawnedChildren: [SM64ObjectID]
}

struct SM64TreasureChestSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64TreasureChestObjectEffectRecord]
}

/// Owner-thread bridge for `bhvTreasureChests*`, `bhvTreasureChestBottom`,
/// and `bhvTreasureChestTop`.
///
/// The C spawn order is deliberately observable here: each root creates
/// bottom 1, then its top, before creating bottom 2 and its top, and so on.
/// The bottom objects live in `OBJ_LIST_GENACTOR`, while roots and tops live
/// in `OBJ_LIST_DEFAULT`; the shared scheduler therefore retains C's list
/// traversal (all bottoms, then root, then tops) without a second scheduler.
final class SM64TreasureChestObjectBridge {
    // ASCII: bhv_trc, bhv_trj, bhv_trs, bhv_trb, bhv_trt.
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747263
    static let jrbBehaviorIdentity: UInt64 = 0x6268_765F_74726A
    static let shipBehaviorIdentity: UInt64 = 0x6268_765F_747273
    static let bottomBehaviorIdentity: UInt64 = 0x6268_765F_747262
    static let topBehaviorIdentity: UInt64 = 0x6268_765F_747274

    static let rootModel: UInt32 = 0
    static let bottomModel: UInt32 = 0x65 // MODEL_TREASURE_CHEST_BASE
    static let topModel: UInt32 = 0x66 // MODEL_TREASURE_CHEST_LID
    static let bottomInteractionType: UInt32 = 1 << 29 // INTERACT_SHOCK

    private struct BottomState: Equatable, Sendable {
        let rootID: SM64ObjectID
        let behaviorParameter: Int32
        var distanceToMario: Float?
        var marioYaw: Int32?
    }

    private struct TopState: Equatable, Sendable {
        let rootID: SM64ObjectID
        let bottomID: SM64ObjectID
    }

    private struct Placement: Equatable, Sendable {
        let position: SM64ObjectVector3
        let yaw: Int32
        let behaviorParameter: Int32
    }

    private let scheduler: SM64ObjectScheduler
    private var roles: [SM64ObjectID: SM64TreasureChestObjectRole] = [:]
    private var rootStates: [SM64ObjectID: SM64TreasureChestRootState] = [:]
    private var bottomStates: [SM64ObjectID: BottomState] = [:]
    private var topStates: [SM64ObjectID: TopState] = [:]
    private var childrenByRoot: [SM64ObjectID: [SM64ObjectID]] = [:]
    private var bottomByRoot: [SM64ObjectID: [SM64ObjectID]] = [:]
    private var topByBottom: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64TreasureChestObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    /// IDs are sorted by the pool's stable slot/generation identity.  The
    /// per-root child accessors below preserve source creation order.
    var registeredIDs: [SM64ObjectID] {
        roles.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func role(for id: SM64ObjectID) -> SM64TreasureChestObjectRole? {
        roles[id]
    }

    func rootState(for id: SM64ObjectID) -> SM64TreasureChestRootState? {
        rootStates[id]
    }

    /// Returns `[bottom1, top1, bottom2, top2, ...]`, exactly as the C init
    /// routines append children to the object pool.
    func children(of rootID: SM64ObjectID) -> [SM64ObjectID] {
        childrenByRoot[rootID] ?? []
    }

    func bottomIDs(of rootID: SM64ObjectID) -> [SM64ObjectID] {
        bottomByRoot[rootID] ?? []
    }

    func topID(of bottomID: SM64ObjectID) -> SM64ObjectID? {
        topByBottom[bottomID]
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    /// Spawns one source root and all four bottom/top pairs.  Child creation
    /// is synchronous and ordered; a failed child allocation rolls back only
    /// the objects created by this call before rethrowing the pool error.
    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        variant: SM64TreasureChestVariant = .standard,
        position: SM64ObjectVector3 = .zero,
        environmentalRegionHeight: Int32 = 0,
        environmentAvailable: Bool = false
    ) throws -> SM64ObjectID {
        let root = try engineState.spawnObject(
            in: .default,
            model: Self.rootModel,
            behaviorIdentity: Self.identity(for: variant)
        )
        var created = [root]
        do {
            guard attachRoot(
                root,
                variant: variant,
                position: position,
                environmentalRegionHeight: environmentalRegionHeight,
                environmentAvailable: environmentAvailable,
                in: engineState.objects
            ) else {
                throw SM64ObjectPoolError.invalidReference(root)
            }

            for placement in Self.placements(for: variant) {
                let bottom = try engineState.spawnObject(
                    in: .generalActor,
                    model: Self.bottomModel,
                    behaviorIdentity: Self.bottomBehaviorIdentity,
                    parent: root
                )
                created.append(bottom)
                guard attachBottom(
                    bottom,
                    rootID: root,
                    position: placement.position,
                    moveYaw: placement.yaw,
                    behaviorParameter: placement.behaviorParameter,
                    in: engineState.objects
                ) else {
                    throw SM64ObjectPoolError.invalidReference(bottom)
                }

                let top = try engineState.spawnObject(
                    in: .default,
                    model: Self.topModel,
                    behaviorIdentity: Self.topBehaviorIdentity,
                    parent: bottom
                )
                created.append(top)
                guard attachTop(
                    top,
                    rootID: root,
                    bottomID: bottom,
                    position: placement.position,
                    in: engineState.objects
                ) else {
                    throw SM64ObjectPoolError.invalidReference(top)
                }

            }
            return root
        } catch {
            // Detach owner bookkeeping first, then release the exact objects
            // allocated by this spawn.  No unrelated pool object is touched.
            for id in created.reversed() {
                remove(id)
                _ = engineState.objects.despawn(id)
            }
            throw error
        }
    }

    @discardableResult
    func spawnRoot(
        in engineState: SM64SwiftEngineState,
        variant: SM64TreasureChestVariant = .standard,
        position: SM64ObjectVector3 = .zero,
        environmentalRegionHeight: Int32 = 0,
        environmentAvailable: Bool = false
    ) throws -> SM64ObjectID {
        try spawn(
            in: engineState,
            variant: variant,
            position: position,
            environmentalRegionHeight: environmentalRegionHeight,
            environmentAvailable: environmentAvailable
        )
    }

    @discardableResult
    func spawnStandard(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        environmentalRegionHeight: Int32 = 0,
        environmentAvailable: Bool = false
    ) throws -> SM64ObjectID {
        try spawn(
            in: engineState,
            variant: .standard,
            position: position,
            environmentalRegionHeight: environmentalRegionHeight,
            environmentAvailable: environmentAvailable
        )
    }

    @discardableResult
    func spawnJRB(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawn(in: engineState, variant: .jrb, position: position)
    }

    @discardableResult
    func spawnJrb(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawnJRB(in: engineState, position: position)
    }

    @discardableResult
    func spawnShip(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        environmentalRegionHeight: Int32 = 0,
        environmentAvailable: Bool = false
    ) throws -> SM64ObjectID {
        try spawn(
            in: engineState,
            variant: .ship,
            position: position,
            environmentalRegionHeight: environmentalRegionHeight,
            environmentAvailable: environmentAvailable
        )
    }

    /// Attaches an already-spawned root and creates its source children. This
    /// is the entry point for a future level-loader/behavior-dispatch owner.
    @discardableResult
    func attachRoot(
        _ id: SM64ObjectID,
        variant: SM64TreasureChestVariant,
        position: SM64ObjectVector3 = .zero,
        environmentalRegionHeight: Int32 = 0,
        environmentAvailable: Bool = false,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, roles[id] == nil else { return false }
        roles[id] = .root
        rootStates[id] = SM64TreasureChestRootState(
            variant: variant,
            environmentalRegionHeight: environmentalRegionHeight,
            environmentAvailable: environmentAvailable
        )
        childrenByRoot[id] = []
        bottomByRoot[id] = []
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachBottom(
        _ id: SM64ObjectID,
        rootID: SM64ObjectID,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        behaviorParameter: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              pool.record(for: rootID) != nil,
              roles[rootID] == .root,
              roles[id] == nil,
              (1...4).contains(behaviorParameter) else { return false }
        roles[id] = .bottom
        bottomStates[id] = BottomState(
            rootID: rootID,
            behaviorParameter: behaviorParameter,
            distanceToMario: nil,
            marioYaw: nil
        )
        bottomByRoot[rootID, default: []].append(id)
        childrenByRoot[rootID, default: []].append(id)
        return pool.mutate(id) { record in
            record.parent = rootID
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.faceAngles.yaw = moveYaw
            record.behaviorParams2ndByte = behaviorParameter
            record.intangibleTimer = -1
            record.interactionType = Self.bottomInteractionType
            record.damageOrCoinValue = 1
            record.hitboxRadius = 300
            record.hitboxHeight = 300
            record.hurtboxRadius = 310
            record.hurtboxHeight = 310
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func attachTop(
        _ id: SM64ObjectID,
        rootID: SM64ObjectID,
        bottomID: SM64ObjectID,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              pool.record(for: bottomID) != nil,
              pool.record(for: rootID) != nil,
              roles[rootID] == .root,
              roles[bottomID] == .bottom,
              roles[id] == nil else { return false }
        roles[id] = .top
        topStates[id] = TopState(rootID: rootID, bottomID: bottomID)
        topByBottom[bottomID] = id
        childrenByRoot[rootID, default: []].append(id)
        return pool.mutate(id) { record in
            record.parent = bottomID
            record.position = position
            record.homePosition = position
            record.parentRelativePosition = SM64ObjectVector3(x: 0, y: 102, z: -77)
            record.objectFlags |= SM64ObjectScheduler.objectFlagTransformRelativeToParent
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    /// Supplies the environment region pointer/value used by the ship root.
    /// The actual region storage remains outside this owner; this is its
    /// generation-safe value boundary.
    @discardableResult
    func setEnvironment(
        regionHeight: Int32,
        available: Bool,
        for rootID: SM64ObjectID
    ) -> Bool {
        guard var state = rootStates[rootID] else { return false }
        state.environmentalRegionHeight = regionHeight
        state.environmentAvailable = available
        rootStates[rootID] = state
        return true
    }

    @discardableResult
    func setSequence(_ sequence: Int32, for rootID: SM64ObjectID) -> Bool {
        guard var state = rootStates[rootID] else { return false }
        state.sequence = sequence
        rootStates[rootID] = state
        return true
    }

    /// Optional test/input override. If unset, the bridge reads distance and
    /// movement yaw from the object record and Mario yaw from engine globals.
    @discardableResult
    func setBottomInput(
        distanceToMario: Float?,
        marioYaw: Int32?,
        for bottomID: SM64ObjectID
    ) -> Bool {
        guard var state = bottomStates[bottomID] else { return false }
        guard distanceToMario == nil || distanceToMario!.isFinite else { return false }
        state.distanceToMario = distanceToMario
        state.marioYaw = marioYaw
        bottomStates[bottomID] = state
        return true
    }

    /// Updates one object from the shared scheduler. No nested traversal is
    /// created here; the enclosing dispatcher remains list-order authority.
    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> Bool {
        guard let role = roles[id], engineState.objects.record(for: id) != nil else {
            return false
        }

        switch role {
        case .root:
            return updateRoot(id, state: engineState)
        case .bottom:
            return updateBottom(id, state: engineState)
        case .top:
            return updateTop(id, state: engineState)
        }
    }

    /// Runs one standalone owner tick for focused tests or a non-central
    /// caller. The same scheduler is used by the eventual dispatch lane.
    @discardableResult
    func tick(in engineState: SM64SwiftEngineState) -> SM64TreasureChestSchedulerTickResult {
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, _ in
            guard let self else { return }
            _ = self.updateInline(id, state: engineState)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64TreasureChestSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog
        )
    }

    func remove(_ id: SM64ObjectID) {
        if roles[id] == .root {
            let descendants = childrenByRoot[id] ?? []
            for descendant in descendants {
                roles.removeValue(forKey: descendant)
                bottomStates.removeValue(forKey: descendant)
                topStates.removeValue(forKey: descendant)
                topByBottom.removeValue(forKey: descendant)
            }
            for bottomID in bottomByRoot[id] ?? [] {
                topByBottom.removeValue(forKey: bottomID)
            }
        } else if roles[id] == .bottom, let topID = topByBottom[id] {
            roles.removeValue(forKey: topID)
            topStates.removeValue(forKey: topID)
            topByBottom.removeValue(forKey: id)
        }
        roles.removeValue(forKey: id)
        rootStates.removeValue(forKey: id)
        bottomStates.removeValue(forKey: id)
        topStates.removeValue(forKey: id)
        topByBottom.removeValue(forKey: id)

        for rootID in Array(childrenByRoot.keys) {
            childrenByRoot[rootID]?.removeAll { $0 == id }
            bottomByRoot[rootID]?.removeAll { $0 == id }
        }
        for bottomID in Array(topByBottom.keys) where topByBottom[bottomID] == id {
            topByBottom.removeValue(forKey: bottomID)
        }
        childrenByRoot.removeValue(forKey: id)
        bottomByRoot.removeValue(forKey: id)
    }

    /// Removes owner shadows for unloaded IDs and retires descendants whose
    /// parent disappeared first. Pool destruction remains scheduler-owned.
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        let unloadedSet = Set(unloaded)
        let missingRoots = rootStates.keys.filter {
            unloadedSet.contains($0) || pool.record(for: $0) == nil
        }
        for rootID in missingRoots {
            let descendants = childrenByRoot[rootID] ?? []
            for childID in descendants where pool.record(for: childID) != nil {
                _ = pool.markForDeletion(childID)
            }
            remove(rootID)
        }

        for id in registeredIDs where pool.record(for: id) == nil {
            remove(id)
        }
        let orphanedTops = topByBottom.filter { bottomID, _ in
            pool.record(for: bottomID) == nil
        }
        for (bottomID, topID) in orphanedTops {
            _ = pool.markForDeletion(topID)
            remove(topID)
            topByBottom.removeValue(forKey: bottomID)
        }
    }

    private func updateRoot(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> Bool {
        guard var root = rootStates[id], let record = engineState.objects.record(for: id) else {
            return false
        }
        let output = SM64TreasureChestBehavior.updateRoot(&root)
        rootStates[id] = root
        _ = engineState.objects.mutate(id) { next in
            next.action = Int32(output.action.rawValue)
            next.timer = output.timer
            next.behaviorParams = output.sequence
            next.behaviorParams2ndByte = output.wrongLock
            if !output.active { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(
            SM64TreasureChestObjectEffectRecord(
                objectID: id,
                role: .root,
                variant: root.variant,
                output: .root(output),
                spawnedChildren: []
            )
        )
        _ = record
        return true
    }

    private func updateBottom(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> Bool {
        guard var bottom = bottomStates[id],
              var root = rootStates[bottom.rootID],
              let record = engineState.objects.record(for: id) else {
            return false
        }
        let marioYaw = bottom.marioYaw ?? engineState.globals.marioObject.flatMap {
            engineState.objects.record(for: $0)?.faceAngles.yaw
        } ?? 0
        let input = SM64TreasureChestBottomInput(
            action: SM64TreasureChestBottomAction(rawValue: UInt8(clamping: record.action)) ?? .idle,
            timer: record.timer,
            behaviorParameter: bottom.behaviorParameter,
            parentSequence: root.sequence,
            parentWrongLock: root.wrongLock,
            intangibleTimer: record.intangibleTimer,
            distanceToMario: bottom.distanceToMario ?? record.distanceToMario,
            moveYaw: record.moveAngles.yaw,
            marioYaw: marioYaw
        )
        let output = SM64TreasureChestBehavior.updateBottom(input)
        root.sequence = output.parentSequence
        root.wrongLock = output.parentWrongLock
        rootStates[bottom.rootID] = root
        bottom.distanceToMario = nil
        bottom.marioYaw = nil
        bottomStates[id] = bottom
        _ = engineState.objects.mutate(id) { next in
            next.action = Int32(output.action.rawValue)
            next.timer = output.timer
            next.intangibleTimer = output.intangibleTimer
            next.interactionStatus = 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        _ = engineState.objects.mutate(bottom.rootID) { next in
            next.behaviorParams = root.sequence
            next.behaviorParams2ndByte = root.wrongLock
        }
        effectLog.append(
            SM64TreasureChestObjectEffectRecord(
                objectID: id,
                role: .bottom,
                variant: root.variant,
                output: .bottom(output),
                spawnedChildren: []
            )
        )
        return true
    }

    private func updateTop(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> Bool {
        guard let top = topStates[id],
              let root = rootStates[top.rootID],
              let bottomRecord = engineState.objects.record(for: top.bottomID),
              let record = engineState.objects.record(for: id) else {
            return false
        }
        let input = SM64TreasureChestTopInput(
            action: SM64TreasureChestTopAction(rawValue: UInt8(clamping: record.action)) ?? .closed,
            timer: record.timer,
            facePitch: record.faceAngles.pitch,
            parentBottomAction: SM64TreasureChestBottomAction(rawValue: UInt8(clamping: bottomRecord.action)) ?? .idle,
            rootMode: root.mode,
            behaviorParameter: bottomRecord.behaviorParams2ndByte
        )
        let output = SM64TreasureChestBehavior.updateTop(input)
        _ = engineState.objects.mutate(id) { next in
            next.action = Int32(output.action.rawValue)
            next.timer = output.timer
            next.faceAngles.pitch = output.facePitch
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(
            SM64TreasureChestObjectEffectRecord(
                objectID: id,
                role: .top,
                variant: root.variant,
                output: .top(output),
                spawnedChildren: []
            )
        )
        return true
    }

    private static func identity(for variant: SM64TreasureChestVariant) -> UInt64 {
        switch variant {
        case .standard: return defaultBehaviorIdentity
        case .jrb: return jrbBehaviorIdentity
        case .ship: return shipBehaviorIdentity
        }
    }

    private static func placements(
        for variant: SM64TreasureChestVariant
    ) -> [Placement] {
        switch variant {
        case .ship:
            return [
                Placement(position: .init(x: 400, y: -350, z: -2700), yaw: 0, behaviorParameter: 1),
                Placement(position: .init(x: 650, y: -350, z: -940), yaw: -0x6001, behaviorParameter: 2),
                Placement(position: .init(x: -550, y: -350, z: -770), yaw: 0x5FFF, behaviorParameter: 3),
                Placement(position: .init(x: 100, y: -350, z: -1700), yaw: 0, behaviorParameter: 4),
            ]
        case .jrb:
            return [
                Placement(position: .init(x: -1700, y: -2812, z: -1150), yaw: 0x7FFF, behaviorParameter: 1),
                Placement(position: .init(x: -1150, y: -2812, z: -1550), yaw: 0x7FFF, behaviorParameter: 2),
                Placement(position: .init(x: -2400, y: -2812, z: -1800), yaw: 0x7FFF, behaviorParameter: 3),
                Placement(position: .init(x: -1800, y: -2812, z: -2100), yaw: 0x7FFF, behaviorParameter: 4),
            ]
        case .standard:
            return [
                Placement(position: .init(x: -4500, y: -5119, z: 1300), yaw: -0x6001, behaviorParameter: 1),
                Placement(position: .init(x: -1800, y: -5119, z: 1050), yaw: 0x1FFF, behaviorParameter: 2),
                Placement(position: .init(x: -4500, y: -5119, z: -1100), yaw: 9102, behaviorParameter: 3),
                Placement(position: .init(x: -2400, y: -4607, z: 125), yaw: 16019, behaviorParameter: 4),
            ]
        }
    }
}
