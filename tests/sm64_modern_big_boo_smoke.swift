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

private func hashResult(_ initial: UInt64, _ result: SM64BigBooTickResult) -> UInt64 {
    let state = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue),
        UInt64(state.variant.rawValue),
        UInt64(state.action.rawValue),
        UInt64(bitPattern: Int64(state.health)),
        UInt64(bitPattern: Int64(state.timer)),
        state.tangible ? 1 : 0,
        state.hidden ? 1 : 0,
        state.markedForDeletion ? 1 : 0,
        result.starPosition == nil ? 0 : 1,
        result.bridgePosition == nil ? 0 : 1
    ]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBigBooSmoke {
    static func main() {
        var fingerprint = fnvOffset

        var gated = SM64BigBooState(variant: .ghostHunt, minionBoosKilled: 4)
        let gatedResult = SM64BigBooKernel.tick(
            SM64BigBooTickInput(distanceToMario: 500), state: &gated
        )
        require(gatedResult.state.action == .initialize && gatedResult.state.hidden,
                "Big Boo waits for five minion Boos")
        fingerprint = hashResult(fingerprint, gatedResult)

        var active = SM64BigBooState(variant: .ghostHunt, minionBoosKilled: 5)
        let activeResult = SM64BigBooKernel.tick(
            SM64BigBooTickInput(distanceToMario: 500, randomValue: 37), state: &active
        )
        require(activeResult.state.action == .chase && activeResult.state.tangible,
                "Big Boo activation gate")
        require(activeResult.effects.contains([.tangible, .chase]),
                "Big Boo activation effects")
        fingerprint = hashResult(fingerprint, activeResult)

        var nonlethal = SM64BigBooState(variant: .ghostHunt, minionBoosKilled: 5)
        nonlethal.action = .death
        nonlethal.health = 3
        let hit = SM64BigBooKernel.tick(
            SM64BigBooTickInput(marioMoveYaw: 0x220), state: &nonlethal
        )
        require(hit.state.health == 2 && hit.state.action == .death,
                "Big Boo nonlethal health decrement")
        require(hit.effects.contains([.mist, .shake]), "Big Boo nonlethal hit effects")
        fingerprint = hashResult(fingerprint, hit)

        var lethal = SM64BigBooState(variant: .ghostHunt, minionBoosKilled: 5)
        lethal.action = .death
        lethal.health = 1
        let lethalStart = SM64BigBooKernel.tick(
            SM64BigBooTickInput(marioMoveYaw: 0x400), state: &lethal
        )
        require(lethalStart.state.health == 0 && lethalStart.state.action == .death,
                "Big Boo lethal death starts after final hit")
        fingerprint = hashResult(fingerprint, lethalStart)

        lethal.timer = 31
        let lethalEnd = SM64BigBooKernel.tick(
            SM64BigBooTickInput(marioMoveYaw: 0x400, hitWall: true), state: &lethal
        )
        require(lethalEnd.state.action == .postDeath && lethalEnd.effects.contains(.star),
                "Big Boo lethal reward transition")
        require(lethalEnd.starPosition == SM64BigBooKernel.ghostHuntStarPosition,
                "Ghost Hunt Big Boo star coordinates")
        fingerprint = hashResult(fingerprint, lethalEnd)

        var bridge = SM64BigBooState(variant: .ghostHunt, minionBoosKilled: 5)
        bridge.action = .postDeath
        bridge.timer = 61
        let bridgeResult = SM64BigBooKernel.tick(
            SM64BigBooTickInput(distanceToMario: 500), state: &bridge
        )
        require(bridgeResult.effects.contains([.spawnBridge, .markForDeletion]),
                "Ghost Hunt bridge transition")
        require(bridgeResult.bridgePosition == SM64BigBooKernel.ghostHuntBridgePosition,
                "Ghost Hunt bridge destination")
        require(bridgeResult.state.markedForDeletion, "Big Boo retires after bridge spawn")
        fingerprint = hashResult(fingerprint, bridgeResult)

        var balcony = SM64BigBooState(variant: .balcony)
        balcony.action = .death
        balcony.health = 0
        balcony.timer = 31
        let balconyReward = SM64BigBooKernel.tick(
            SM64BigBooTickInput(hitWall: true), state: &balcony
        )
        require(balconyReward.starPosition == SM64BigBooKernel.balconyStarPosition,
                "Balcony Big Boo star coordinates")
        fingerprint = hashResult(fingerprint, balconyReward)

        print(String(format: "bigBooFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Big Boo smoke passed")
    }
}
