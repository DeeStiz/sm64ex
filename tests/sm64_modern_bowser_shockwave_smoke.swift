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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64BowserShockWaveTickResult) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.state.timer))
    hash = hashFloat(hash, effect.state.scale)
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.state.opacity)))
    return hashU64(hash, effect.state.markedForDeletion ? 1 : 0)
}

@main
enum SM64ModernBowserShockWaveSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var valueState = SM64BowserShockWaveState()
        let expand = SM64BowserShockWaveKernel.tick(
            SM64BowserShockWaveTickInput(globalTimer: 1, marioDistance: 0),
            state: &valueState
        )
        require(expand.state.timer == 1 && expand.state.scale == 0, "shockwave initial expansion")
        require(expand.effects.contains(.fade), "shockwave global fade")
        fingerprint = hashEffect(fingerprint, expand)

        valueState.timer = 1
        valueState.opacity = 255
        let hit = SM64BowserShockWaveKernel.tick(
            SM64BowserShockWaveTickInput(globalTimer: 3, marioDistance: 21),
            state: &valueState
        )
        require(hit.effects.contains(.interactMario), "shockwave Mario ring")
        require(hit.state.scale == 10 && hit.state.opacity == 255, "shockwave scale/opacity")
        fingerprint = hashEffect(fingerprint, hit)

        valueState.timer = 71
        valueState.opacity = 5
        let fadeOut = SM64BowserShockWaveKernel.tick(
            SM64BowserShockWaveTickInput(globalTimer: 1, marioDistance: 0),
            state: &valueState
        )
        require(fadeOut.state.opacity == 0 && fadeOut.state.markedForDeletion, "shockwave deletion")
        require(fadeOut.effects.contains(.markForDeletion), "shockwave deletion effect")
        fingerprint = hashEffect(fingerprint, fadeOut)

        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BowserShockWaveObjectBridge()
        let marioID = try engine.spawnObject(in: .player, isMario: true)
        let waveID = try bridge.spawnShockWave(in: engine, position: .zero)
        var bridgeState = bridge.state(for: waveID)!
        bridgeState.timer = 1
        bridgeState.opacity = 255
        require(bridge.setState(bridgeState, for: waveID, in: engine.objects), "shockwave bridge state")
        let bridgeTick = bridge.tick(
            state: engine,
            inputs: [waveID: SM64BowserShockWaveTickInput(globalTimer: 3, marioDistance: 21)],
            marioID: marioID
        )
        guard let effect = bridgeTick.effects.first,
              let record = engine.objects.record(for: waveID),
              let mario = engine.objects.record(for: marioID) else {
            preconditionFailure("shockwave bridge record missing")
        }
        require(effect.interactedMario && mario.interactionStatus & SM64BowserShockWaveObjectBridge.marioInteractionBit != 0,
                "shockwave owner Mario interaction")
        require(record.scale == SM64ObjectVector3(x: 10, y: 10, z: 10), "shockwave owner scale")
        require(record.opacity == 255 && record.timer == 2, "shockwave owner publication")
        fingerprint = hashU64(fingerprint, UInt64(effect.objectID.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(effect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(effect.timer))
        fingerprint = hashFloat(fingerprint, effect.scale)
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(effect.opacity)))
        fingerprint = hashU64(fingerprint, effect.interactedMario ? 1 : 0)
        fingerprint = hashU64(fingerprint, UInt64(record.opacity))
        fingerprint = hashU64(fingerprint, UInt64(record.timer))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(mario.interactionStatus)))

        var dying = bridge.state(for: waveID)!
        dying.timer = 71
        dying.opacity = 5
        require(bridge.setState(dying, for: waveID, in: engine.objects), "shockwave dying state")
        let deathTick = bridge.tick(
            state: engine,
            inputs: [waveID: SM64BowserShockWaveTickInput(globalTimer: 1)],
            marioID: marioID
        )
        require(deathTick.scheduler.unloaded == [waveID], "shockwave owner unload")
        require(deathTick.effects.first?.markedForDeletion == true, "shockwave owner delete effect")
        fingerprint = hashU64(fingerprint, UInt64(deathTick.effects.first!.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(deathTick.scheduler.unloaded.count))

        print(String(format: "bowserShockWaveFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bowser shockwave smoke passed")
    }
}
