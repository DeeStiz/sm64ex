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

private func hashState(_ initial: UInt64, _ result: SM64MoneybagTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.jumpState.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(UInt32(bitPattern: state.opacity)))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.tangible ? 1 : 0)
    hash = hashU64(hash, state.markedForDeletion ? 1 : 0)
    return hashU64(hash, UInt64(state.coinCount))
}

private func hashHidden(_ initial: UInt64, _ result: SM64MoneybagHiddenTickResult) -> UInt64 {
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(result.state.action.rawValue))
    hash = hashU64(hash, UInt64(result.state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(result.state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(result.state.positionZ.bitPattern))
    return hashU64(hash, UInt64(result.state.timer))
}

private func hashEffect(_ initial: UInt64, _ effect: SM64MoneybagObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, effect.kind ? 1 : 0)
    hash = hashU64(hash, UInt64(effect.action))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren { hash = hashU64(hash, UInt64(child.traceSubject)) }
    return hashU64(hash, effect.markedForDeletion ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernMoneybagObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var bag = SM64MoneybagState(action: .appear, positionY: 100)
        let appear = SM64MoneybagKernel.tick(SM64MoneybagTickInput(), state: &bag)
        require(appear.state.opacity == 12 && appear.state.action == .appear, "moneybag appear")
        fingerprint = hashState(fingerprint, appear)

        bag.opacity = 249
        let move = SM64MoneybagKernel.tick(SM64MoneybagTickInput(), state: &bag)
        require(move.state.opacity == 255 && move.state.action == .moveAround, "moneybag appear complete")
        fingerprint = hashState(fingerprint, move)

        bag.timer = 31
        let movement = SM64MoneybagKernel.tick(
            SM64MoneybagTickInput(homeDistanceToMario: 900, collisionFlags: SM64MoneybagKernel.landedFlags),
            state: &bag
        )
        require(movement.state.action == .returnHome, "moneybag return home")
        require(movement.effects.contains(.tangible), "moneybag tangible gate")
        fingerprint = hashState(fingerprint, movement)

        var jumping = SM64MoneybagState(action: .moveAround, positionY: 100)
        jumping.jumpState = .prepare
        let jump = SM64MoneybagKernel.tick(
            SM64MoneybagTickInput(collisionFlags: 0, animationFrame: 5, nearAnimationEnd: true),
            state: &jumping
        )
        require(jump.state.jumpState == .jump && jump.state.forwardVelocity == 20 && jump.state.velocityY == 37,
                "moneybag prepare jump")
        fingerprint = hashState(fingerprint, jump)

        let attackedMario = SM64MoneybagKernel.tick(
            SM64MoneybagTickInput(angleToMario: 0x2000, interacted: true, attackedMario: true, collisionFlags: 0),
            state: &jumping
        )
        require(attackedMario.state.velocityY == 30, "moneybag bounce reaction")
        fingerprint = hashState(fingerprint, attackedMario)

        var dying = SM64MoneybagState(action: .moveAround)
        let deathTransition = SM64MoneybagKernel.tick(
            SM64MoneybagTickInput(interacted: true, wasAttacked: true),
            state: &dying
        )
        require(deathTransition.state.action == .death, "moneybag death transition")
        fingerprint = hashState(fingerprint, deathTransition)
        let death = SM64MoneybagKernel.tick(SM64MoneybagTickInput(), state: &dying)
        require(death.state.markedForDeletion && death.state.coinCount == 5, "moneybag death loot")
        fingerprint = hashState(fingerprint, death)

        var disappearing = SM64MoneybagState(action: .disappear)
        disappearing.opacity = 6
        let disappear = SM64MoneybagKernel.tick(SM64MoneybagTickInput(), state: &disappearing)
        require(disappear.state.markedForDeletion, "moneybag disappear deletion")
        fingerprint = hashState(fingerprint, disappear)

        var hidden = SM64MoneybagHiddenState()
        let hiddenResult = SM64MoneybagKernel.tickHidden(
            SM64MoneybagHiddenTickInput(withinRadius: true, moneybagPositionX: 10, moneybagPositionY: 20, moneybagPositionZ: 30),
            state: &hidden
        )
        require(hiddenResult.state.action == .transform && hiddenResult.effects.contains(.hiddenSpawn), "hidden moneybag transform")
        fingerprint = hashHidden(fingerprint, hiddenResult)

        let engineState = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64MoneybagObjectBridge()
        let bagID = try bridge.spawnMoneybag(in: engineState, action: .death)
        let marioID = try engineState.spawnObject(in: .player, isMario: true)
        require(bagID.traceSubject == 1 && marioID.traceSubject == 2, "stable Moneybag slots")
        let firstTick = bridge.tick(state: engineState, inputs: [bagID: SM64MoneybagTickInput()])
        require(firstTick.effects.count == 1, "moneybag bridge transition")
        fingerprint = hashEffect(fingerprint, firstTick.effects[0])
        let finalTick = bridge.tick(state: engineState, inputs: [bagID: SM64MoneybagTickInput()])
        guard let finalEffect = finalTick.effects.first else { preconditionFailure("moneybag final effect missing") }
        require(finalEffect.spawnedChildren.count == 6 && finalEffect.markedForDeletion,
                "moneybag bridge loot/mist children")
        require(finalTick.scheduler.unloaded.count == 7, "moneybag end-of-frame unload")
        fingerprint = hashEffect(fingerprint, finalEffect)

        print(String(format: "moneybagObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Moneybag object bridge smoke passed")
    }
}
