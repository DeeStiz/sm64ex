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

private func hashKernel(_ initial: UInt64, _ result: SM64AmpTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.kind.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.scale.bitPattern))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.facePitch)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: state.ampYPhase)))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.homingLockedOn ? 1 : 0)
    hash = hashU64(hash, state.invisible ? 1 : 0)
    return hashU64(hash, state.tangible ? 1 : 0)
}

private func hashBridgeTick(
    _ initial: UInt64,
    _ tick: SM64AmpSchedulerTickResult,
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
        hash = hashU64(hash, effect.tangible ? 1 : 0)
        hash = hashU64(hash, effect.invisible ? 1 : 0)
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
        hash = hashU64(hash, UInt64(UInt32(bitPattern: record.faceAngles.yaw)))
        hash = hashU64(hash, UInt64(UInt32(bitPattern: record.faceAngles.pitch)))
        hash = hashU64(hash, UInt64(record.hitboxRadius.bitPattern))
        hash = hashU64(hash, UInt64(record.hitboxDownOffset.bitPattern))
        hash = hashU64(hash, UInt64(record.graphFlags))
        hash = hashU64(hash, UInt64(record.interactionType))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernAmpObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var appearing = SM64AmpState(kind: .homing, homeX: 10, homeY: 20, homeZ: 30)
        let reveal = SM64AmpKernel.tick(
            SM64AmpTickInput(distanceToMario: 799, cameraTargetYaw: 0x2000),
            state: &appearing
        )
        require(reveal.state.action == .appear && !reveal.state.invisible, "homing reveal")
        require(reveal.effects.contains(.reveal) && reveal.state.timer == 1, "homing reveal effect")
        fingerprint = hashKernel(fingerprint, reveal)

        appearing.timer = 91
        let chase = SM64AmpKernel.tick(
            SM64AmpTickInput(distanceToMario: 500, angleToMario: 0x2000, marioHeadY: 100),
            state: &appearing
        )
        require(chase.state.action == .active && chase.state.scale == 1, "homing chase admission")
        require(chase.effects.contains(.chase), "homing chase effect")
        fingerprint = hashKernel(fingerprint, chase)

        let locked = SM64AmpKernel.tick(
            SM64AmpTickInput(distanceToMario: 500, angleToMario: 0, marioHeadY: 100),
            state: &appearing
        )
        require(locked.state.homingLockedOn && locked.state.forwardVelocity == 15, "homing lock")
        require(locked.effects.contains(.setHitbox) && locked.effects.contains(.buzz), "homing effects")
        fingerprint = hashKernel(fingerprint, locked)

        let giveUp = SM64AmpKernel.tick(
            SM64AmpTickInput(homeRadiusExceeded: true),
            state: &appearing
        )
        require(giveUp.state.action == .giveUp && giveUp.effects.contains(.giveUp), "homing give up")
        fingerprint = hashKernel(fingerprint, giveUp)

        appearing.timer = 151
        let reset = SM64AmpKernel.tick(SM64AmpTickInput(), state: &appearing)
        require(reset.state.action == .inactive && reset.state.invisible, "homing reset")
        require(reset.state.positionX == 10 && reset.state.positionY == 20 && reset.state.positionZ == 30, "home position")
        fingerprint = hashKernel(fingerprint, reset)

        var circling = SM64AmpState(
            kind: .circling,
            homeX: 100,
            homeY: 200,
            homeZ: 300,
            rotationRadius: 300,
            initialMoveYaw: 0,
            initialPhase: 1
        )
        let circle = SM64AmpKernel.tick(SM64AmpTickInput(), state: &circling)
        require(circle.state.positionX == 100 && circle.state.positionZ > 590, "circling radius")
        require(circle.state.moveYaw == 0x400 && circle.effects.contains(.buzz), "circling advance")
        fingerprint = hashKernel(fingerprint, circle)

        var fixed = SM64AmpState(kind: .fixed, homeX: 0, homeY: 100, homeZ: 0, initialPhase: 2)
        let fixedTick = SM64AmpKernel.tick(
            SM64AmpTickInput(angleToMario: 0x4000, verticalAngleToMario: 0x2000),
            state: &fixed
        )
        require(fixedTick.state.faceYaw == 0x1000 && fixedTick.state.facePitch == 0x1000, "fixed facing")
        require(!fixedTick.effects.contains(.buzz), "fixed amp has no buzz")
        fingerprint = hashKernel(fingerprint, fixedTick)

        circling.action = .attackCooldown
        circling.timer = 91
        let cooldown = SM64AmpKernel.tick(SM64AmpTickInput(), state: &circling)
        require(cooldown.state.action == .active && cooldown.state.tangible, "amp cooldown release")
        fingerprint = hashKernel(fingerprint, cooldown)

        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64AmpObjectBridge()
        let homing = try bridge.spawnAmp(
            in: engineState,
            kind: .homing,
            homeX: 10,
            homeY: 20,
            homeZ: 30
        )
        let fixedID = try bridge.spawnAmp(
            in: engineState,
            kind: .fixed,
            homeX: 100,
            homeY: 200,
            homeZ: 300,
            initialPhase: 1
        )
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(homing.traceSubject == 1 && fixedID.traceSubject == 2 && mario.traceSubject == 3, "stable Amp slots")

        let bridgeReveal = bridge.tick(
            state: engineState,
            inputs: [
                homing: SM64AmpTickInput(distanceToMario: 500, cameraTargetYaw: 0x1000),
                fixedID: SM64AmpTickInput(angleToMario: 0x2000, verticalAngleToMario: 0x1000)
            ]
        )
        require(bridgeReveal.effects.count == 2, "Amp effect count")
        guard let revealHomingRecord = engineState.objects.record(for: homing),
              let revealFixedRecord = engineState.objects.record(for: fixedID) else {
            preconditionFailure("Amp bridge reveal records missing")
        }
        fingerprint = hashBridgeTick(
            fingerprint,
            bridgeReveal,
            records: [revealHomingRecord, revealFixedRecord]
        )

        for _ in 0..<91 {
            _ = bridge.tick(
                state: engineState,
                inputs: [
                    homing: SM64AmpTickInput(distanceToMario: 500),
                    fixedID: SM64AmpTickInput()
                ]
            )
        }

        let bridgeAttack = bridge.tick(
            state: engineState,
            inputs: [
                homing: SM64AmpTickInput(distanceToMario: 500, interacted: true),
                fixedID: SM64AmpTickInput(interacted: true)
            ]
        )
        require(bridgeAttack.effects.allSatisfy { $0.action == .attackCooldown }, "Amp interaction cooldown")
        guard let attackHomingRecord = engineState.objects.record(for: homing),
              let attackFixedRecord = engineState.objects.record(for: fixedID) else {
            preconditionFailure("Amp bridge attack records missing")
        }
        fingerprint = hashBridgeTick(
            fingerprint,
            bridgeAttack,
            records: [attackHomingRecord, attackFixedRecord]
        )

        print(String(format: "ampObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Amp object bridge smoke passed")
    }
}
