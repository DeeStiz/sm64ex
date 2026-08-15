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

private func hashState(_ initial: UInt64, _ result: SM64BobombTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.subtype.rawValue))
    hash = hashU64(hash, UInt64(state.heldState.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(state.fuseTimer))
    hash = hashU64(hash, UInt64(state.blinkTimer))
    hash = hashU64(hash, UInt64(state.scale.bitPattern))
    hash = hashU64(hash, state.fuseLit ? 1 : 0)
    hash = hashU64(hash, state.hidden ? 1 : 0)
    hash = hashU64(hash, state.tangible ? 1 : 0)
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64BobombObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.subtype.rawValue))
    hash = hashU64(hash, UInt64(effect.heldState.rawValue))
    hash = hashU64(hash, UInt64(effect.action.rawValue))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    return hashU64(hash, effect.markedForDeletion ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBobombObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var patrol = SM64BobombState(homeY: 100)
        let patrolResult = SM64BobombKernel.tick(
            SM64BobombTickInput(distanceFromHome: 0, facingTowardMario: true),
            state: &patrol
        )
        require(patrolResult.state.action == .chase, "generic patrol chase admission")
        require(patrolResult.state.forwardVelocity == 5, "generic patrol speed")
        require(patrolResult.state.fuseLit, "generic patrol lights fuse")
        fingerprint = hashState(fingerprint, patrolResult)

        patrol.animationFrame = 4
        let chaseResult = SM64BobombKernel.tick(
            SM64BobombTickInput(angleToMario: 0x2000),
            state: &patrol
        )
        require(chaseResult.state.action == .chase, "chase remains active")
        require(chaseResult.state.forwardVelocity == 20, "chase speed")
        require(chaseResult.effects.contains(.walkSound), "chase walk sound")
        fingerprint = hashState(fingerprint, chaseResult)

        let launchResult = SM64BobombKernel.tick(
            SM64BobombTickInput(
                marioYaw: 0x4000,
                interacted: true,
                marioUnk1: true,
                moveFlags: 0
            ),
            state: &patrol
        )
        require(launchResult.state.action == .launched, "interaction launch action")
        require(launchResult.state.forwardVelocity == 25 && launchResult.state.velocityY == 30,
                "interaction launch velocity")
        fingerprint = hashState(fingerprint, launchResult)

        var held = SM64BobombState(heldState: .held, action: .patrol)
        let heldResult = SM64BobombKernel.tick(
            SM64BobombTickInput(marioYaw: 0x4000, marioX: 10, marioY: 20, marioZ: 30),
            state: &held
        )
        require(heldResult.state.hidden, "held Bob-omb hidden")
        require(heldResult.state.positionY == 80, "held Bob-omb relative height")
        fingerprint = hashState(fingerprint, heldResult)

        var thrown = SM64BobombState(heldState: .thrown, action: .patrol)
        let thrownResult = SM64BobombKernel.tick(
            SM64BobombTickInput(marioYaw: -0x4000),
            state: &thrown
        )
        require(thrownResult.state.heldState == .free && thrownResult.state.action == .launched,
                "thrown release transition")
        require(thrownResult.state.forwardVelocity == 25 && thrownResult.state.velocityY == 20,
                "thrown release velocity")
        fingerprint = hashState(fingerprint, thrownResult)

        var stationary = SM64BobombState(subtype: .stationary, action: .launched)
        let stationaryResult = SM64BobombKernel.tick(
            SM64BobombTickInput(moveFlags: SM64BobombKernel.collisionGrounded),
            state: &stationary
        )
        require(stationaryResult.state.action == .explode, "stationary launch explosion")
        fingerprint = hashState(fingerprint, stationaryResult)

        var exploding = SM64BobombState(action: .explode)
        exploding.timer = 5
        let explosionResult = SM64BobombKernel.tick(SM64BobombTickInput(), state: &exploding)
        require(explosionResult.state.markedForDeletion, "explosion deletion")
        require(explosionResult.effects.contains(.explosion) && explosionResult.effects.contains(.coin),
                "explosion effects")
        fingerprint = hashState(fingerprint, explosionResult)

        let engineState = SM64SwiftEngineState(objectCapacity: 12)
        let bridge = SM64BobombObjectBridge()
        let bobombID = try bridge.spawnBobomb(in: engineState, homeY: 100)
        let marioID = try engineState.spawnObject(in: .player, isMario: true)
        require(bobombID.traceSubject == 1 && marioID.traceSubject == 2, "stable Bob-omb slots")

        let firstTick = bridge.tick(
            state: engineState,
            inputs: [
                bobombID: SM64BobombTickInput(
                    interacted: true,
                    touchedBobomb: true,
                    moveFlags: 0
                )
            ]
        )
        require(firstTick.effects.count == 1 && firstTick.effects[0].action == .explode,
                "bridge interaction explosion transition")
        fingerprint = hashEffect(fingerprint, firstTick.effects[0])

        var finalTick = firstTick
        for _ in 0..<5 {
            finalTick = bridge.tick(state: engineState, inputs: [bobombID: SM64BobombTickInput()])
        }
        guard let finalEffect = finalTick.effects.first else {
            preconditionFailure("final Bob-omb effect missing")
        }
        require(finalEffect.effects.contains(.explosion), "bridge explosion child effect")
        require(finalEffect.spawnedChildren.count == 2, "bridge explosion coin children")
        require(finalTick.scheduler.unloaded.count == 3, "bridge end-of-frame unload")
        fingerprint = hashEffect(fingerprint, finalEffect)
        require(bridge.state(for: bobombID) == nil, "deleted Bob-omb removed from bridge")

        print(String(format: "bobombObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bob-omb object bridge smoke passed")
    }
}
