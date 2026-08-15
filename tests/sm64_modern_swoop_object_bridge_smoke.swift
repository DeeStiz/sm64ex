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

private func hashKernel(_ initial: UInt64, _ result: SM64SwoopTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.scale.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceRoll)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.facePitch)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetPitch)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.bonkCountdown)))
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBridgeTick(
    _ initial: UInt64,
    _ tick: SM64SwoopSchedulerTickResult,
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
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    guard let record else { return hashU64(hash, 0) }
    hash = hashU64(hash, 1)
    hash = hashU64(hash, UInt64(record.action))
    hash = hashU64(hash, UInt64(record.previousAction))
    hash = hashU64(hash, UInt64(record.timer))
    hash = hashU64(hash, UInt64(record.scale.x.bitPattern))
    hash = hashU64(hash, UInt64(record.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(record.velocity.y.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: record.moveAngles.yaw)))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: record.faceAngles.pitch)))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: record.faceAngles.roll)))
    hash = hashU64(hash, UInt64(record.hitboxRadius.bitPattern))
    hash = hashU64(hash, UInt64(record.numLootCoins))
    return hashU64(hash, record.activeFlags == 0 ? 0 : 1)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSwoopObjectBridgeSmoke {
    static func main() throws {
        var state = SM64SwoopState(positionY: 1_000, homeY: 900)
        state.scale = 0.95
        let enter = SM64SwoopKernel.tick(
            SM64SwoopTickInput(distanceToMario: 1_000),
            state: &state
        )
        require(enter.state.action == .move, "idle enters move")
        require(enter.effects == [.animate, .enterMove, .swoopSound], "enter move effects")
        require(enter.state.velocityY == -12 && enter.state.faceRoll == Int16(bitPattern: 0x8000), "swoop initial velocity")

        state.forwardVelocity = 0
        state.faceRoll = 1_000
        let dive = SM64SwoopKernel.tick(
            SM64SwoopTickInput(),
            state: &state
        )
        require(dive.state.forwardVelocity == 10 && dive.state.velocityY == -10, "begin dive")
        require(dive.effects == [.animate, .beginDive], "begin dive effects")

        state.velocityY = -0.5
        state.positionY = 100
        state.forwardVelocity = 10
        let speedUp = SM64SwoopKernel.tick(
            SM64SwoopTickInput(marioY: 0),
            state: &state
        )
        require(speedUp.state.velocityY == 0 && speedUp.state.forwardVelocity == 20, "swoop speed up")
        require(speedUp.effects == [.animate, .speedUp], "speed up effect")

        state.velocityY = 0
        let wall = SM64SwoopKernel.tick(
            SM64SwoopTickInput(reflectedYaw: 0x4000, moveFlags: SM64SwoopKernel.hitWallFlag),
            state: &state
        )
        require(wall.effects.contains(.wallBounce) && wall.state.bonkCountdown == 30, "wall bounce fence")

        let reset = SM64SwoopKernel.tick(
            SM64SwoopTickInput(marioFarAway: true),
            state: &state
        )
        require(reset.state.action == .idle && reset.state.positionY == 900 && reset.state.scale == 0, "far reset")
        require(reset.effects.contains(.resetHome), "far reset effect")

        let attacked = SM64SwoopKernel.tick(
            SM64SwoopTickInput(attacked: true),
            state: &state
        )
        require(attacked.state.markedForDeletion, "attack marks Swoop")
        require(attacked.effects.contains(.attackResponse) && attacked.effects.contains(.markForDeletion), "attack effects")
        require(SM64SwoopHitbox.standard.radius == 100 && SM64SwoopHitbox.standard.numLootCoins == 1, "hitbox constants")

        var fingerprint = fnvOffset
        fingerprint = hashKernel(fingerprint, enter)
        fingerprint = hashKernel(fingerprint, dive)
        fingerprint = hashKernel(fingerprint, speedUp)
        fingerprint = hashKernel(fingerprint, wall)
        fingerprint = hashKernel(fingerprint, reset)
        fingerprint = hashKernel(fingerprint, attacked)

        let engineState = SM64SwiftEngineState(objectCapacity: 6)
        let bridge = SM64SwoopObjectBridge()
        let swoop = try bridge.spawnSwoop(in: engineState, positionY: 500, homeY: 500)
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(swoop.traceSubject == 1 && mario.traceSubject == 2, "stable Swoop slots")

        let bridgeIdle = bridge.tick(
            state: engineState,
            inputs: [swoop: SM64SwoopTickInput(distanceToMario: 2_000)]
        )
        require(bridgeIdle.scheduler.updated.map(\.traceSubject) == [2, 1], "Swoop scheduler order")
        guard let idleRecord = engineState.objects.record(for: swoop) else {
            preconditionFailure("idle record missing")
        }

        for _ in 0..<18 {
            _ = bridge.tick(
                state: engineState,
                inputs: [swoop: SM64SwoopTickInput(distanceToMario: 2_000)]
            )
        }
        let bridgeEnter = bridge.tick(
            state: engineState,
            inputs: [swoop: SM64SwoopTickInput(distanceToMario: 1_000)]
        )
        require(bridgeEnter.effects[0].action == .move, "bridge move action")
        guard let enterRecord = engineState.objects.record(for: swoop) else {
            preconditionFailure("enter record missing")
        }

        for _ in 0..<13 {
            _ = bridge.tick(
                state: engineState,
                inputs: [swoop: SM64SwoopTickInput(targetRoll: 0)]
            )
        }
        let bridgeDive = bridge.tick(
            state: engineState,
            inputs: [swoop: SM64SwoopTickInput(targetRoll: 0)]
        )
        require(bridgeDive.effects[0].effects.contains(.beginDive), "bridge dive effect")
        guard let diveRecord = engineState.objects.record(for: swoop) else {
            preconditionFailure("dive record missing")
        }

        let bridgeAttack = bridge.tick(
            state: engineState,
            inputs: [swoop: SM64SwoopTickInput(attacked: true)]
        )
        require(bridgeAttack.scheduler.unloaded.map(\.traceSubject) == [1], "Swoop attack unload")
        require(
            bridge.deliveryLog.contains { $0.deleted == [swoop] },
            "Swoop deletion routed through owner thread"
        )
        require(!engineState.objects.contains(swoop) && bridge.state(for: swoop) == nil, "Swoop shadow removed")

        fingerprint = hashBridgeTick(fingerprint, bridgeIdle, record: idleRecord)
        fingerprint = hashBridgeTick(fingerprint, bridgeEnter, record: enterRecord)
        fingerprint = hashBridgeTick(fingerprint, bridgeDive, record: diveRecord)
        fingerprint = hashBridgeTick(fingerprint, bridgeAttack, record: nil)
        fingerprint = hashU64(fingerprint, 1)
        fingerprint = hashU64(fingerprint, 1)

        print(String(format: "swoopObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Swoop object bridge smoke passed")
    }
}
