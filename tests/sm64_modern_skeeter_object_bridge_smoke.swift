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

private func hashKernel(_ initial: UInt64, _ result: SM64SkeeterTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetAngle)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.smoothTurnYaw)))
    hash = hashU64(hash, UInt64(state.turningAwayFromWall))
    hash = hashU64(hash, UInt64(state.targetForwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.waitTime))
    hash = hashU64(hash, UInt64(state.moveFlags))
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBridge(
    _ initial: UInt64,
    _ tick: SM64SkeeterSchedulerTickResult,
    record: SM64ObjectRecord?
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
        hash = hashU64(hash, effect.isWave ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedWaves.count))
        for id in effect.spawnedWaves { hash = hashU64(hash, UInt64(id.traceSubject)) }
        hash = hashU64(hash, UInt64(effect.scale.bitPattern))
        hash = hashU64(hash, UInt64(effect.animationState))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    guard let record else { return hashU64(hash, 0) }
    hash = hashU64(hash, 1)
    hash = hashU64(hash, UInt64(record.action))
    hash = hashU64(hash, UInt64(record.previousAction))
    hash = hashU64(hash, UInt64(record.timer))
    hash = hashU64(hash, UInt64(record.position.x.bitPattern))
    hash = hashU64(hash, UInt64(record.position.y.bitPattern))
    hash = hashU64(hash, UInt64(record.position.z.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: record.moveAngles.yaw)))
    hash = hashU64(hash, UInt64(record.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(record.hitboxDownOffset.bitPattern))
    hash = hashU64(hash, UInt64(record.hitboxRadius.bitPattern))
    hash = hashU64(hash, UInt64(record.hitboxHeight.bitPattern))
    hash = hashU64(hash, UInt64(record.hurtboxRadius.bitPattern))
    hash = hashU64(hash, UInt64(record.hurtboxHeight.bitPattern))
    return hashU64(hash, UInt64(record.interactionType))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSkeeterObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var skeeter = SM64SkeeterState(homeX: 10, homeY: 100, homeZ: -20)

        skeeter.timer = 1
        let walkStart = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(moveFlags: 0x2, animationNearEnd: true),
            state: &skeeter
        )
        require(walkStart.state.action == .walk, "ground idle to walk")
        fingerprint = hashKernel(fingerprint, walkStart)

        let walk = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(distanceToMario: 100, angleToMario: 0x1000, moveFlags: 0x2),
            state: &skeeter
        )
        require(abs(walk.state.forwardVelocity - 0.4) < 0.0001, "skeeter walk approach")
        fingerprint = hashKernel(fingerprint, walk)

        let bounce = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(
                distanceToMario: 1_000,
                moveFlags: 0x2,
                resolvedTurnRemaining: 4,
                bounceOffWall: true,
                reflectedYaw: 0x2000
            ),
            state: &skeeter
        )
        require(bounce.effects.contains(.wallBounce), "skeeter wall bounce")
        fingerprint = hashKernel(fingerprint, bounce)

        let turning = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(moveFlags: 0x2, resolvedTurnRemaining: 2),
            state: &skeeter
        )
        require(turning.state.turningAwayFromWall == 2, "skeeter wall turn continuation")
        fingerprint = hashKernel(fingerprint, turning)

        skeeter.turningAwayFromWall = 0
        skeeter.waitTime = 0
        let idle = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(
                distanceToMario: 1_000,
                moveFlags: 0x2,
                animationNearEnd: true,
                randomWaitTime: 5
            ),
            state: &skeeter
        )
        require(idle.state.action == .idle && idle.state.waitTime == 5, "skeeter random idle")
        fingerprint = hashKernel(fingerprint, idle)

        skeeter.timer = 61
        skeeter.waitTime = 0
        let lunge = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(
                moveFlags: SM64SkeeterKernel.atWaterSurfaceFlag,
                animationNearEnd: true,
                smoothTurnComplete: true
            ),
            state: &skeeter
        )
        require(lunge.state.action == .lunge && lunge.state.forwardVelocity == 80, "skeeter water lunge")
        require(lunge.effects.contains(.spawnWaves), "skeeter wave spawn intent")
        fingerprint = hashKernel(fingerprint, lunge)

        skeeter.forwardVelocity = 0.4
        let lungeEnd = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(
                moveFlags: SM64SkeeterKernel.atWaterSurfaceFlag | SM64SkeeterKernel.hitWallFlag,
                animationAtEnd: true,
                reflectedYaw: 0x3000,
                randomTargetAngle: 0x1800,
                randomWaitTime: 7
            ),
            state: &skeeter
        )
        require(lungeEnd.state.action == .idle && lungeEnd.state.waitTime == 7, "skeeter lunge end")
        fingerprint = hashKernel(fingerprint, lungeEnd)

        let attacked = SM64SkeeterKernel.tick(
            SM64SkeeterTickInput(attacked: true),
            state: &skeeter
        )
        require(attacked.state.markedForDeletion && attacked.effects.contains(.coin), "skeeter attack death")
        fingerprint = hashKernel(fingerprint, attacked)

        let engineState = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64SkeeterObjectBridge()
        let skeeterID = try bridge.spawnSkeeter(in: engineState, homeX: 10, homeY: 100, homeZ: -20)
        let playerID = try engineState.spawnObject(in: .player, isMario: true)
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [
                skeeterID: SM64SkeeterTickInput(
                    moveFlags: SM64SkeeterKernel.atWaterSurfaceFlag,
                    smoothTurnComplete: false
                )
            ]
        )
        require(bridgeTick.effects.count == 5, "skeeter parent plus four waves")
        require(bridgeTick.effects.first?.spawnedWaves.count == 4, "skeeter wave children")
        require(bridgeTick.scheduler.updated.first?.traceSubject == playerID.traceSubject, "player update order")
        guard let record = engineState.objects.record(for: skeeterID) else {
            preconditionFailure("skeeter record missing")
        }
        require(record.hitboxRadius == 180 && record.numLootCoins == 3, "skeeter hitbox bridge")
        fingerprint = hashBridge(fingerprint, bridgeTick, record: record)

        print(String(format: "skeeterObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Skeeter object bridge smoke passed")
    }
}
