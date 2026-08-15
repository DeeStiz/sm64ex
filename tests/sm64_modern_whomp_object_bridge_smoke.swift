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

private func hashState(_ initial: UInt64, _ result: SM64WhompTickResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue),
        UInt64(s.size.rawValue),
        UInt64(s.action.rawValue),
        UInt64(s.homeX.bitPattern), UInt64(s.homeY.bitPattern), UInt64(s.homeZ.bitPattern),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)),
        UInt64(UInt16(bitPattern: s.facePitch)),
        UInt64(UInt16(bitPattern: s.angleVelocityPitch)),
        UInt64(s.forwardVelocity.bitPattern),
        UInt64(s.velocityY.bitPattern),
        UInt64(UInt16(bitPattern: s.health)),
        UInt64(UInt32(bitPattern: s.subAction)),
        UInt64(UInt32(bitPattern: s.shakeValue)),
        UInt64(s.timer),
        s.tangible ? 1 : 0,
        s.hidden ? 1 : 0,
        s.markedForDeletion ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64WhompObjectEffectRecord) -> UInt64 {
    let values: [UInt64] = [
        UInt64(effect.objectID.traceSubject),
        UInt64(effect.size.rawValue),
        UInt64(effect.action.rawValue),
        UInt64(effect.effects.rawValue),
        UInt64(UInt16(bitPattern: effect.health)),
        effect.markedForDeletion ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernWhompObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var normal = SM64WhompState(size: .normal, homeX: 10, homeY: 20, homeZ: 30)
        let initial = SM64WhompKernel.tick(
            SM64WhompTickInput(distanceToMario: 2_000), state: &normal
        )
        require(initial.state.action == .initialize && initial.state.positionX == 10,
                "Whomp initialize")
        fingerprint = hashState(fingerprint, initial)

        let chase = SM64WhompKernel.tick(
            SM64WhompTickInput(distanceToMario: 400, angleToMario: 0), state: &normal
        )
        require(chase.state.action == .chase && chase.effects.contains(.chase),
                "Whomp chase admission")
        fingerprint = hashState(fingerprint, chase)

        let pound = SM64WhompKernel.tick(
            SM64WhompTickInput(distanceToMario: 200, angleToMario: 0), state: &normal
        )
        require(pound.state.action == .pound && pound.effects.contains(.pound),
                "Whomp pound admission")
        fingerprint = hashState(fingerprint, pound)

        let fall = SM64WhompKernel.tick(
            SM64WhompTickInput(animationNearEnd: true), state: &normal
        )
        require(fall.state.action == .fall && fall.effects.contains(.fall),
                "Whomp fall transition")
        fingerprint = hashState(fingerprint, fall)

        normal.action = .fall
        normal.timer = 8
        normal.facePitch = 0x3FFF
        normal.angleVelocityPitch = 0x100
        let landed = SM64WhompKernel.tick(
            SM64WhompTickInput(), state: &normal
        )
        require(landed.state.action == .landed && landed.state.facePitch == 0x4000,
                "Whomp landing angle")
        fingerprint = hashState(fingerprint, landed)

        normal.action = .landed
        normal.subAction = 0
        let onGround = SM64WhompKernel.tick(
            SM64WhompTickInput(landed: true, onGround: true), state: &normal
        )
        require(onGround.state.action == .onGround && onGround.effects.contains(.shake),
                "Whomp ground admission")
        fingerprint = hashState(fingerprint, onGround)

        normal.action = .onGround
        normal.subAction = 0
        let normalDeath = SM64WhompKernel.tick(
            SM64WhompTickInput(marioGroundPound: true, marioOnPlatform: true),
            state: &normal
        )
        require(normalDeath.state.action == .death && normalDeath.effects.contains(.coins),
                "Whomp normal defeat")
        fingerprint = hashState(fingerprint, normalDeath)

        let normalDelete = SM64WhompKernel.tick(SM64WhompTickInput(), state: &normal)
        require(normalDelete.state.markedForDeletion && normalDelete.effects.contains(.markForDeletion),
                "Whomp normal deletion")
        fingerprint = hashState(fingerprint, normalDelete)

        var king = SM64WhompState(size: .king)
        king.subAction = 1
        let kingTurn = SM64WhompKernel.tick(
            SM64WhompTickInput(dialogComplete: true), state: &king
        )
        require(kingTurn.state.action == .turn && kingTurn.effects.contains(.cameraFocus),
                "King Whomp dialog transition")
        fingerprint = hashState(fingerprint, kingTurn)

        king.action = .onGround
        king.subAction = 0
        king.health = 2
        let kingHit = SM64WhompKernel.tick(
            SM64WhompTickInput(marioGroundPound: true), state: &king
        )
        require(kingHit.state.health == 1 && kingHit.effects.contains(.triangleBreak),
                "King Whomp damage")
        fingerprint = hashState(fingerprint, kingHit)

        king.action = .onGround
        king.subAction = 0
        king.health = 1
        _ = SM64WhompKernel.tick(SM64WhompTickInput(marioGroundPound: true), state: &king)
        require(king.action == .death, "King Whomp final pound")
        king.timer = 0
        let kingDeath = SM64WhompKernel.tick(
            SM64WhompTickInput(dialogComplete: true), state: &king
        )
        require(kingDeath.state.action == .bossWait && kingDeath.effects.contains(.star),
                "King Whomp star defeat")
        fingerprint = hashState(fingerprint, kingDeath)

        let engineState = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64WhompObjectBridge()
        let whompID = try bridge.spawnWhomp(
            in: engineState, size: .normal, homeX: 5, homeY: 10, homeZ: 15
        )
        require(whompID.traceSubject == 1, "stable Whomp surface slot")
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [whompID: SM64WhompTickInput(distanceToMario: 400)]
        )
        guard let bridgeEffect = bridgeTick.effects.first(where: { $0.objectID == whompID }) else {
            preconditionFailure("Whomp bridge effect missing")
        }
        require(bridgeEffect.action == .chase && bridgeEffect.effects.contains(.chase),
                "Whomp bridge chase")
        fingerprint = hashEffect(fingerprint, bridgeEffect)

        let bridgePound = bridge.tick(
            state: engineState,
            inputs: [whompID: SM64WhompTickInput(distanceToMario: 200)]
        )
        require(bridgePound.effects.first?.action == .pound, "Whomp bridge pound admission")
        _ = bridge.tick(
            state: engineState,
            inputs: [whompID: SM64WhompTickInput(animationNearEnd: true)]
        )

        var finalDeletion: SM64WhompSchedulerTickResult?
        for _ in 0..<64 {
            guard let state = bridge.state(for: whompID) else { break }
            let input: SM64WhompTickInput
            switch state.action {
            case .initialize:
                input = SM64WhompTickInput(distanceToMario: 400)
            case .chase:
                input = SM64WhompTickInput(distanceToMario: 200)
            case .pound:
                input = SM64WhompTickInput(animationNearEnd: true)
            case .fall:
                input = SM64WhompTickInput()
            case .landed:
                input = SM64WhompTickInput(onGround: true)
            case .onGround:
                input = SM64WhompTickInput(marioGroundPound: true, marioOnPlatform: true)
            case .death:
                input = SM64WhompTickInput()
            case .turn, .returnHome, .bossWait:
                input = SM64WhompTickInput(distanceToMario: 200)
            }
            let result = bridge.tick(state: engineState, inputs: [whompID: input])
            if result.scheduler.unloaded.contains(whompID) {
                finalDeletion = result
                break
            }
        }
        require(
            finalDeletion?.scheduler.unloaded == [whompID] &&
                bridge.deliveryLog.contains { $0.deleted == [whompID] },
            "Whomp deletion must route through owner thread"
        )

        print(String(format: "whompObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Whomp object bridge smoke passed")
    }
}
