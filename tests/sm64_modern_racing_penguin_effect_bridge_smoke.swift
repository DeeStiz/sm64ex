import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= UInt64((value >> UInt64(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashID(_ initial: UInt64, _ id: SM64ObjectID) -> UInt64 {
    let hash = hashU32(initial, UInt32(id.slot))
    return hashU32(hash, id.generation)
}

private func hashIntent(_ initial: UInt64, _ intent: SM64OwnerThreadEffectIntent) -> UInt64 {
    var hash = hashU64(initial, intent.sequence)
    hash = hashID(hash, intent.objectID)
    hash = hashU32(hash, UInt32(intent.kind.rawValue))
    hash = hashU32(hash, UInt32(bitPattern: intent.value))
    return hashU32(hash, UInt32(bitPattern: intent.auxiliary))
}

private func hashDelivery(_ initial: UInt64, _ delivery: SM64OwnerThreadEffectDeliveryResult)
    -> UInt64
{
    var hash = hashU32(initial, UInt32(delivery.delivered.count))
    for intent in delivery.delivered {
        hash = hashIntent(hash, intent)
    }
    hash = hashU32(hash, UInt32(delivery.presented.count))
    for intent in delivery.presented {
        hash = hashIntent(hash, intent)
    }
    hash = hashU32(hash, UInt32(delivery.spawned.count))
    for id in delivery.spawned {
        hash = hashID(hash, id)
    }
    hash = hashU32(hash, UInt32(delivery.deleted.count))
    for id in delivery.deleted {
        hash = hashID(hash, id)
    }
    hash = hashU32(hash, UInt32(delivery.rejected.count))
    for intent in delivery.rejected {
        hash = hashIntent(hash, intent)
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func presented(
    _ tick: SM64RacingPenguinSchedulerTickResult,
    kind: SM64OwnerThreadEffectKind,
    value: Int32,
    objectID: SM64ObjectID
) -> SM64OwnerThreadEffectIntent {
    let matches = tick.deliveries.flatMap(\.presented).filter {
        $0.kind == kind && $0.value == value && $0.objectID == objectID
    }
    guard let match = matches.first else {
        preconditionFailure("missing \(kind) presentation")
    }
    return match
}

@main
enum SM64ModernRacingPenguinEffectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64RacingPenguinObjectBridge()
        let id = try bridge.spawnPenguin(in: engineState, position: .zero)

        // Wait -> initial dialog -> accepted race start.
        _ = bridge.tick(state: engineState)
        _ = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                marioPositionY: 100,
                canActivateInitialText: true
            )]
        )
        let accepted = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(initialDialogResponse: 1)]
        )
        require(accepted.effects.first?.raceChildren != nil, "accepted race owns children")
        _ = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(raceBeginComplete: true)]
        )

        var fingerprint = fnvOffset
        var routedDeliveries = 0
        func absorb(_ tick: SM64RacingPenguinSchedulerTickResult) {
            for delivery in tick.deliveries where
                !delivery.delivered.isEmpty || !delivery.presented.isEmpty ||
                !delivery.spawned.isEmpty || !delivery.deleted.isEmpty || !delivery.rejected.isEmpty
            {
                fingerprint = hashDelivery(fingerprint, delivery)
                routedDeliveries += 1
            }
        }

        // Race movement emits the rough-slide sound and a grounded animation
        // completion owns a smoke child whose deletion is delivered in the
        // same owner-thread transaction.
        _ = engineState.objects.mutate(id) { record in
            record.moveFlags = SM64RacingPenguinBehavior.moveLanded |
                SM64RacingPenguinBehavior.moveOnGround
        }
        let smokeTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                marioPositionY: -200,
                pathWaypointFlags: 0x20,
                pathTargetYaw: 6_000,
                animationAtEnd: true,
                marioInAirAction: true
            )]
        )
        absorb(smokeTick)
        guard let smokeEffect = smokeTick.effects.first,
              let smokeID = smokeEffect.spawnedChildren.first else {
            preconditionFailure("smoke effect missing")
        }
        _ = presented(smokeTick, kind: .sound, value: 1, objectID: id)
        require(smokeEffect.output.spawnSmoke, "race animation owns smoke intent")
        require(smokeTick.scheduler.unloaded.contains(smokeID), "smoke retires at frame end")
        require(smokeTick.deliveries.allSatisfy(\.rejected.isEmpty), "smoke route has no rejects")

        // Finish-line child ownership marks a real win before the parent enters
        // the finish action. Six timer frames then reproduce the pounding and
        // camera-shake branch from the original behavior.
        let finishTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                pathStatus: SM64RacingPenguinBehavior.pathReachedEnd,
                finishLineDistanceToMario: 500,
                finishLineMarioDeltaZ: -1
            )]
        )
        absorb(finishTick)
        require(finishTick.effects.first?.output.reachedBottom == true, "finish action reached bottom")

        _ = engineState.objects.mutate(id) { record in
            record.moveFlags |= SM64RacingPenguinBehavior.moveHitWall
        }
        var poundingTick: SM64RacingPenguinSchedulerTickResult?
        for _ in 0..<7 {
            let tick = bridge.tick(
                state: engineState,
                environments: [id: SM64RacingPenguinEnvironment()]
            )
            absorb(tick)
            if tick.effects.first?.output.playPoundingSound == true {
                poundingTick = tick
            }
        }
        guard let poundingTick else { preconditionFailure("pounding effect missing") }
        _ = presented(poundingTick, kind: .sound, value: 3, objectID: id)
        _ = presented(poundingTick, kind: .cameraShake, value: 1, objectID: id)
        require(poundingTick.deliveries.allSatisfy(\.rejected.isEmpty), "pounding route has no rejects")

        // Finish animation rotates to the canonical facing, then presents the
        // win dialog. Completing it emits a dialog presentation followed by a
        // star child and progression presentation on the next tick.
        var textboxTick: SM64RacingPenguinSchedulerTickResult?
        for _ in 0..<80 {
            let tick = bridge.tick(
                state: engineState,
                environments: [id: SM64RacingPenguinEnvironment(
                    finalAnimationAtEnd: true,
                    canActivateFinalText: true
                )]
            )
            absorb(tick)
            if tick.effects.first?.output.finalTextbox == SM64RacingPenguinBehavior.dialogWin {
                textboxTick = tick
                break
            }
        }
        guard textboxTick != nil else { preconditionFailure("final textbox missing") }

        let dialogTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                finalDialogResult: SM64RacingPenguinBehavior.dialogWin
            )]
        )
        absorb(dialogTick)
        _ = presented(
            dialogTick,
            kind: .dialog,
            value: SM64RacingPenguinBehavior.dialogWin,
            objectID: id
        )
        require(dialogTick.effects.first?.output.finalDialogCompleted == true, "dialog completion intent")

        let starTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment()]
        )
        absorb(starTick)
        guard let starEffect = starTick.effects.first,
              let starID = starEffect.spawnedChildren.first else {
            preconditionFailure("star effect missing")
        }
        _ = presented(starTick, kind: .star, value: 0, objectID: id)
        require(starEffect.output.spawnStar, "win owns star intent")
        guard let starRecord = engineState.objects.record(for: starID) else {
            preconditionFailure("star child record missing")
        }
        require(
            starRecord.model == SM64RacingPenguinObjectBridge.starModel &&
                starRecord.parent == id &&
                starRecord.position == SM64ObjectVector3(x: 0, y: 200, z: 0) &&
                starRecord.homePosition == SM64RacingPenguinObjectBridge.starHomePosition,
            "star child model, source position, home target, and parent"
        )
        require(starTick.deliveries.allSatisfy(\.rejected.isEmpty), "star route has no rejects")

        print(String(format: "racingPenguinEffectBridgeFingerprint=0x%016llx", fingerprint))
        print("racingPenguinEffectBridgeRoutedDeliveries=\(routedDeliveries)")
        print("SM64 Modern racing penguin effect bridge smoke passed")
    }
}
