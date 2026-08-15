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

private func hashState(_ initial: UInt64, _ result: SM64PiranhaPlantTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(state.scale.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: state.opacity)))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.tangible ? 1 : 0)
    hash = hashU64(hash, state.hidden ? 1 : 0)
    hash = hashU64(hash, state.blueCoinRequested ? 1 : 0)
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64PiranhaPlantObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
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
enum SM64ModernPiranhaPlantObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var plant = SM64PiranhaPlantState()
        let idle = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(distanceToMario: 2_000),
            state: &plant
        )
        require(idle.state.action == .idle && !idle.state.tangible, "plant idle")
        fingerprint = hashState(fingerprint, idle)

        let sleep = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(distanceToMario: 1_000),
            state: &plant
        )
        require(sleep.state.action == .sleeping, "plant sleep admission")
        fingerprint = hashState(fingerprint, sleep)

        let wake = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(distanceToMario: 300, marioMovingFast: true),
            state: &plant
        )
        require(wake.state.action == .wokenUp && wake.state.tangible, "plant wake")
        fingerprint = hashState(fingerprint, wake)

        plant.timer = 11
        let biteTransition = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(
                distanceToMario: 300,
                angleToMario: 0x2000
            ),
            state: &plant
        )
        require(biteTransition.state.action == .biting, "plant bite transition")
        fingerprint = hashState(fingerprint, biteTransition)

        let bite = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(
                distanceToMario: 300,
                angleToMario: 0x2000,
                biteAnimationFrame: 12
            ),
            state: &plant
        )
        require(bite.state.action == .biting && bite.state.moveYaw == 0x400,
                "plant bite turn")
        require(bite.effects.contains(.biteSound), "plant bite sound")
        fingerprint = hashState(fingerprint, bite)

        let stopped = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(distanceToMario: 600, nearAnimationEnd: true),
            state: &plant
        )
        require(stopped.state.action == .stoppedBiting, "plant stopped biting")
        fingerprint = hashState(fingerprint, stopped)

        let sleepingAgain = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(distanceToMario: 600, nearAnimationEnd: true),
            state: &plant
        )
        require(sleepingAgain.state.action == .sleeping, "plant return to sleep")
        fingerprint = hashState(fingerprint, sleepingAgain)

        let attacked = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(interacted: true, wasAttacked: true),
            state: &plant
        )
        require(attacked.state.action == .attacked && attacked.effects.contains(.particles),
                "plant attacked particles")
        fingerprint = hashState(fingerprint, attacked)

        var shrinking = SM64PiranhaPlantState(action: .shrinkAndDie)
        shrinking.scale = 0.04
        let shrunk = SM64PiranhaPlantKernel.tick(SM64PiranhaPlantTickInput(), state: &shrinking)
        require(shrunk.state.action == .waitToRespawn && shrunk.state.blueCoinRequested,
                "plant blue coin respawn wait")
        fingerprint = hashState(fingerprint, shrunk)

        let respawn = SM64PiranhaPlantKernel.tick(
            SM64PiranhaPlantTickInput(distanceToMario: 2_000),
            state: &shrinking
        )
        require(respawn.state.action == .respawn, "plant respawn admission")
        fingerprint = hashState(fingerprint, respawn)

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64PiranhaPlantObjectBridge()
        let plantID = try bridge.spawnPlant(in: engineState, action: .sleeping)
        let marioID = try engineState.spawnObject(in: .player, isMario: true)
        require(plantID.traceSubject == 1 && marioID.traceSubject == 2, "stable plant slots")
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [plantID: SM64PiranhaPlantTickInput(interacted: true, wasAttacked: true)]
        )
        require(bridgeTick.effects.count == 1, "plant bridge effect count")
        guard let bridgeEffect = bridgeTick.effects.first else {
            preconditionFailure("plant bridge effect missing")
        }
        require(bridgeEffect.action == .attacked && bridgeEffect.spawnedChildren.count == 20,
                "plant bridge particle children")
        require(bridgeTick.scheduler.unloaded.count == 20, "plant particle unload")
        fingerprint = hashEffect(fingerprint, bridgeEffect)

        print(String(format: "piranhaPlantObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Piranha Plant object bridge smoke passed")
    }
}
