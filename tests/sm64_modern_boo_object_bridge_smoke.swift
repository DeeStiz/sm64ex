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

private func hashState(_ initial: UInt64, _ result: SM64BooTickResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue), UInt64(s.action.rawValue),
        UInt64(s.homeX.bitPattern), UInt64(s.homeY.bitPattern), UInt64(s.homeZ.bitPattern),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.initialMoveYaw)), UInt64(UInt16(bitPattern: s.moveYaw)),
        UInt64(UInt16(bitPattern: s.faceYaw)), UInt64(UInt16(bitPattern: s.facePitch)),
        UInt64(UInt16(bitPattern: s.faceRoll)), UInt64(s.forwardVelocity.bitPattern),
        UInt64(s.velocityY.bitPattern), UInt64(s.gravity.bitPattern), UInt64(UInt16(bitPattern: s.opacity)),
        UInt64(UInt16(bitPattern: s.targetOpacity)), UInt64(s.baseScale.bitPattern),
        UInt64(s.renderScaleX.bitPattern), UInt64(s.renderScaleY.bitPattern), UInt64(s.renderScaleZ.bitPattern),
        UInt64(s.oscillationTimer), UInt64(UInt16(bitPattern: s.moveYawDuringHit)),
        UInt64(UInt16(bitPattern: s.moveYawBeforeHit)), UInt64(s.negatedAggressiveness.bitPattern),
        UInt64(UInt16(bitPattern: s.turningSpeed)), UInt64(s.deathStatus), s.tangible ? 1 : 0,
        UInt64(s.interactionType), s.markedForDeletion ? 1 : 0, UInt64(s.timer)
    ]
    return values.reduce(initial, hashU64)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64BooObjectEffectRecord) -> UInt64 {
    let values: [UInt64] = [
        UInt64(effect.objectID.traceSubject), UInt64(effect.effects.rawValue),
        UInt64(effect.action.rawValue), UInt64(UInt16(bitPattern: effect.opacity)),
        effect.markedForDeletion ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBooObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var boo = SM64BooState(homeX: 10, homeY: 500, homeZ: 30)
        let chase = SM64BooKernel.tick(
            SM64BooTickInput(distanceToMario: 1_000, angleToMario: 0, marioFaceYaw: 0, randomValue: 7),
            state: &boo
        )
        require(chase.state.action == .chase && chase.effects.contains(.chase), "Boo activation")
        fingerprint = hashState(fingerprint, chase)

        let visible = SM64BooKernel.tick(
            SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0, marioY: 0),
            state: &boo
        )
        require(visible.state.tangible && visible.effects.contains(.oscillate), "Boo chase visibility")
        fingerprint = hashState(fingerprint, visible)

        boo.opacity = 255
        let vanish = SM64BooKernel.tick(
            SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0x7FFF),
            state: &boo
        )
        require(vanish.state.targetOpacity == 40 && vanish.effects.contains(.vanish), "Boo vanish")
        fingerprint = hashState(fingerprint, vanish)

        boo.action = .chase
        boo.timer = 0
        let bounced = SM64BooKernel.tick(
            SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0, attackStatus: .bounced),
            state: &boo
        )
        require(bounced.state.action == .bounced && bounced.effects.contains(.bounced), "Boo bounce admission")
        fingerprint = hashState(fingerprint, bounced)

        boo.timer = 0
        let roll = SM64BooKernel.tick(
            SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0),
            state: &boo
        )
        require(roll.effects.contains(.bounced) && roll.state.moveYawDuringHit != 0, "Boo bounce roll")
        fingerprint = hashState(fingerprint, roll)

        boo.action = .death
        boo.timer = 31
        let death = SM64BooKernel.tick(
            SM64BooTickInput(marioMoveYaw: 0x4000, hitWall: true),
            state: &boo
        )
        require(death.state.markedForDeletion && death.effects.contains(.mist), "Boo death")
        fingerprint = hashState(fingerprint, death)

        let engineState = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64BooObjectBridge()
        let booID = try bridge.spawnBoo(in: engineState, homeX: 5, homeY: 500, homeZ: 15)
        require(booID.traceSubject == 1, "stable Boo slot")
        let first = bridge.tick(
            state: engineState,
            inputs: [booID: SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0, randomValue: 3)]
        )
        require(first.effects.count == 1, "Boo bridge callback")
        fingerprint = hashEffect(fingerprint, first.effects[0])

        let second = bridge.tick(
            state: engineState,
            inputs: [booID: SM64BooTickInput(distanceToMario: 300, angleToMario: 0, marioFaceYaw: 0)]
        )
        require(second.effects.count == 1 && bridge.state(for: booID) != nil, "Boo bridge state")
        fingerprint = hashEffect(fingerprint, second.effects[0])

        let attack = bridge.tick(
            state: engineState,
            inputs: [booID: SM64BooTickInput(
                distanceToMario: 300,
                angleToMario: 0,
                marioFaceYaw: 0,
                attackStatus: .attacked
            )]
        )
        require(attack.effects.first?.action == .death, "Boo bridge death admission")
        let deletion = bridge.tick(
            state: engineState,
            inputs: [booID: SM64BooTickInput(
                distanceToMario: 300,
                angleToMario: 0,
                marioFaceYaw: 0,
                hitWall: true
            )]
        )
        require(
            deletion.scheduler.unloaded == [booID] &&
                bridge.deliveryLog.contains { $0.deleted == [booID] },
            "Boo deletion must route through owner thread"
        )

        print(String(format: "booObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Boo object bridge smoke passed")
    }
}
