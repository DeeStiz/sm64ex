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

private func hashEye(_ initial: UInt64, _ result: SM64MrITickResult) -> UInt64 {
    let s = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(s.action.rawValue))
    hash = hashU64(hash, s.isKing ? 1 : 0)
    hash = hashU64(hash, UInt64(s.homeX.bitPattern))
    hash = hashU64(hash, UInt64(s.homeY.bitPattern))
    hash = hashU64(hash, UInt64(s.homeZ.bitPattern))
    hash = hashU64(hash, UInt64(s.positionX.bitPattern))
    hash = hashU64(hash, UInt64(s.positionY.bitPattern))
    hash = hashU64(hash, UInt64(s.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: s.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: s.movePitch)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: s.angleVelocityYaw)))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: s.turnAccum)))
    hash = hashU64(hash, UInt64(UInt8(bitPattern: s.turnDirection)))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: s.turnTimer)))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: s.particleTimer)))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: s.particleDelay)))
    hash = hashU64(hash, UInt64(s.scale.bitPattern))
    hash = hashU64(hash, UInt64(s.size.bitPattern))
    hash = hashU64(hash, UInt64(s.timer))
    hash = hashU64(hash, s.tangible ? 1 : 0)
    return hashU64(hash, s.markedForDeletion ? 1 : 0)
}

private func hashParticle(_ initial: UInt64, _ result: SM64MrIParticleTickResult) -> UInt64 {
    let s = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(s.action.rawValue))
    hash = hashU64(hash, UInt64(s.positionX.bitPattern))
    hash = hashU64(hash, UInt64(s.positionY.bitPattern))
    hash = hashU64(hash, UInt64(s.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: s.moveYaw)))
    hash = hashU64(hash, UInt64(s.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(s.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(s.timer))
    return hashU64(hash, s.markedForDeletion ? 1 : 0)
}

private func hashBody(_ initial: UInt64, _ result: SM64MrIBodyTickResult) -> UInt64 {
    let s = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(s.positionX.bitPattern))
    hash = hashU64(hash, UInt64(s.positionY.bitPattern))
    hash = hashU64(hash, UInt64(s.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(s.scale.bitPattern))
    hash = hashU64(hash, UInt64(s.relativeZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: s.animationState)))
    hash = hashU64(hash, UInt64(s.timer))
    return hashU64(hash, s.markedForDeletion ? 1 : 0)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64MrIObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.kind.rawValue))
    hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 255))
    hash = hashU64(hash, UInt64(effect.particleAction?.rawValue ?? 255))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren { hash = hashU64(hash, UInt64(child.traceSubject)) }
    return hashU64(hash, effect.markedForDeletion ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernMrIObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var eye = SM64MrIState(homeX: 10, homeY: 20, homeZ: 30)
        let idle = SM64MrIKernel.tick(
            SM64MrITickInput(distanceToMario: 2_000),
            state: &eye
        )
        require(idle.state.action == .idle && !idle.state.tangible, "Mr I idle")
        fingerprint = hashEye(fingerprint, idle)

        let awake = SM64MrIKernel.tick(
            SM64MrITickInput(distanceToMario: 1_000),
            state: &eye
        )
        require(awake.state.action == .tracking, "Mr I tracking admission")
        fingerprint = hashEye(fingerprint, awake)

        eye.timer = 0
        let tracking = SM64MrIKernel.tick(
            SM64MrITickInput(
                distanceToMario: 600,
                angleToMario: 0x100,
                marioFaceYaw: Int16(bitPattern: 0x8000),
                randomValue: 3
            ),
            state: &eye
        )
        require(tracking.state.action == .turning && tracking.state.tangible, "Mr I turning admission")
        fingerprint = hashEye(fingerprint, tracking)

        eye.timer = 0
        let turning = SM64MrIKernel.tick(
            SM64MrITickInput(distanceToMario: 600, angleToMario: 0x2000, randomValue: 7),
            state: &eye
        )
        require(turning.state.action == .turning, "Mr I turning step")
        fingerprint = hashEye(fingerprint, turning)

        var dying = SM64MrIState()
        dying.action = .dying
        dying.timer = 104
        let death = SM64MrIKernel.tick(SM64MrITickInput(), state: &dying)
        require(death.effects.contains(.blueCoin) && !death.state.tangible, "Mr I blue coin death")
        fingerprint = hashEye(fingerprint, death)

        var king = SM64MrIState(isKing: true)
        king.action = .dying
        king.timer = 104
        let kingDeath = SM64MrIKernel.tick(SM64MrITickInput(), state: &king)
        require(kingDeath.effects.contains(.star) && kingDeath.state.markedForDeletion,
                "King Mr I star death")
        fingerprint = hashEye(fingerprint, kingDeath)

        var particle = SM64MrIParticleState(moveYaw: 0)
        let particleFlight = SM64MrIKernel.tickParticle(
            SM64MrIParticleTickInput(),
            state: &particle
        )
        require(particleFlight.state.positionZ == 20, "Mr I particle flight")
        fingerprint = hashParticle(fingerprint, particleFlight)

        _ = SM64MrIKernel.tickParticle(
            SM64MrIParticleTickInput(interacted: true),
            state: &particle
        )
        let burst = SM64MrIKernel.tickParticle(
            SM64MrIParticleTickInput(),
            state: &particle
        )
        require(burst.effects.contains(.particleBurst) && burst.state.markedForDeletion,
                "Mr I particle burst")
        fingerprint = hashParticle(fingerprint, burst)

        var bodyState = SM64MrIBodyState()
        let body = SM64MrIKernel.tickBody(
            SM64MrIBodyTickInput(parentScale: 2, parentParticleFlash: true),
            state: &bodyState
        )
        require(body.state.relativeZ == 200 && body.state.animationState == 0,
                "Mr I body child")
        fingerprint = hashBody(fingerprint, body)

        let engineState = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64MrIObjectBridge()
        let eyeID = try bridge.spawnMrI(in: engineState)
        require(eyeID.traceSubject == 1, "stable Mr I eye slot")
        let firstTick = bridge.tick(
            state: engineState,
            eyeInputs: [eyeID: SM64MrITickInput(distanceToMario: 1_000)]
        )
        guard let eyeEffect = firstTick.effects.first(where: { $0.objectID == eyeID }) else {
            preconditionFailure("Mr I eye effect missing")
        }
        require(firstTick.effects.contains(where: { $0.kind == .body }), "Mr I body bridge")
        fingerprint = hashEffect(fingerprint, eyeEffect)

        var particleEffect: SM64MrIObjectEffectRecord?
        for _ in 0..<100 where particleEffect == nil {
            let tick = bridge.tick(
                state: engineState,
                eyeInputs: [eyeID: SM64MrITickInput(
                    distanceToMario: 1_000,
                    marioFaceYaw: Int16(bitPattern: 0x8000),
                    randomValue: 3
                )]
            )
            particleEffect = tick.effects.first(where: {
                $0.objectID == eyeID && !$0.spawnedChildren.isEmpty
            })
        }
        guard let particleEffect else { preconditionFailure("Mr I particle bridge missing") }
        require(particleEffect.spawnedChildren.count == 1, "Mr I particle child count")
        fingerprint = hashEffect(fingerprint, particleEffect)

        print(String(format: "mrIObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mr I object bridge smoke passed")
    }
}
