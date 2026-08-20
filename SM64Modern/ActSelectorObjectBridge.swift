import Foundation

/// Owner-side receipt for one act-selector logical update.  The selector
/// kernel only returns values; this record is the narrow value boundary used
/// by the eventual renderer/effect router.
struct SM64ActSelectorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ActSelectorLoopOutput
    let starIDs: [SM64ObjectID]
}

/// The mutable portion of one selector lives with its owner, rather than in
/// an object pointer or a C static.  Child IDs are generation-scoped Swift
/// references and are intentionally included in the value snapshot so a
/// route can prove that it still owns the exact stars it spawned.
struct SM64ActSelectorObjectState: Equatable, Sendable {
    let stars: UInt8
    let obtainedStars: Int32
    let initialSelectedActNum: Int32
    let visibleStars: Int32
    let starIDs: [SM64ObjectID]
    var selectedActIndex: Int32
    var selectableStarIndex: Int32
    var menuHoldKeyIndex: Int32
    var menuHoldKeyTimer: Int32
    var selectorTypes: [SM64ActSelectorType]
}

/// Owner-thread bridge for `bhv_act_selector`.
///
/// `bhv_act_selector_init` creates a parent plus one child object per visible
/// star (and, when earned, the 100-coin star).  The bridge keeps that parent /
/// child relationship generation-safe and delegates only the value logic to
/// `SM64ActSelectorBehavior`.  The existing star-type bridge is injected so a
/// parent selection change can update the child behavior's type without
/// exposing its private state to the C side.
final class SM64ActSelectorObjectBridge {
    /// `bhv_act_selector`, encoded with the same short fixed-width identity
    /// convention used by the other Swift behavior bridges.
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6173_6C
    static let defaultModel: UInt32 = 0
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let transparentStarModel: UInt32 = 0x79 // MODEL_TRANSPARENT_STAR
    static let starTypeBehaviorIdentity: UInt64 =
        SM64ActSelectorStarTypeObjectBridge.defaultBehaviorIdentity

    private let scheduler: SM64ObjectScheduler
    private let starTypeBridge: SM64ActSelectorStarTypeObjectBridge
    private var states: [SM64ObjectID: SM64ActSelectorObjectState] = [:]
    private(set) var effectLog: [SM64ActSelectorObjectEffectRecord] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        starTypeBridge: SM64ActSelectorStarTypeObjectBridge = SM64ActSelectorStarTypeObjectBridge()
    ) {
        self.scheduler = scheduler
        self.starTypeBridge = starTypeBridge
    }

    /// The injected bridge is shared with central dispatch for the child
    /// `bhvActSelectorStarType` route.  It is read-only from the outside so
    /// the owner remains responsible for attach/remove ordering.
    var childBridge: SM64ActSelectorStarTypeObjectBridge { starTypeBridge }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func state(for id: SM64ObjectID) -> SM64ActSelectorObjectState? {
        states[id]
    }

    func childIDs(for id: SM64ObjectID) -> [SM64ObjectID] {
        states[id]?.starIDs ?? []
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    /// Creates the C-equivalent selector object and all star children.  The
    /// parent is returned only after every child has attached successfully;
    /// partial initialization is rolled back to avoid orphan IDs.
    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        input: SM64ActSelectorInitializationInput,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: Self.defaultModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, input: input, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned act selector could not attach")
        }
        return id
    }

    /// Named variant matching bridges that call their root object a manager.
    @discardableResult
    func spawnSelector(
        in engineState: SM64SwiftEngineState,
        input: SM64ActSelectorInitializationInput,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawn(in: engineState, input: input, position: position)
    }

    /// Attaches an already allocated parent and transactionally allocates its
    /// star children from the same owner pool.
    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        input: SM64ActSelectorInitializationInput,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, states[id] == nil else { return false }

        let initialization = SM64ActSelectorBehavior.initialize(input)
        var children: [SM64ObjectID] = []
        children.reserveCapacity(initialization.spawnRequests.count)

        for request in initialization.spawnRequests {
            do {
                let child = try pool.spawn(
                    in: .default,
                    model: request.model.rawValue,
                    behaviorIdentity: Self.starTypeBehaviorIdentity,
                    parent: id
                )
                let type = SM64ActSelectorStarType(rawValue: request.type.rawValue)
                    ?? .notSelected
                guard starTypeBridge.attach(
                    child,
                    type: type,
                    position: SM64ObjectVector3(
                        x: Float(request.position.x),
                        y: Float(request.position.y),
                        z: Float(request.position.z)
                    ),
                    size: request.size,
                    in: pool
                ) else {
                    _ = pool.despawn(child)
                    throw SM64ActSelectorAttachError.childAttachFailed
                }
                children.append(child)
            } catch {
                for child in children {
                    starTypeBridge.remove(child)
                    _ = pool.despawn(child)
                }
                return false
            }
        }

        let state = SM64ActSelectorObjectState(
            stars: initialization.stars,
            obtainedStars: initialization.obtainedStars,
            initialSelectedActNum: initialization.initialSelectedActNum,
            visibleStars: initialization.visibleStars,
            starIDs: children,
            selectedActIndex: initialization.selectedActIndex,
            selectableStarIndex: initialization.selectableStarIndex,
            menuHoldKeyIndex: 0,
            menuHoldKeyTimer: 0,
            selectorTypes: initialization.selectorTypes
        )
        states[id] = state

        guard pool.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams = initialization.obtainedStars
            record.behaviorParams2ndByte = Int32(initialization.stars)
            record.dialogState = Int16(clamping: Int(initialization.initialSelectedActNum))
            record.action = initialization.selectedActIndex
            record.subAction = initialization.selectableStarIndex
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            remove(id, from: pool)
            return false
        }
        return true
    }

    /// Updates the selector using an immutable input value and mirrors the
    /// resulting selection into each child star's generation-scoped state.
    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState,
        rawStickX: Int32 = 0,
        advanceLegacyDomain: Bool = true
    ) -> SM64ActSelectorObjectEffectRecord? {
        guard var owner = states[id], engineState.objects.record(for: id) != nil else {
            return nil
        }
        guard owner.starIDs.allSatisfy({ engineState.objects.record(for: $0) != nil }) else {
            return nil
        }

        let output = SM64ActSelectorBehavior.update(
            SM64ActSelectorLoopInput(
                stars: owner.stars,
                obtainedStars: owner.obtainedStars,
                initialSelectedActNum: owner.initialSelectedActNum,
                visibleStars: owner.visibleStars,
                selectedActIndex: owner.selectedActIndex,
                selectableStarIndex: owner.selectableStarIndex,
                menuHoldKeyIndex: owner.menuHoldKeyIndex,
                menuHoldKeyTimer: owner.menuHoldKeyTimer,
                rawStickX: rawStickX,
                selectorTypes: owner.selectorTypes,
                advanceLegacyDomain: advanceLegacyDomain
            )
        )

        owner.selectedActIndex = output.selectedActIndex
        owner.selectableStarIndex = output.selectableStarIndex
        owner.menuHoldKeyIndex = output.menuHoldKeyIndex
        owner.menuHoldKeyTimer = output.menuHoldKeyTimer
        owner.selectorTypes = output.selectorTypes
        states[id] = owner

        _ = engineState.objects.mutate(id) { record in
            record.action = output.selectedActIndex
            record.subAction = output.selectableStarIndex
            record.behaviorParams2ndByte = output.menuHoldKeyIndex
            record.timer = output.menuHoldKeyTimer
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }

        if advanceLegacyDomain {
            synchronizeChildTypes(owner.starIDs, types: output.selectorTypes, in: engineState.objects)
        }

        let effect = SM64ActSelectorObjectEffectRecord(
            objectID: id,
            output: output,
            starIDs: owner.starIDs
        )
        effectLog.append(effect)
        return effect
    }

    /// Compatibility label used by existing owner bridges and dispatch code.
    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState,
        rawStickX: Int32,
        legacyDomainAdvances: Bool
    ) -> SM64ActSelectorObjectEffectRecord? {
        updateInline(
            id,
            state: engineState,
            rawStickX: rawStickX,
            advanceLegacyDomain: legacyDomainAdvances
        )
    }

    /// Runs the selector parent and its star-type children in the C object
    /// list order.  The shared child bridge is intentionally returned so the
    /// central owner can route/render child effects without duplicating state.
    struct SchedulerTickResult: Equatable, Sendable {
        let scheduler: SM64ObjectSchedulerTickResult
        let effects: [SM64ActSelectorObjectEffectRecord]
        let starTypeEffects: [SM64ActSelectorStarTypeObjectEffectRecord]
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        rawStickXByID: [SM64ObjectID: Int32] = [:],
        advanceLegacyDomain: Bool = true
    ) -> SchedulerTickResult {
        beginExternalTick()
        starTypeBridge.beginExternalTick()
        let result = scheduler.update(
            state: engineState,
            advanceLegacyDomain: advanceLegacyDomain
        ) { [weak self] id, _ in
            guard let self else { return }
            if self.states[id] != nil {
                _ = self.updateInline(
                    id,
                    state: engineState,
                    rawStickX: rawStickXByID[id] ?? 0,
                    advanceLegacyDomain: advanceLegacyDomain
                )
            } else if advanceLegacyDomain && self.starTypeBridge.registeredIDs.contains(id) {
                _ = self.starTypeBridge.updateInline(id, state: engineState)
            }
        }
        pruneExternal(unloaded: result.unloaded, pool: engineState.objects)
        return SchedulerTickResult(
            scheduler: result,
            effects: effectLog,
            starTypeEffects: starTypeBridge.effectLog
        )
    }

    /// Removes owner bookkeeping.  The optional pool is used by callers that
    /// own the actual end-of-frame unload; it marks children for that same
    /// unload rather than silently leaving orphan records in the pool.
    func remove(_ id: SM64ObjectID) {
        guard let owner = states.removeValue(forKey: id) else { return }
        for child in owner.starIDs { starTypeBridge.remove(child) }
    }

    func remove(_ id: SM64ObjectID, from pool: SM64ObjectPool) {
        guard let owner = states.removeValue(forKey: id) else { return }
        for child in owner.starIDs {
            starTypeBridge.remove(child)
            _ = pool.markForDeletion(child)
        }
        _ = pool.markForDeletion(id)
    }

    /// Cleans both parent and child state after an external unload/reset.  A
    /// parent with a missing child is retired as one unit, preserving the
    /// C invariant that every visible star has exactly one owner record.
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        let unloadedSet = Set(unloaded)
        let retired = registeredIDs.filter { id in
            guard let owner = states[id] else { return true }
            if unloadedSet.contains(id) || pool.record(for: id) == nil { return true }
            return owner.starIDs.contains { child in
                unloadedSet.contains(child) || pool.record(for: child) == nil
            }
        }
        for id in retired {
            if let owner = states[id] {
                for child in owner.starIDs {
                    starTypeBridge.remove(child)
                    if pool.record(for: child) != nil && !unloadedSet.contains(child) {
                        _ = pool.despawn(child)
                    }
                }
            }
            remove(id)
            if pool.record(for: id) != nil { _ = pool.markForDeletion(id) }
        }
        starTypeBridge.pruneExternal(unloaded: unloaded, pool: pool)
    }

    private func synchronizeChildTypes(
        _ children: [SM64ObjectID],
        types: [SM64ActSelectorType],
        in pool: SM64ObjectPool
    ) {
        for (index, child) in children.enumerated() {
            guard let desired = types[safe: index], let record = pool.record(for: child) else {
                continue
            }
            let current = SM64ActSelectorStarType(rawValue: UInt8(clamping: record.animationState))
                ?? .notSelected
            guard current.rawValue != desired.rawValue else { continue }
            starTypeBridge.remove(child)
            _ = starTypeBridge.attach(
                child,
                type: SM64ActSelectorStarType(rawValue: desired.rawValue) ?? .notSelected,
                position: record.position,
                size: record.scale.x,
                in: pool
            )
        }
    }
}

private enum SM64ActSelectorAttachError: Error {
    case childAttachFailed
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
