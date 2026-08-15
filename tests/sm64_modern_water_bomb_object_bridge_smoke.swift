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

private func hashSpawner(
    _ initial: UInt64,
    _ result: SM64WaterBombSpawnerTickResult
) -> UInt64 {
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    let state = result.state
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(state.radiusParameter))
    hash = hashU64(hash, state.bombActive ? 1 : 0)
    hash = hashU64(hash, UInt64(state.timeToSpawn))
    return hashU64(hash, UInt64(state.timer))
}

private func hashBomb(
    _ initial: UInt64,
    _ result: SM64WaterBombTickResult
) -> UInt64 {
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    let state = result.state
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(state.floorHeight.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.angleToMario)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(state.verticalStretch.bitPattern))
    hash = hashU64(hash, UInt64(state.stretchSpeed.bitPattern))
    hash = hashU64(hash, state.onGround ? 1 : 0)
    hash = hashU64(hash, UInt64(state.numBounces.bitPattern))
    hash = hashU64(hash, UInt64(state.scaleX.bitPattern))
    hash = hashU64(hash, UInt64(state.scaleY.bitPattern))
    hash = hashU64(hash, UInt64(state.scaleZ.bitPattern))
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashShadow(
    _ initial: UInt64,
    _ result: SM64WaterBombShadowTickResult
) -> UInt64 {
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    let state = result.state
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(state.scaleX.bitPattern))
    hash = hashU64(hash, UInt64(state.scaleY.bitPattern))
    hash = hashU64(hash, UInt64(state.scaleZ.bitPattern))
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBridge(
    _ initial: UInt64,
    _ tick: SM64WaterBombSchedulerTickResult,
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
        hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 0xff))
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
        hash = hashU64(hash, UInt64(record.scale.x.bitPattern))
        hash = hashU64(hash, UInt64(record.scale.y.bitPattern))
        hash = hashU64(hash, UInt64(record.scale.z.bitPattern))
        hash = hashU64(hash, UInt64(record.interactionType))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernWaterBombObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var spawner = SM64WaterBombSpawnerState(
            positionX: 10,
            positionY: 100,
            positionZ: -20,
            radiusParameter: 1
        )
        let spawn = SM64WaterBombKernel.tickSpawner(
            SM64WaterBombSpawnerTickInput(
                marioX: 100,
                marioY: 80,
                marioZ: 40,
                marioForwardVelocity: 5,
                marioMoveYaw: 0x1000,
                randomDelay: 7
            ),
            state: &spawner
        )
        require(spawn.effects == [.animate, .spawnBomb], "spawner spawn gate")
        require(spawn.state.bombActive && spawn.state.timeToSpawn == 7, "spawner active state")
        fingerprint = hashSpawner(fingerprint, spawn)

        let waiting = SM64WaterBombKernel.tickSpawner(
            SM64WaterBombSpawnerTickInput(
                marioX: 100,
                marioY: 80,
                marioZ: 40,
                randomDelay: 7
            ),
            state: &spawner
        )
        require(waiting.effects == [.animate] && waiting.state.timer == 2, "spawner wait")
        fingerprint = hashSpawner(fingerprint, waiting)

        var bomb = SM64WaterBombState(
            action: .initialize,
            positionX: 100,
            positionY: 2_100,
            positionZ: 40,
            floorHeight: 0,
            moveYaw: 0x1000
        )
        let initialize = SM64WaterBombKernel.tickBomb(
            SM64WaterBombTickInput(angleToMario: 0x2000),
            state: &bomb
        )
        require(initialize.state.action == .drop && initialize.state.velocityY == -40, "bomb initialization")
        require(initialize.effects == [.animate, .landingSound], "bomb initialization effects")
        fingerprint = hashBomb(fingerprint, initialize)

        let airborne = SM64WaterBombKernel.tickBomb(
            SM64WaterBombTickInput(angleToMario: 0x2000),
            state: &bomb
        )
        require(airborne.state.positionY == 2_056 && airborne.state.velocityY == -44, "bomb gravity")
        fingerprint = hashBomb(fingerprint, airborne)

        let bounce = SM64WaterBombKernel.tickBomb(
            SM64WaterBombTickInput(moveFlags: SM64WaterBombKernel.maskOnGround, angleToMario: 0x3000),
            state: &bomb
        )
        require(bounce.state.onGround && bounce.state.numBounces == 1, "bomb bounce admission")
        require(bounce.effects.contains(.bounceSound) && bounce.effects.contains(.screenShake), "bomb bounce effects")
        fingerprint = hashBomb(fingerprint, bounce)

        let interacted = SM64WaterBombKernel.tickBomb(
            SM64WaterBombTickInput(interacted: true, angleToMario: 0x3000),
            state: &bomb
        )
        require(interacted.state.action == .explode, "bomb interaction explode")
        require(interacted.effects.contains(.diveSound), "bomb interaction sound")
        fingerprint = hashBomb(fingerprint, interacted)

        let exploded = SM64WaterBombKernel.tickBomb(
            SM64WaterBombTickInput(angleToMario: 0x3000),
            state: &bomb
        )
        require(exploded.state.markedForDeletion && exploded.effects.contains(.clearSpawner), "bomb explode cleanup")
        fingerprint = hashBomb(fingerprint, exploded)

        var cannon = SM64WaterBombState(
            action: .shotFromCannon,
            positionX: 2,
            positionY: 3,
            positionZ: 4,
            scale: 1.7
        )
        cannon.timer = 1
        let cannonTick = SM64WaterBombKernel.tickBomb(
            SM64WaterBombTickInput(transformDeltaX: 1, transformDeltaY: -2, transformDeltaZ: 3),
            state: &cannon
        )
        require(cannonTick.effects.contains(.cannonParticles) && cannonTick.effects.contains(.spawnParticles), "cannon particles")
        require(cannonTick.state.scaleY < 1.7 && cannonTick.state.positionX == 3, "cannon transform")
        fingerprint = hashBomb(fingerprint, cannonTick)

        var shadow = SM64WaterBombShadowState()
        var shadowParent = exploded.state
        shadowParent.action = .drop
        shadowParent.markedForDeletion = false
        let shadowFollow = SM64WaterBombKernel.tickShadow(parent: shadowParent, state: &shadow)
        require(shadowFollow.state.positionY == shadowParent.floorHeight + min(shadowParent.positionY - shadowParent.floorHeight, 500), "shadow follow")
        fingerprint = hashShadow(fingerprint, shadowFollow)
        let shadowHide = SM64WaterBombKernel.tickShadow(parent: exploded.state, state: &shadow)
        require(shadowHide.state.markedForDeletion && shadowHide.effects.contains(.shadowHidden), "shadow deletion")
        fingerprint = hashShadow(fingerprint, shadowHide)

        let engineState = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64WaterBombObjectBridge()
        let spawnerID = try bridge.spawnSpawner(
            in: engineState,
            positionX: 10,
            positionY: 100,
            positionZ: -20,
            radiusParameter: 1
        )
        let marioID = try engineState.spawnObject(in: .player, isMario: true)
        let bridgeTick = bridge.tick(
            state: engineState,
            spawnerInputs: [spawnerID: SM64WaterBombSpawnerTickInput(
                marioX: 100,
                marioY: 80,
                marioZ: 40,
                marioForwardVelocity: 5,
                marioMoveYaw: 0x1000
            )]
        )
        require(bridgeTick.effects.count == 3, "bridge spawner/bomb/shadow callbacks")
        require(bridgeTick.effects[0].spawnedChildren.count == 2, "bridge child allocation")
        require(bridgeTick.scheduler.updated.map(\.traceSubject) == [marioID.traceSubject, spawnerID.traceSubject, 3, 4], "bridge live ordering")
        guard let bombID = bridgeTick.effects[0].spawnedChildren.first,
              let shadowID = bridgeTick.effects[0].spawnedChildren.last else {
            preconditionFailure("bridge children missing")
        }
        require(bridge.bombState(for: bombID)?.action == .drop, "bridge bomb action")
        fingerprint = hashBridge(
            fingerprint,
            bridgeTick,
            records: [
                engineState.objects.record(for: spawnerID),
                engineState.objects.record(for: bombID),
                engineState.objects.record(for: shadowID)
            ]
        )

        let impact = bridge.tick(
            state: engineState,
            bombInputs: [bombID: SM64WaterBombTickInput(interacted: true)]
        )
        require(impact.effects.contains { $0.kind == .shadow && $0.markedForDeletion }, "bridge shadow impact deletion")
        require(
            bridge.deliveryLog.contains { $0.deleted == [shadowID] },
            "bridge shadow deletion routed through owner thread"
        )
        require(impact.scheduler.unloaded.map(\.traceSubject) == [shadowID.traceSubject], "bridge shadow unload")
        fingerprint = hashBridge(
            fingerprint,
            impact,
            records: [
                engineState.objects.record(for: spawnerID),
                engineState.objects.record(for: bombID),
                engineState.objects.record(for: shadowID)
            ]
        )

        let cleanup = bridge.tick(
            state: engineState,
            bombInputs: [bombID: SM64WaterBombTickInput()]
        )
        require(cleanup.scheduler.unloaded.map(\.traceSubject) == [bombID.traceSubject], "bridge bomb unload")
        require(
            bridge.deliveryLog.contains { $0.deleted == [bombID] },
            "bridge bomb deletion routed through owner thread"
        )
        require(bridge.spawnerState(for: spawnerID)?.bombActive == false, "bridge spawner clear")
        require(bridge.registeredIDs == [spawnerID], "bridge child cleanup")
        fingerprint = hashBridge(
            fingerprint,
            cleanup,
            records: [
                engineState.objects.record(for: spawnerID),
                engineState.objects.record(for: bombID),
                engineState.objects.record(for: shadowID)
            ]
        )
        fingerprint = hashU64(fingerprint, 1)
        fingerprint = hashU64(fingerprint, 1)
        fingerprint = hashU64(fingerprint, 1)
        fingerprint = hashU64(fingerprint, 1)

        print(String(format: "waterBombObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern water-bomb object bridge smoke passed")
    }
}
