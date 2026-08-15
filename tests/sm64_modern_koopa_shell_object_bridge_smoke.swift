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

private func hashState(_ initial: UInt64, _ result: SM64KoopaShellTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.kind.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.heldState.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(state.floorHeight.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(state.moveFlags))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.floorType)))
    hash = hashU64(hash, state.hidden ? 1 : 0)
    hash = hashU64(hash, state.markedForDeletion ? 1 : 0)
    return hashU64(hash, UInt64(state.timer))
}

private func hashBridge(
    _ initial: UInt64,
    _ tick: SM64KoopaShellSchedulerTickResult,
    records: [SM64ObjectRecord?]
) -> UInt64 {
    let scheduler = tick.scheduler
    var hash = hashU64(initial, scheduler.frame)
    for count in scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(scheduler.objectCounter))
    hash = hashU64(hash, UInt64(scheduler.updated.count))
    for id in scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(scheduler.unloaded.count))
    for id in scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for id in effect.spawnedChildren { hash = hashU64(hash, UInt64(id.traceSubject)) }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    for record in records {
        guard let record else {
            hash = hashU64(hash, 0)
            continue
        }
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(record.action))
        hash = hashU64(hash, UInt64(record.previousAction))
        hash = hashU64(hash, UInt64(record.timer))
        hash = hashU64(hash, UInt64(record.position.x.bitPattern))
        hash = hashU64(hash, UInt64(record.position.y.bitPattern))
        hash = hashU64(hash, UInt64(record.position.z.bitPattern))
        hash = hashU64(hash, UInt64(record.heldState))
        hash = hashU64(hash, UInt64(record.interactionType))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernKoopaShellObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var shell = SM64KoopaShellState(
            positionX: 10,
            positionY: 100,
            positionZ: -20,
            floorHeight: 0,
            moveYaw: 0x1000,
            forwardVelocity: 8
        )
        let free = SM64KoopaShellKernel.tick(
            SM64KoopaShellTickInput(
                moveFlags: SM64KoopaShellKernel.onGroundMask | SM64KoopaShellKernel.hitWallFlag,
                wallYaw: 0x2000,
                floorHeight: 0,
                interacted: true
            ),
            state: &shell
        )
        require(free.state.action == .ridden && free.state.faceYaw == 0x2000, "shell interaction action")
        require(free.effects.contains(.wallBounce) && free.effects.contains(.spawnSparkle), "shell free effects")
        fingerprint = hashState(fingerprint, free)

        let waterRide = SM64KoopaShellKernel.tick(
            SM64KoopaShellTickInput(
                nearWater: true,
                marioForwardVelocity: 15,
                marioX: 30,
                marioY: 50,
                marioZ: -4,
                marioMoveYaw: 0x3000
            ),
            state: &shell
        )
        require(waterRide.state.positionX == 30 && waterRide.effects.contains(.spawnWaveTrail), "shell water ride")
        require(waterRide.effects.contains(.spawnWaterDrop), "shell water drop")
        fingerprint = hashState(fingerprint, waterRide)

        let stop = SM64KoopaShellKernel.tick(
            SM64KoopaShellTickInput(
                stopRiding: true,
                marioX: 30,
                marioY: 0,
                marioZ: -4
            ),
            state: &shell
        )
        require(stop.state.action == .free && stop.state.markedForDeletion, "shell stop riding")
        require(stop.effects.contains(.spawnMist) && stop.effects.contains(.markForDeletion), "shell stop effects")
        fingerprint = hashState(fingerprint, stop)

        var underwater = SM64KoopaShellState(kind: .underwater)
        let held = SM64KoopaShellKernel.tick(
            SM64KoopaShellTickInput(heldState: .held),
            state: &underwater
        )
        require(held.state.hidden && held.effects.contains(.hide), "underwater held state")
        fingerprint = hashState(fingerprint, held)
        let thrown = SM64KoopaShellKernel.tick(
            SM64KoopaShellTickInput(heldState: .thrown),
            state: &underwater
        )
        require(thrown.state.markedForDeletion && thrown.effects.contains(.spawnMist), "underwater thrown state")
        fingerprint = hashState(fingerprint, thrown)

        let engineState = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64KoopaShellObjectBridge()
        let shellID = try bridge.spawnShell(
            in: engineState,
            positionX: 10,
            positionY: 100,
            positionZ: -20,
            moveYaw: 0x1000,
            forwardVelocity: 8
        )
        let underwaterID = try bridge.spawnUnderwaterShell(in: engineState, positionX: -30, positionY: 20, positionZ: 4)
        let marioID = try engineState.spawnObject(in: .player, isMario: true)
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [shellID: SM64KoopaShellTickInput(moveFlags: SM64KoopaShellKernel.onGroundMask, interacted: true)],
            underwaterInputs: [underwaterID: SM64KoopaShellTickInput(heldState: .held)]
        )
        require(bridgeTick.effects.count == 2, "shell bridge callbacks")
        require(
            bridgeTick.effects[0].kind == SM64KoopaShellKind.underwater
                && bridgeTick.effects[1].kind == SM64KoopaShellKind.shell,
            "level/general callback ordering"
        )
        require(bridgeTick.effects[1].spawnedChildren.count == 1, "shell sparkle allocation")
        require(bridgeTick.scheduler.updated.first?.traceSubject == marioID.traceSubject, "shell player ordering")
        guard let sparkleID = bridgeTick.effects[1].spawnedChildren.first else {
            preconditionFailure("shell sparkle missing")
        }
        fingerprint = hashBridge(
            fingerprint,
            bridgeTick,
            records: [
                engineState.objects.record(for: shellID),
                engineState.objects.record(for: underwaterID),
                engineState.objects.record(for: sparkleID)
            ]
        )

        let shellStop = bridge.tick(
            state: engineState,
            inputs: [shellID: SM64KoopaShellTickInput(stopRiding: true, marioY: 0)]
        )
        require(shellStop.effects.contains { $0.objectID == shellID && $0.markedForDeletion }, "shell bridge deletion")
        require(shellStop.scheduler.unloaded.contains(shellID), "shell end-frame unload")
        fingerprint = hashBridge(
            fingerprint,
            shellStop,
            records: [
                engineState.objects.record(for: shellID),
                engineState.objects.record(for: underwaterID),
                engineState.objects.record(for: sparkleID)
            ]
        )

        print(String(format: "koopaShellObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Koopa shell object bridge smoke passed")
    }
}
