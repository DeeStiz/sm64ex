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

private func hashSnufit(_ initial: UInt64, _ result: SM64SnufitTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(state.homeX.bitPattern))
    hash = hashU64(hash, UInt64(state.homeY.bitPattern))
    hash = hashU64(hash, UInt64(state.homeZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.movePitch)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.facePitch)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.circularPeriod)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.bodyScalePeriod)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.bodyBaseScale)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.bodyScale)))
    hash = hashU64(hash, UInt64(state.scale.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.recoil)))
    hash = hashU64(hash, UInt64(state.bullets))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.tangible ? 1 : 0)
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBullet(_ initial: UInt64, _ result: SM64SnufitBulletTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.movePitch)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(state.gravity.bitPattern))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.intangible ? 1 : 0)
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64SnufitObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.kind.rawValue))
    hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 0xFF))
    hash = hashU64(hash, UInt64(effect.bulletAction?.rawValue ?? 0xFF))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedBullets.count))
    for child in effect.spawnedBullets {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    return hashU64(hash, effect.markedForDeletion ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSnufitObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var snufit = SM64SnufitState(positionX: 10, positionY: 20, positionZ: 30, moveYaw: 0x1000)
        let orbit = SM64SnufitKernel.tick(
            SM64SnufitTickInput(distanceToMario: 2_000, globalTimer: 3),
            state: &snufit
        )
        require(orbit.state.action == .idle && orbit.state.circularPeriod == 400, "snufit orbit")
        fingerprint = hashSnufit(fingerprint, orbit)

        snufit.timer = 20
        snufit.bodyBaseScale = 600
        snufit.bodyScalePeriod = 0
        let arm = SM64SnufitKernel.tick(
            SM64SnufitTickInput(distanceToMario: 100, angleToMario: 0x2000, marioPitch: 0x1000),
            state: &snufit
        )
        require(arm.state.action == .shoot && arm.state.bullets == 0, "snufit shoot admission")
        fingerprint = hashSnufit(fingerprint, arm)

        snufit.timer = 3
        let shot = SM64SnufitKernel.tick(
            SM64SnufitTickInput(distanceToMario: 100, angleToMario: 0x2000),
            state: &snufit
        )
        require(shot.effects.contains(.spawnBullet) && shot.state.bullets == 1,
                "snufit first shot")
        fingerprint = hashSnufit(fingerprint, shot)

        var bullet = SM64SnufitBulletState(moveYaw: 0, movePitch: 0)
        let flight = SM64SnufitKernel.tickBullet(
            SM64SnufitBulletTickInput(distanceToMario: 200),
            state: &bullet
        )
        require(flight.state.positionZ == 40 && !flight.state.markedForDeletion,
                "snufit bullet flight")
        fingerprint = hashBullet(fingerprint, flight)

        let bounce = SM64SnufitKernel.tickBullet(
            SM64SnufitBulletTickInput(distanceToMario: 200, hitMetalMario: true),
            state: &bullet
        )
        require(bounce.state.action == .bouncedFromMetal && bounce.state.intangible,
                "snufit metal bounce")
        fingerprint = hashBullet(fingerprint, bounce)

        let falling = SM64SnufitKernel.tickBullet(
            SM64SnufitBulletTickInput(distanceToMario: 200),
            state: &bullet
        )
        require(falling.state.gravity == -4 && falling.state.velocityY == 26,
                "snufit bounced gravity")
        fingerprint = hashBullet(fingerprint, falling)

        var dyingBullet = SM64SnufitBulletState()
        let death = SM64SnufitKernel.tickBullet(
            SM64SnufitBulletTickInput(distanceToMario: 200, hitWallOrGround: true),
            state: &dyingBullet
        )
        require(death.state.markedForDeletion && death.effects.contains(.bulletDeath),
                "snufit bullet wall death")
        fingerprint = hashBullet(fingerprint, death)

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64SnufitObjectBridge()
        let snufitID = try bridge.spawnSnufit(in: engineState, moveYaw: 0x1000)
        require(snufitID.traceSubject == 1, "stable snufit slot")
        let bridgeTick = bridge.tick(
            state: engineState,
            snufitInputs: [snufitID: SM64SnufitTickInput(distanceToMario: 100)]
        )
        require(bridgeTick.effects.count == 1, "snufit bridge effect count")
        guard let effect = bridgeTick.effects.first else { preconditionFailure("snufit effect missing") }
        require(effect.kind == .snufit && effect.spawnedBullets.isEmpty,
                "snufit bridge first tick")
        fingerprint = hashEffect(fingerprint, effect)

        // Advance the owned state to the first shot without mutating through a
        // pointer; the bridge remains the only allocation authority.
        var shotEffect: SM64SnufitObjectEffectRecord?
        for _ in 0..<100 where shotEffect == nil {
            let tick = bridge.tick(
                state: engineState,
                snufitInputs: [snufitID: SM64SnufitTickInput(distanceToMario: 100)]
            )
            shotEffect = tick.effects.first(where: {
                $0.objectID == snufitID && !$0.spawnedBullets.isEmpty
            })
        }
        guard let shotEffect else {
            preconditionFailure("snufit bridge shot effect missing")
        }
        require(shotEffect.spawnedBullets.count == 1, "snufit bridge child allocation")
        fingerprint = hashEffect(fingerprint, shotEffect)

        print(String(format: "snufitObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Snufit object bridge smoke passed")
    }
}
