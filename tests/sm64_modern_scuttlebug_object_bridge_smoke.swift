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

private func hashBug(_ initial: UInt64, _ result: SM64ScuttlebugTickResult) -> UInt64 {
    let s = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(s.subAction.rawValue))
    hash = hashU64(hash, UInt64(s.homeX.bitPattern))
    hash = hashU64(hash, UInt64(s.homeY.bitPattern))
    hash = hashU64(hash, UInt64(s.homeZ.bitPattern))
    hash = hashU64(hash, UInt64(s.positionX.bitPattern))
    hash = hashU64(hash, UInt64(s.positionY.bitPattern))
    hash = hashU64(hash, UInt64(s.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: s.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: s.targetYaw)))
    hash = hashU64(hash, UInt64(s.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(s.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(s.attackWindow))
    hash = hashU64(hash, UInt64(s.alertTimer))
    hash = hashU64(hash, UInt64(s.moveFlags))
    hash = hashU64(hash, UInt64(s.animationState))
    hash = hashU64(hash, UInt64(s.timer))
    hash = hashU64(hash, s.tangible ? 1 : 0)
    return hashU64(hash, s.markedForDeletion ? 1 : 0)
}

private func hashSpawner(_ initial: UInt64, _ result: SM64ScuttlebugSpawnerTickResult) -> UInt64 {
    let s = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(s.action))
    hash = hashU64(hash, UInt64(s.timer))
    hash = hashU64(hash, s.childActive ? 1 : 0)
    hash = hashU64(hash, UInt64(s.childUnknown))
    return hashU64(hash, s.markedForDeletion ? 1 : 0)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64ScuttlebugObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.kind.rawValue))
    hash = hashU64(hash, UInt64(effect.action?.rawValue ?? 255))
    hash = hashU64(hash, UInt64(effect.effects.rawValue))
    hash = hashU64(hash, UInt64(effect.spawnedChild?.traceSubject ?? 0))
    return hashU64(hash, effect.markedForDeletion ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernScuttlebugObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var bug = SM64ScuttlebugState(homeX: 100, homeY: 200, homeZ: 300)
        let landed = SM64ScuttlebugKernel.tick(
            SM64ScuttlebugTickInput(moveFlags: SM64ScuttlebugKernel.onGroundMask),
            state: &bug
        )
        require(landed.state.subAction == .chase && landed.state.homeX == 100, "scuttlebug landing")
        fingerprint = hashBug(fingerprint, landed)

        let alert = SM64ScuttlebugKernel.tick(
            SM64ScuttlebugTickInput(
                moveFlags: SM64ScuttlebugKernel.onGroundMask,
                distanceToMario: 300,
                angleToMario: 0x200
            ),
            state: &bug
        )
        require(alert.effects.contains(.alert) && alert.state.velocityY == 20, "scuttlebug alert")
        fingerprint = hashBug(fingerprint, alert)

        let edge = SM64ScuttlebugKernel.tick(
            SM64ScuttlebugTickInput(
                moveFlags: SM64ScuttlebugKernel.onGroundMask | SM64ScuttlebugKernel.hitEdgeFlag,
                angleToMario: 0x200
            ),
            state: &bug
        )
        require(edge.state.subAction == .turn && edge.effects.contains(.wallOrEdge), "scuttlebug edge turn")
        fingerprint = hashBug(fingerprint, edge)

        bug.moveYaw = bug.targetYaw
        let turned = SM64ScuttlebugKernel.tick(
            SM64ScuttlebugTickInput(moveFlags: SM64ScuttlebugKernel.onGroundMask),
            state: &bug
        )
        require(turned.state.subAction == .chase, "scuttlebug return chase")
        fingerprint = hashBug(fingerprint, turned)

        var attacked = SM64ScuttlebugState()
        attacked.subAction = .chase
        let attack = SM64ScuttlebugKernel.tick(
            SM64ScuttlebugTickInput(attacked: true),
            state: &attacked
        )
        require(attack.state.markedForDeletion && attack.effects.contains(.coin), "scuttlebug attack")
        fingerprint = hashBug(fingerprint, attack)

        var spawner = SM64ScuttlebugSpawnerState()
        spawner.timer = 31
        let spawned = SM64ScuttlebugKernel.tickSpawner(
            SM64ScuttlebugSpawnerTickInput(distanceToMario: 1_000),
            state: &spawner
        )
        require(spawned.state.action == 1 && spawned.state.childActive
                && spawned.effects.contains(.spawnScuttlebug), "scuttlebug spawn")
        fingerprint = hashSpawner(fingerprint, spawned)

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64ScuttlebugObjectBridge()
        let spawnerID = try bridge.spawnSpawner(in: engineState)
        require(spawnerID.traceSubject == 1, "stable scuttlebug spawner slot")
        var spawnedEffect: SM64ScuttlebugObjectEffectRecord?
        for _ in 0..<35 where spawnedEffect == nil {
            let tick = bridge.tick(
                state: engineState,
                spawnerInputs: [spawnerID: SM64ScuttlebugSpawnerTickInput(distanceToMario: 1_000)]
            )
            spawnedEffect = tick.effects.first(where: {
                $0.objectID == spawnerID && $0.spawnedChild != nil
            })
        }
        guard let spawnedEffect else { preconditionFailure("scuttlebug bridge spawn missing") }
        require(spawnedEffect.spawnedChild?.traceSubject == 2, "stable scuttlebug child slot")
        fingerprint = hashEffect(fingerprint, spawnedEffect)

        print(String(format: "scuttlebugObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Scuttlebug object bridge smoke passed")
    }
}
