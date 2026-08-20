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

private func hashValues(_ initial: UInt64, _ values: [UInt64]) -> UInt64 {
    values.reduce(initial, hashU64)
}

private func signed(_ value: Int32) -> UInt64 {
    UInt64(bitPattern: Int64(value))
}

private func hashRoot(_ initial: UInt64, _ output: SM64TreasureChestRootOutput) -> UInt64 {
    hashValues(initial, [
        UInt64(output.action.rawValue), signed(output.timer), signed(output.sequence),
        signed(output.wrongLock), signed(output.environmentalRegionHeight), output.active ? 1 : 0,
        UInt64(output.effects.rawValue),
    ])
}

private func hashBottom(_ initial: UInt64, _ output: SM64TreasureChestBottomOutput) -> UInt64 {
    hashValues(initial, [
        UInt64(output.action.rawValue), signed(output.timer), signed(output.parentSequence),
        signed(output.parentWrongLock), signed(output.intangibleTimer),
        UInt64(output.effects.rawValue),
    ])
}

private func hashTop(_ initial: UInt64, _ output: SM64TreasureChestTopOutput) -> UInt64 {
    hashValues(initial, [
        UInt64(output.action.rawValue), signed(output.timer), signed(output.facePitch),
        UInt64(output.effects.rawValue),
    ])
}

private func hashBridgeEffect(
    _ initial: UInt64,
    _ effect: SM64TreasureChestObjectEffectRecord,
    pool: SM64ObjectPool
) -> UInt64 {
    let record = pool.record(for: effect.objectID)
    var hash = hashValues(initial, [
        UInt64(effect.objectID.traceSubject), UInt64(effect.role.rawValue),
        UInt64(effect.variant.rawValue), UInt64(record?.objectList.rawValue ?? 255),
        UInt64(record?.parent.traceSubject ?? 0),
    ])
    switch effect.output {
    case let .root(output): hash = hashRoot(hash, output)
    case let .bottom(output): hash = hashBottom(hash, output)
    case let .top(output): hash = hashTop(hash, output)
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernTreasureChestSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var standard = SM64TreasureChestRootState(variant: .standard)
        standard.sequence = 5
        let standardStart = SM64TreasureChestBehavior.updateRoot(&standard)
        require(standardStart.action == .started && standardStart.timer == 0,
                "standard puzzle start")
        require(standardStart.effects == [.puzzleJingle], "standard puzzle jingle")
        fingerprint = hashRoot(fingerprint, standardStart)

        standard.timer = 60
        let standardComplete = SM64TreasureChestBehavior.updateRoot(&standard)
        require(standardComplete.action == .completed && standardComplete.timer == 0,
                "standard puzzle completion")
        require(standardComplete.effects == [.mist, .star], "standard reward effects")
        fingerprint = hashRoot(fingerprint, standardComplete)

        var jrb = SM64TreasureChestRootState(variant: .jrb)
        jrb.sequence = 5
        let jrbStart = SM64TreasureChestBehavior.updateRoot(&jrb)
        require(jrb.mode == 1 && jrbStart.effects == [.puzzleJingle], "JRB mode")
        fingerprint = hashRoot(fingerprint, jrbStart)
        jrb.timer = 60
        let jrbComplete = SM64TreasureChestBehavior.updateRoot(&jrb)
        require(jrbComplete.effects == [.mist, .star], "JRB reward effects")
        fingerprint = hashRoot(fingerprint, jrbComplete)

        var ship = SM64TreasureChestRootState(
            variant: .ship,
            environmentalRegionHeight: -330,
            environmentAvailable: true
        )
        ship.sequence = 5
        let shipStart = SM64TreasureChestBehavior.updateRoot(&ship)
        require(shipStart.effects == [.puzzleJingle, .fadeVolume], "ship puzzle start")
        fingerprint = hashRoot(fingerprint, shipStart)
        let shipDrain = SM64TreasureChestBehavior.updateRoot(&ship)
        require(shipDrain.environmentalRegionHeight == -335 && shipDrain.active,
                "ship drain step")
        fingerprint = hashRoot(fingerprint, shipDrain)
        let shipDeactivate = SM64TreasureChestBehavior.updateRoot(&ship)
        require(!shipDeactivate.active && shipDeactivate.effects.contains(.deactivate),
                "ship drain deactivation")
        fingerprint = hashRoot(fingerprint, shipDeactivate)

        let correct = SM64TreasureChestBehavior.updateBottom(
            SM64TreasureChestBottomInput(
                behaviorParameter: 1,
                parentSequence: 1,
                parentWrongLock: 0,
                distanceToMario: 149,
                moveYaw: 0,
                marioYaw: 0x8000
            )
        )
        require(correct.action == .correct && correct.parentSequence == 2,
                "correct chest answer")
        require(correct.intangibleTimer == -1 && correct.effects.contains(.rightAnswer),
                "correct chest collision")
        fingerprint = hashBottom(fingerprint, correct)

        let wrong = SM64TreasureChestBehavior.updateBottom(
            SM64TreasureChestBottomInput(
                behaviorParameter: 2,
                parentSequence: 1,
                parentWrongLock: 0,
                distanceToMario: 149,
                moveYaw: 0,
                marioYaw: 0x8000
            )
        )
        require(wrong.action == .wrong && wrong.parentSequence == 1 && wrong.parentWrongLock == 1,
                "wrong chest answer")
        require(wrong.intangibleTimer == 0 && wrong.effects.contains(.wrongAnswer),
                "wrong chest collision")
        fingerprint = hashBottom(fingerprint, wrong)

        let wrongCleared = SM64TreasureChestBehavior.updateBottom(
            SM64TreasureChestBottomInput(
                action: .wrong,
                timer: 4,
                behaviorParameter: 2,
                parentSequence: 1,
                parentWrongLock: 1,
                intangibleTimer: 0,
                distanceToMario: 500,
                moveYaw: 0,
                marioYaw: 0x8000
            )
        )
        require(wrongCleared.action == .idle && wrongCleared.parentWrongLock == 0
                    && wrongCleared.intangibleTimer == -1,
                "wrong chest lock clear")
        fingerprint = hashBottom(fingerprint, wrongCleared)

        let opening = SM64TreasureChestBehavior.updateTop(
            SM64TreasureChestTopInput(
                action: .opening,
                timer: 0,
                facePitch: 0,
                parentBottomAction: .correct,
                rootMode: 0,
                behaviorParameter: 1
            )
        )
        require(opening.facePitch == -0x200 && opening.effects == [.spawnBubble],
                "underwater chest opening")
        fingerprint = hashTop(fingerprint, opening)

        let open = SM64TreasureChestBehavior.updateTop(
            SM64TreasureChestTopInput(
                action: .opening,
                timer: 2,
                facePitch: -0x4000,
                parentBottomAction: .correct,
                rootMode: 1,
                behaviorParameter: 1
            )
        )
        require(open.action == .open && open.effects == [.orangeNumber],
                "JRB chest opening completion")
        fingerprint = hashTop(fingerprint, open)

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64TreasureChestObjectBridge()
        let rootID = try bridge.spawnJRB(in: engineState)
        let children = bridge.children(of: rootID)
        require(rootID.traceSubject == 1 && children.count == 8,
                "JRB root child count")
        require(children.map(\.traceSubject) == [2, 3, 4, 5, 6, 7, 8, 9],
                "source child creation order")
        require(engineState.objects.ids(in: .generalActor).map(\.traceSubject) == [2, 4, 6, 8],
                "source bottom object-list order")
        require(engineState.objects.ids(in: .default).map(\.traceSubject) == [1, 3, 5, 7, 9],
                "source root/top object-list order")
        for (index, childID) in children.enumerated() {
            guard let record = engineState.objects.record(for: childID) else {
                preconditionFailure("missing JRB child record")
            }
            if index.isMultiple(of: 2) {
                require(record.parent == rootID && record.behaviorParams2ndByte == Int32(index / 2 + 1),
                        "bottom parent/parameter")
            } else {
                require(record.parent == children[index - 1], "top parent order")
            }
        }

        for bottomID in bridge.bottomIDs(of: rootID) {
            guard let bottomRecord = engineState.objects.record(for: bottomID) else {
                preconditionFailure("missing bridge bottom record")
            }
            require(bridge.setBottomInput(
                distanceToMario: 100,
                marioYaw: bottomRecord.moveAngles.yaw &- 0x8000,
                for: bottomID
            ),
                    "bridge bottom input")
        }
        require(bridge.setSequence(1, for: rootID), "bridge root sequence")
        let bridgeTick = bridge.tick(in: engineState)
        require(bridgeTick.effects.map(\.role) == [.bottom, .bottom, .bottom, .bottom, .root, .top, .top, .top, .top],
                "shared scheduler source list order")
        guard let rootEffect = bridgeTick.effects.first(where: { $0.objectID == rootID }) else {
            preconditionFailure("missing bridge root effect")
        }
        if case let .root(output) = rootEffect.output {
            require(output.action == .started && output.sequence == 5,
                    "bridge root observes completed child puzzle")
        } else {
            preconditionFailure("root effect output role")
        }
        require(bridgeTick.effects.filter({ $0.role == .top }).allSatisfy {
            if case let .top(output) = $0.output { return output.action == .opening }
            return false
        }, "bridge top observes bottom answers")
        for effect in bridgeTick.effects {
            fingerprint = hashBridgeEffect(fingerprint, effect, pool: engineState.objects)
        }

        let retirementState = SM64SwiftEngineState(objectCapacity: 32)
        let retirementBridge = SM64TreasureChestObjectBridge()
        let retirementRoot = try retirementBridge.spawnStandard(in: retirementState)
        let retirementChildren = retirementBridge.children(of: retirementRoot)
        require(SM64ObjectPool.activeFlagActive != 0, "pool lifecycle constants")
        require(retirementState.objects.markForDeletion(retirementRoot), "root retirement mark")
        let retirementTick = retirementBridge.tick(in: retirementState)
        require(retirementTick.scheduler.unloaded.contains(retirementRoot), "root retirement unload")
        require(retirementBridge.registeredIDs.isEmpty, "root retirement owner cleanup")
        require(retirementChildren.allSatisfy {
            retirementState.objects.record(for: $0).map {
                $0.activeFlags & SM64ObjectPool.activeFlagActive == 0
            } == true
        }, "root retirement child fence")

        print(String(format: "treasureChestFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern treasure chest smoke passed")
    }
}
