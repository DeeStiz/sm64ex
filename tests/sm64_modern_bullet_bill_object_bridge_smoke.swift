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

private func hashKernel(_ initial: UInt64, _ result: SM64BulletBillTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.initialMoveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.facePitch)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceRoll)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, state.intangible ? 1 : 0)
}

private func hashBridgeTick(
    _ initial: UInt64,
    _ tick: SM64BulletBillSchedulerTickResult,
    bulletRecord: SM64ObjectRecord?,
    smokeRecord: SM64ObjectRecord?
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
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedSmoke?.traceSubject ?? 0))
    }
    if let bulletRecord {
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(bulletRecord.action))
        hash = hashU64(hash, UInt64(bulletRecord.previousAction))
        hash = hashU64(hash, UInt64(bulletRecord.timer))
        hash = hashU64(hash, UInt64(bulletRecord.forwardVelocity.bitPattern))
        hash = hashU64(hash, UInt64(bulletRecord.moveAngles.yaw))
        hash = hashU64(hash, UInt64(bulletRecord.faceAngles.pitch))
        hash = hashU64(hash, UInt64(bulletRecord.faceAngles.roll))
        hash = hashU64(hash, UInt64(bulletRecord.position.y.bitPattern))
        hash = hashU64(hash, bulletRecord.intangibleTimer >= 0 ? 1 : 0)
    } else {
        hash = hashU64(hash, 0)
    }
    return hashU64(hash, smokeRecord == nil ? 0 : 1)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBulletBillObjectBridgeSmoke {
    static func main() throws {
        var kernelState = SM64BulletBillState(initialMoveYaw: 0x1000)
        let reset = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(homeY: 120),
            state: &kernelState
        )
        require(reset.state.action == .waiting, "reset enters waiting")
        require(reset.effects == [.animate, .resetToHome, .tangible], "reset effects")
        require(reset.state.positionY == 120, "home position reset")

        let launch = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0x1000),
            state: &kernelState
        )
        require(launch.state.action == .launching && launch.effects == [.animate, .launch], "launch gate")

        kernelState.timer = 39
        let early = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0x2000),
            state: &kernelState
        )
        require(early.state.forwardVelocity == 3, "early launch speed")

        kernelState.timer = 40
        let reverse = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0x2000),
            state: &kernelState
        )
        require(reverse.state.forwardVelocity == -3, "alternating launch speed")

        kernelState.timer = 50
        let smoke = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0x2000),
            state: &kernelState
        )
        require(smoke.effects.contains(.spawnSmoke) && smoke.effects.contains(.launchSound), "smoke launch effects")
        require(smoke.state.forwardVelocity == 30 && smoke.state.moveYaw == 0x1100, "launch yaw approach")

        kernelState.timer = 151
        let ended = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(
                distanceToMario: 1_000,
                angleToMario: 0x2000,
                moveFlags: SM64BulletBillState.hitWallFlag
            ),
            state: &kernelState
        )
        require(ended.state.action == .ended && ended.effects.contains(.spawnMist), "wall termination")

        var returningState = SM64BulletBillState()
        returningState.action = .returning
        let returning = SM64BulletBillKernel.tick(
            SM64BulletBillTickInput(),
            state: &returningState
        )
        require(returning.effects.contains(.intangible), "return intangible boundary")
        require(returning.state.forwardVelocity == -30 && returning.state.positionY == 20, "return motion")

        var fingerprint = fnvOffset
        fingerprint = hashKernel(fingerprint, reset)
        fingerprint = hashKernel(fingerprint, launch)
        fingerprint = hashKernel(fingerprint, early)
        fingerprint = hashKernel(fingerprint, reverse)
        fingerprint = hashKernel(fingerprint, smoke)
        fingerprint = hashKernel(fingerprint, ended)
        fingerprint = hashKernel(fingerprint, returning)

        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BulletBillObjectBridge()
        let bullet = try bridge.spawnBulletBill(in: engineState, initialMoveYaw: 0)
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(bullet.traceSubject == 1 && mario.traceSubject == 2, "stable Bullet Bill slots")

        let bridgeReset = bridge.tick(
            state: engineState,
            inputs: [bullet: SM64BulletBillTickInput(homeY: 80)]
        )
        require(bridgeReset.scheduler.updated.map(\.traceSubject) == [2, 1], "player/general object order")
        require(bridgeReset.effects[0].effects == [.animate, .resetToHome, .tangible], "bridge reset effects")
        guard let bridgeResetRecord = engineState.objects.record(for: bullet) else {
            preconditionFailure("bridge reset record missing")
        }

        let bridgeLaunch = bridge.tick(
            state: engineState,
            inputs: [bullet: SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0)]
        )
        require(bridgeLaunch.effects[0].action == .launching, "bridge launch action")
        guard let bridgeLaunchRecord = engineState.objects.record(for: bullet) else {
            preconditionFailure("bridge launch record missing")
        }

        // Reach the timer-50 smoke branch through the live owner-thread route.
        for _ in 0..<48 {
            _ = bridge.tick(
                state: engineState,
                inputs: [bullet: SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0)]
            )
        }
        let bridgeSmoke = bridge.tick(
            state: engineState,
            inputs: [bullet: SM64BulletBillTickInput(distanceToMario: 1_000, angleToMario: 0)]
        )
        guard let smokeID = bridgeSmoke.effects[0].spawnedSmoke else {
            preconditionFailure("bridge did not allocate smoke")
        }
        require(smokeID.traceSubject == 3, "smoke child slot")
        require(bridgeSmoke.scheduler.updated.map(\.traceSubject) == [2, 1, 3], "same-frame smoke callback")
        require(bridgeSmoke.scheduler.unloaded.map(\.traceSubject) == [3], "smoke end-of-frame unload")
        require(!engineState.objects.contains(smokeID), "smoke transient unloaded")
        guard let bridgeSmokeRecord = engineState.objects.record(for: bullet) else {
            preconditionFailure("bridge smoke record missing")
        }

        let bridgeEnd = bridge.tick(
            state: engineState,
            inputs: [bullet: SM64BulletBillTickInput(
                distanceToMario: 1_000,
                angleToMario: 0,
                moveFlags: SM64BulletBillState.hitWallFlag
            )]
        )
        require(bridgeEnd.effects[0].action == .ended, "bridge wall end")
        require(bridgeEnd.effects[0].effects.contains(.spawnMist), "bridge mist effect")
        guard let bridgeEndRecord = engineState.objects.record(for: bullet) else {
            preconditionFailure("bridge end record missing")
        }

        fingerprint = hashBridgeTick(fingerprint, bridgeReset, bulletRecord: bridgeResetRecord, smokeRecord: nil)
        fingerprint = hashBridgeTick(fingerprint, bridgeLaunch, bulletRecord: bridgeLaunchRecord, smokeRecord: nil)
        fingerprint = hashBridgeTick(fingerprint, bridgeSmoke, bulletRecord: bridgeSmokeRecord, smokeRecord: nil)
        fingerprint = hashBridgeTick(fingerprint, bridgeEnd, bulletRecord: bridgeEndRecord, smokeRecord: nil)

        print(String(format: "bulletBillObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bullet Bill object bridge smoke passed")
    }
}
