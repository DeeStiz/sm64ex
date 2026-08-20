import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashI32(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU64(initial, UInt64(bitPattern: Int64(value)))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashInitialization(
    _ initial: UInt64,
    _ output: SM64ActSelectorInitializationOutput
) -> UInt64 {
    var hash = hashU64(initial, UInt64(output.stars))
    hash = hashI32(hash, output.obtainedStars)
    hash = hashI32(hash, output.initialSelectedActNum)
    hash = hashI32(hash, output.visibleStars)
    hash = hashI32(hash, output.selectableStarIndex)
    hash = hashI32(hash, output.selectedActIndex)
    hash = hashU64(hash, UInt64(output.selectorTypes.count))
    for type in output.selectorTypes {
        hash = hashU64(hash, UInt64(type.rawValue))
    }
    hash = hashU64(hash, UInt64(output.spawnRequests.count))
    for request in output.spawnRequests {
        hash = hashU64(hash, UInt64(request.model.rawValue))
        hash = hashU64(hash, UInt64(request.type.rawValue))
        hash = hashI32(hash, request.position.x)
        hash = hashI32(hash, request.position.y)
        hash = hashI32(hash, request.position.z)
        hash = hashFloat(hash, request.size)
    }
    return hash
}

private func hashLoop(_ initial: UInt64, _ output: SM64ActSelectorLoopOutput) -> UInt64 {
    var hash = hashI32(initial, output.selectedActIndex)
    hash = hashI32(hash, output.selectableStarIndex)
    hash = hashI32(hash, output.menuHoldKeyIndex)
    hash = hashI32(hash, output.menuHoldKeyTimer)
    hash = hashU64(hash, UInt64(output.selectorTypes.count))
    for type in output.selectorTypes {
        hash = hashU64(hash, UInt64(type.rawValue))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernActSelectorSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        let cases: [SM64ActSelectorInitializationInput] = [
            .init(stars: 0x00, obtainedStars: 0),
            .init(stars: 0x15, obtainedStars: 3),
            .init(stars: 0x3F, obtainedStars: 6),
            .init(stars: 0x41, obtainedStars: 0),
            .init(
                stars: 0x05,
                obtainedStars: 2,
                initialSelectedActNum: 4,
                initialSelectableStarIndex: 3,
                initialSelectedActIndex: 1
            ),
        ]
        let initializations = cases.map(SM64ActSelectorBehavior.initialize)
        for output in initializations {
            fingerprint = hashInitialization(fingerprint, output)
        }

        let partial = initializations[1]
        let firstScroll = SM64ActSelectorBehavior.update(
            .init(
                stars: partial.stars,
                obtainedStars: partial.obtainedStars,
                initialSelectedActNum: partial.initialSelectedActNum,
                visibleStars: partial.visibleStars,
                selectedActIndex: partial.selectedActIndex,
                selectableStarIndex: partial.selectableStarIndex,
                rawStickX: 100,
                selectorTypes: partial.selectorTypes
            )
        )
        require(firstScroll.selectableStarIndex == 2, "partial selector scrolls right")
        require(firstScroll.selectedActIndex == 2, "partial selector selects collected star")
        require(firstScroll.selectorTypes[2] == SM64ActSelectorType.selected, "partial selected marker")
        fingerprint = hashLoop(fingerprint, firstScroll)

        let secondScroll = SM64ActSelectorBehavior.update(
            .init(
                stars: partial.stars,
                obtainedStars: partial.obtainedStars,
                initialSelectedActNum: partial.initialSelectedActNum,
                visibleStars: partial.visibleStars,
                selectedActIndex: firstScroll.selectedActIndex,
                selectableStarIndex: firstScroll.selectableStarIndex,
                menuHoldKeyIndex: firstScroll.menuHoldKeyIndex,
                menuHoldKeyTimer: firstScroll.menuHoldKeyTimer,
                rawStickX: -100,
                selectorTypes: firstScroll.selectorTypes
            )
        )
        require(secondScroll.selectableStarIndex == 1, "partial selector scrolls left")
        require(secondScroll.selectedActIndex == 1, "partial selector selects next mission")
        fingerprint = hashLoop(fingerprint, secondScroll)

        let held = SM64ActSelectorBehavior.update(
            .init(
                stars: partial.stars,
                obtainedStars: partial.obtainedStars,
                initialSelectedActNum: partial.initialSelectedActNum,
                visibleStars: partial.visibleStars,
                selectedActIndex: secondScroll.selectedActIndex,
                selectableStarIndex: secondScroll.selectableStarIndex,
                menuHoldKeyIndex: secondScroll.menuHoldKeyIndex,
                menuHoldKeyTimer: secondScroll.menuHoldKeyTimer,
                rawStickX: 100,
                selectorTypes: secondScroll.selectorTypes,
                advanceLegacyDomain: false
            )
        )
        require(held == .init(
            selectedActIndex: secondScroll.selectedActIndex,
            selectableStarIndex: secondScroll.selectableStarIndex,
            menuHoldKeyIndex: secondScroll.menuHoldKeyIndex,
            menuHoldKeyTimer: secondScroll.menuHoldKeyTimer,
            selectorTypes: secondScroll.selectorTypes
        ), "held half does not advance legacy selector state")
        fingerprint = hashLoop(fingerprint, held)

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64ActSelectorObjectBridge()
        let selectorID = try bridge.spawn(
            in: engineState,
            input: .init(stars: 0x25, obtainedStars: 3),
            position: SM64ObjectVector3(x: 11, y: 22, z: 33)
        )
        let childIDs = bridge.childIDs(for: selectorID)
        require(selectorID.traceSubject == 1, "selector parent gets first owner slot")
        require(childIDs.count == 6, "selector creates six visible children")
        require(bridge.registeredIDs == [selectorID], "selector owner registration")
        for (index, childID) in childIDs.enumerated() {
            guard let record = engineState.objects.record(for: childID) else {
                preconditionFailure("selector child record missing")
            }
            require(record.parent == selectorID, "selector child parent link")
            require(record.model == (index == 0 || index == 2 || index == 5 ? 0x7A : 0x79), "selector child model")
            require(record.position.y == 248 && record.position.z == -300, "selector child position")
        }

        guard let bridgeEffect = bridge.updateInline(
            selectorID,
            state: engineState,
            rawStickX: 100
        ) else {
            preconditionFailure("selector bridge effect missing")
        }
        require(bridgeEffect.output.selectedActIndex == 2, "bridge selector update")
        require(bridge.state(for: selectorID)?.selectorTypes[2] == .selected, "bridge selected type")
        guard let selectedRecord = engineState.objects.record(for: childIDs[2]) else {
            preconditionFailure("selected selector child missing")
        }
        require(selectedRecord.animationState == Int32(SM64ActSelectorType.selected.rawValue), "bridge child type mirror")

        // Hash the owner-visible values as well as the pure kernel.  The C
        // contract below mirrors these fixed source values, while IDs remain
        // trace subjects (slot + 1), not Swift generation internals.
        fingerprint = hashU64(fingerprint, UInt64(selectorID.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(childIDs.count))
        for (index, childID) in childIDs.enumerated() {
            fingerprint = hashU64(fingerprint, UInt64(childID.traceSubject))
            fingerprint = hashU64(fingerprint, UInt64(selectorID.traceSubject))
            fingerprint = hashU64(fingerprint, UInt64(index == 0 || index == 2 || index == 5 ? 0x7A : 0x79))
        }
        fingerprint = hashLoop(fingerprint, bridgeEffect.output)

        // A child can disappear between object-list traversal and the owner
        // callback.  Retire the parent and all remaining children together;
        // no stale generation-scoped IDs may survive a reset/unload boundary.
        let externallyUnloaded = childIDs[0]
        require(engineState.objects.despawn(externallyUnloaded), "external child unload")
        bridge.pruneExternal(unloaded: [externallyUnloaded], pool: engineState.objects)
        require(bridge.registeredIDs.isEmpty, "selector parent pruned with child")
        require(bridge.childBridge.registeredIDs.isEmpty, "selector children pruned with parent")
        _ = engineState.objects.unloadDeactivated()
        require(engineState.objects.record(for: selectorID) == nil, "selector parent retired")

        print(String(format: "actSelectorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern act-selector smoke passed")
    }
}
