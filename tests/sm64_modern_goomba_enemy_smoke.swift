import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 {
    var next = h
    next ^= UInt64(value)
    next &*= fnvPrime
    return next
}

private func h16(_ h: UInt64, _ value: UInt16) -> UInt64 {
    (0..<2).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt16($1 * 8)))
    }
}

private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    (0..<4).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt32($1 * 8)))
    }
}

private func hFloat(_ h: UInt64, _ value: Float) -> UInt64 {
    h32(h, value.bitPattern)
}

private func hash(_ h: UInt64, _ result: SM64GoombaTickResult) -> UInt64 {
    let state = result.state
    var next = h8(h, state.size.rawValue)
    next = h8(next, state.action.rawValue)
    next = h16(next, UInt16(bitPattern: state.moveAngleYaw))
    next = h16(next, UInt16(bitPattern: state.targetYaw))
    next = hFloat(next, state.forwardVelocity)
    next = hFloat(next, state.velocityY)
    next = hFloat(next, state.relativeSpeed)
    next = h16(next, UInt16(bitPattern: state.walkTimer))
    next = h8(next, state.turningAwayFromWall ? 1 : 0)
    next = h32(next, state.timer)
    next = h16(next, UInt16(bitPattern: state.health))
    next = h8(next, state.numLootCoins)
    next = h8(next, state.markedForDeletion ? 1 : 0)
    next = h8(next, state.respawnMarked ? 1 : 0)
    next = hFloat(next, state.animationSpeed)
    return h16(next, result.effects.rawValue)
}

@main
enum SM64ModernGoombaEnemySmoke {
    static func main() {
        var fingerprint = fnvOffset
        var regular = SM64GoombaState(size: .regular)
        precondition(regular.scale == 1.5 && regular.gravity == -4)
        precondition(regular.drawDistance == 4000 && regular.damage == 1)
        precondition(regular.hitbox.radius == 72 && regular.hitbox.hurtboxHeight == 40)

        let farWalk = SM64GoombaKernel.tick(
            .init(
                distanceToMario: 10_000, angleToMario: 0x1000,
                randomU16: 1, randomFraction: 0.25
            ), state: &regular
        )
        precondition(regular.action == .walk)
        precondition(regular.walkTimer == 125)
        fingerprint = hash(fingerprint, farWalk)

        let close = SM64GoombaKernel.tick(
            .init(distanceToMario: 400, angleToMario: 0x3000), state: &regular
        )
        precondition(regular.action == .jump)
        precondition(close.effects.contains([.alertSound, .jump]))
        fingerprint = hash(fingerprint, close)

        let airborne = SM64GoombaKernel.tick(
            .init(onGround: false), state: &regular
        )
        precondition(regular.action == .jump)
        fingerprint = hash(fingerprint, airborne)

        let landed = SM64GoombaKernel.tick(
            .init(onGround: true), state: &regular
        )
        precondition(regular.action == .walk)
        precondition(landed.effects.contains(.landed))
        fingerprint = hash(fingerprint, landed)

        var tiny = SM64GoombaState(size: .tiny)
        _ = SM64GoombaKernel.tick(
            .init(attack: .fromAbove), state: &tiny
        )
        let tinyDeath = SM64GoombaKernel.tick(.init(), state: &tiny)
        precondition(tiny.markedForDeletion && tiny.numLootCoins == 0)
        precondition(tinyDeath.effects.contains([.death, .markRespawn]))
        fingerprint = hash(fingerprint, tinyDeath)

        var huge = SM64GoombaState(size: .huge)
        _ = SM64GoombaKernel.tick(.init(attack: .weak), state: &huge)
        let hugeResponse = SM64GoombaKernel.tick(.init(), state: &huge)
        precondition(huge.action == .jump && huge.health == 1)
        precondition(hugeResponse.effects.contains(.jump))
        fingerprint = hash(fingerprint, hugeResponse)

        print(String(format: "goombaEnemyFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Goomba enemy smoke passed")
    }
}
