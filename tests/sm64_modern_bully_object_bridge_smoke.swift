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

private func hashKernel(_ initial: UInt64, _ result: SM64BullyTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.size.rawValue))
    hash = hashU64(hash, UInt64(state.subtype.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.knockbackCounter)))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.tangible ? 1 : 0)
    hash = hashU64(hash, state.invisible ? 1 : 0)
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBridgeTick(
    _ initial: UInt64,
    _ tick: SM64BullySchedulerTickResult,
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
        hash = hashU64(hash, UInt64(effect.size.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
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
enum SM64ModernBullyObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var small = SM64BullyState(size: .small, homeX: 0, homeY: 100, homeZ: 0, moveYaw: 0)
        let patrol = SM64BullyKernel.tick(
            SM64BullyTickInput(angleToMario: 0x2000, distanceFromHome: 0),
            state: &small
        )
        require(patrol.state.action == .chase && patrol.state.forwardVelocity == 5, "patrol chase admission")
        fingerprint = hashKernel(fingerprint, patrol)

        small.timer = 0
        let chaseStart = SM64BullyKernel.tick(
            SM64BullyTickInput(angleToMario: 0x2000),
            state: &small
        )
        require(chaseStart.state.forwardVelocity == 3 && chaseStart.state.moveYaw == 0x1000, "chase startup")
        fingerprint = hashKernel(fingerprint, chaseStart)

        small.timer = 10
        let chaseFast = SM64BullyKernel.tick(SM64BullyTickInput(), state: &small)
        require(chaseFast.state.forwardVelocity == 20, "small chase speed")
        fingerprint = hashKernel(fingerprint, chaseFast)

        let leave = SM64BullyKernel.tick(
            SM64BullyTickInput(homeRadiusExceeded: true),
            state: &small
        )
        require(leave.state.action == .patrol && leave.effects.contains(.patrol), "bully return home")
        fingerprint = hashKernel(fingerprint, leave)

        let hit = SM64BullyKernel.tick(
            SM64BullyTickInput(interacted: true, marioCollisionAngle: 0x4000),
            state: &small
        )
        require(hit.state.action == .knockback && hit.state.knockbackCounter == 1, "bully knockback")
        require(hit.effects.contains(.attackResponse), "bully attack effect")
        fingerprint = hashKernel(fingerprint, hit)

        small.action = .knockback
        small.knockbackCounter = 17
        small.forwardVelocity = 0
        small.timer = 0
        let knockbackEnd = SM64BullyKernel.tick(SM64BullyTickInput(), state: &small)
        require(knockbackEnd.state.action == .chase && knockbackEnd.state.knockbackCounter == 0, "knockback end")
        fingerprint = hashKernel(fingerprint, knockbackEnd)

        small.action = .backUp
        small.timer = 0
        let backup = SM64BullyKernel.tick(SM64BullyTickInput(), state: &small)
        require(backup.state.action == .backUp && backup.state.forwardVelocity == 5, "backup start")
        fingerprint = hashKernel(fingerprint, backup)

        small.timer = 15
        let backupEnd = SM64BullyKernel.tick(SM64BullyTickInput(), state: &small)
        require(backupEnd.state.action == .patrol, "backup end")
        fingerprint = hashKernel(fingerprint, backupEnd)

        small.action = .lavaDeath
        small.timer = 0
        let smallDeath = SM64BullyKernel.tick(SM64BullyTickInput(), state: &small)
        require(smallDeath.effects.contains(.coin) && smallDeath.state.markedForDeletion, "small lava death")
        fingerprint = hashKernel(fingerprint, smallDeath)

        var big = SM64BullyState(size: .big, subtype: .chill, homeY: 1_100, action: .lavaDeath)
        let bigDeath = SM64BullyKernel.tick(SM64BullyTickInput(), state: &big)
        require(bigDeath.effects.contains(.star) && bigDeath.effects.contains(.mist), "big lava death")
        fingerprint = hashKernel(fingerprint, bigDeath)

        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BullyObjectBridge()
        let smallID = try bridge.spawnBully(in: engineState, size: .small, homeY: 100)
        let bigID = try bridge.spawnBully(in: engineState, size: .big, homeY: 100)
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(smallID.traceSubject == 1 && bigID.traceSubject == 2 && mario.traceSubject == 3, "stable Bully slots")

        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [
                smallID: SM64BullyTickInput(angleToMario: 0x1000, distanceFromHome: 0),
                bigID: SM64BullyTickInput(angleToMario: 0x2000, distanceFromHome: 0)
            ]
        )
        require(bridgeTick.effects.count == 2, "Bully effect count")
        guard let smallRecord = engineState.objects.record(for: smallID) else {
            preconditionFailure("small Bully record missing")
        }
        require(smallRecord.hitboxRadius == 73 && smallRecord.hitboxHeight == 123, "small hitbox bridge")
        fingerprint = hashBridgeTick(fingerprint, bridgeTick, record: smallRecord)

        let bridgeDeath = bridge.tick(
            state: engineState,
            inputs: [
                smallID: SM64BullyTickInput(floorCollisionFlags: 1),
                bigID: SM64BullyTickInput(floorCollisionFlags: 1)
            ]
        )
        _ = bridgeDeath

        print(String(format: "bullyObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bully object bridge smoke passed")
    }
}
