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

private func hashResult(_ initial: UInt64, _ result: SM64EnemyLakituTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.subAction.rawValue))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceForwardCountdown)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.spinyCooldown)))
    hash = hashU64(hash, UInt64(state.numSpinies))
    hash = hashU64(hash, state.previousSpinyAttached ? 1 : 0)
    hash = hashU64(hash, UInt64(state.timer))
    return hashU64(hash, UInt64(result.effects.rawValue))
}

private func hashAttackTable(_ initial: UInt64) -> UInt64 {
    var hash = initial
    for attack in [
        SM64SpinyAttack.none,
        .punch,
        .kickOrTrip,
        .fromAbove,
        .groundPound,
        .fastAttack,
        .fromBelow,
    ] {
        let handler = SM64SpinyAttackTable.decision(attack)
        hash = hashU64(hash, UInt64(attack.rawValue))
        hash = hashU64(hash, UInt64(handler.rawValue))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernEnemyLakituSmoke {
    static func main() {
        var state = SM64EnemyLakituState()
        var fingerprint = fnvOffset

        let far = SM64EnemyLakituKernel.tick(
            .init(distanceToMario: 10_000),
            state: &state
        )
        require(state.action == .uninitialized, "far Lakitu remains hidden")
        fingerprint = hashResult(fingerprint, far)

        let reveal = SM64EnemyLakituKernel.tick(
            .init(distanceToMario: 1_000),
            state: &state
        )
        require(state.action == .main && reveal.effects.contains(.revealAndCloud), "Lakitu reveal gate")
        fingerprint = hashResult(fingerprint, reveal)

        let spawn = SM64EnemyLakituKernel.tick(
            .init(distanceToMario: 700, angleToMario: 0),
            state: &state
        )
        require(state.subAction == .holdSpiny && state.numSpinies == 1, "Spiny spawn count")
        require(state.spinyCooldown == 30 && state.previousSpinyAttached, "Spiny cooldown/parent link")
        require(spawn.effects.contains([.spawnSpiny, .beginHold]), "Spiny spawn effects")
        require(state.forwardVelocity == 20 && state.velocityY == 0.4, "Lakitu speed/vertical approach")
        fingerprint = hashResult(fingerprint, spawn)

        state.spinyCooldown = 0
        let beginThrow = SM64EnemyLakituKernel.tick(
            .init(distanceToMario: 400, angleToMario: 0),
            state: &state
        )
        require(state.subAction == .throwSpiny && state.faceForwardCountdown == 20, "hold-to-throw gate")
        require(beginThrow.effects.contains(.beginThrow), "begin throw effect")
        fingerprint = hashResult(fingerprint, beginThrow)

        let clearPrevious = SM64EnemyLakituKernel.tick(
            .init(animationFrameTwo: true),
            state: &state
        )
        require(!state.previousSpinyAttached, "throw clears parent link")
        require(clearPrevious.effects.contains([.throwSound, .clearPreviousSpiny]), "throw sound/link effect")
        fingerprint = hashResult(fingerprint, clearPrevious)

        let finishThrow = SM64EnemyLakituKernel.tick(
            .init(animationNearEnd: true, randomFraction: 0.5),
            state: &state
        )
        require(state.subAction == .noSpiny && state.spinyCooldown == 150, "throw cooldown")
        fingerprint = hashResult(fingerprint, finishThrow)

        state.spinyCooldown = 0
        state.numSpinies = 3
        let capped = SM64EnemyLakituKernel.tick(
            .init(distanceToMario: 400),
            state: &state
        )
        require(state.numSpinies == 3 && !capped.effects.contains(.spawnSpiny), "three-Spiny cap")
        fingerprint = hashResult(fingerprint, capped)
        fingerprint = hashAttackTable(fingerprint)

        print(String(format: "enemyLakituFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern enemy Lakitu smoke passed")
    }
}
