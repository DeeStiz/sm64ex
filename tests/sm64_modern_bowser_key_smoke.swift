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

private func hashValue(_ initial: UInt64, _ result: SM64BowserKeyTickResult) -> UInt64 {
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(result.state.action.rawValue))
    hash = hashU64(hash, UInt64(result.state.timer))
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.state.angleVelocityYaw)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.state.faceYaw)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.state.faceRoll)))
    hash = hashFloat(hash, result.state.velocityY)
    hash = hashFloat(hash, result.state.scale)
    hash = hashU64(hash, result.state.tangible ? 1 : 0)
    return hashU64(hash, result.state.markedForDeletion ? 1 : 0)
}

@main
enum SM64ModernBowserKeySmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var valueState = SM64BowserKeyState(angleVelocityYaw: 0x600, faceYaw: 0x1000)
        let flight = SM64BowserKeyKernel.tick(
            SM64BowserKeyTickInput(landed: true),
            state: &valueState
        )
        require(flight.state.action == .airborne, "key flight action")
        require(flight.state.velocityY == 70, "key launch velocity")
        require(flight.state.angleVelocityYaw == 0x500, "key yaw damping")
        require(flight.state.faceYaw == 0x1500, "key face yaw")
        require(flight.effects.contains(.sparkleParticles), "key flight sparkle particles")
        require(flight.effects.contains(.sparkleSpawn), "key flight sparkle spawn")
        require(flight.effects.contains(.landingSound), "key landing sound")
        fingerprint = hashValue(fingerprint, flight)

        let land = SM64BowserKeyKernel.tick(
            SM64BowserKeyTickInput(onGround: true),
            state: &valueState
        )
        require(land.state.action == .landed && !land.state.tangible, "key land transition")
        require(!land.effects.contains(.setHitbox), "key hitbox delayed one frame")
        fingerprint = hashValue(fingerprint, land)

        let arm = SM64BowserKeyKernel.tick(
            SM64BowserKeyTickInput(onGround: true),
            state: &valueState
        )
        require(arm.state.tangible && arm.effects.contains(.setHitbox), "key hitbox activation")
        fingerprint = hashValue(fingerprint, arm)

        let collect = SM64BowserKeyKernel.tick(
            SM64BowserKeyTickInput(interacted: true),
            state: &valueState
        )
        require(collect.state.markedForDeletion, "key deletion state")
        require(collect.effects.contains(.clearInteraction), "key interaction clear")
        require(collect.effects.contains(.markForDeletion), "key deletion effect")
        fingerprint = hashValue(fingerprint, collect)

        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BowserKeyObjectBridge()
        let keyID = try bridge.spawnKey(
            in: engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30),
            faceYaw: 0x1000,
            angleVelocityYaw: 0x600
        )
        let launch = bridge.tick(
            state: engine,
            inputs: [keyID: SM64BowserKeyTickInput(landed: true)]
        )
        guard let launchEffect = launch.effects.first,
              let launchRecord = engine.objects.record(for: keyID) else {
            preconditionFailure("key launch owner record missing")
        }
        require(launchEffect.action == .airborne, "key owner launch action")
        require(launchRecord.velocity.y == 70, "key owner launch velocity")
        require(launchRecord.faceAngles.yaw == 0x1500, "key owner yaw")
        fingerprint = hashU64(fingerprint, UInt64(launchEffect.objectID.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(launchEffect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(launchRecord.timer))
        fingerprint = hashFloat(fingerprint, launchRecord.velocity.y)
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(launchRecord.faceAngles.yaw)))

        _ = bridge.tick(
            state: engine,
            inputs: [keyID: SM64BowserKeyTickInput(onGround: true)]
        )
        let armTick = bridge.tick(
            state: engine,
            inputs: [keyID: SM64BowserKeyTickInput(onGround: true)]
        )
        guard let armedRecord = engine.objects.record(for: keyID),
              let armedEffect = armTick.effects.first else {
            preconditionFailure("key armed owner record missing")
        }
        require(armedRecord.interactionType == SM64BowserKeyKernel.interactionType, "key owner hitbox")
        require(armedRecord.intangibleTimer == -1 && armedEffect.tangible, "key owner tangible")
        fingerprint = hashU64(fingerprint, UInt64(armedEffect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(armedRecord.interactionType))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(armedRecord.intangibleTimer)))

        let deleteTick = bridge.tick(
            state: engine,
            inputs: [keyID: SM64BowserKeyTickInput(interacted: true)]
        )
        require(deleteTick.scheduler.unloaded == [keyID], "key owner unload")
        require(deleteTick.effects.first?.markedForDeletion == true, "key owner deletion")
        fingerprint = hashU64(fingerprint, UInt64(deleteTick.effects.first!.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(deleteTick.scheduler.unloaded.count))

        print(String(format: "bowserKeyFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bowser key smoke passed")
    }
}
