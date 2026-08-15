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

private func hash(_ initial: UInt64, _ values: [UInt64]) -> UInt64 {
    values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashParent(_ initial: UInt64, _ result: SM64BouncingFireballTickResult) -> UInt64 {
    let state = result.state
    return hash(initial, [
        UInt64(result.effects.rawValue), UInt64(state.action.rawValue), UInt64(state.timer),
        UInt64(state.randomOffset.bitPattern), UInt64(state.velocityY.bitPattern),
        UInt64(state.forwardVelocity.bitPattern), UInt64(state.animState),
        state.tangible ? 1 : 0, state.markedForDeletion ? 1 : 0,
        UInt64((result.flameScale ?? -1).bitPattern)
    ])
}

private func hashFlame(_ initial: UInt64, _ result: SM64BouncingFireballFlameTickResult) -> UInt64 {
    let state = result.state
    return hash(initial, [
        UInt64(result.effects.rawValue), UInt64(state.action.rawValue), UInt64(state.timer),
        UInt64(state.velocityY.bitPattern), UInt64(state.forwardVelocity.bitPattern),
        state.markedForDeletion ? 1 : 0
    ])
}

@main
enum SM64ModernBouncingFireballSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var parent = SM64BouncingFireballState()
        let far = SM64BouncingFireballKernel.tick(
            SM64BouncingFireballTickInput(distanceToMario: 2_500), state: &parent
        )
        require(far.state.action == .waiting, "fireball distance gate")
        let farValues: [UInt64] = [UInt64(far.effects.rawValue), UInt64(far.state.action.rawValue), UInt64(far.state.timer), UInt64(far.state.randomOffset.bitPattern), UInt64(far.state.velocityY.bitPattern), UInt64(far.state.forwardVelocity.bitPattern), UInt64(far.state.animState), far.state.tangible ? 1 : 0, far.state.markedForDeletion ? 1 : 0, UInt64((far.flameScale ?? -1).bitPattern)]
        fingerprint = hash(fingerprint, farValues)

        let activate = SM64BouncingFireballKernel.tick(
            SM64BouncingFireballTickInput(distanceToMario: 1_000), state: &parent
        )
        require(activate.state.action == .spawnFlame && activate.effects.contains(.activate), "fireball activation")
        let activateValues: [UInt64] = [UInt64(activate.effects.rawValue), UInt64(activate.state.action.rawValue), UInt64(activate.state.timer), UInt64(activate.state.randomOffset.bitPattern), UInt64(activate.state.velocityY.bitPattern), UInt64(activate.state.forwardVelocity.bitPattern), UInt64(activate.state.animState), activate.state.tangible ? 1 : 0, activate.state.markedForDeletion ? 1 : 0, UInt64((activate.flameScale ?? -1).bitPattern)]
        fingerprint = hash(fingerprint, activateValues)

        parent.timer = 0
        let flame = SM64BouncingFireballKernel.tick(
            SM64BouncingFireballTickInput(distanceToMario: 1_000), state: &parent
        )
        require(flame.effects.contains([.spawnFlame, .tangible]) && flame.flameScale == 5, "fireball flame spawn")
        let flameValues: [UInt64] = [UInt64(flame.effects.rawValue), UInt64(flame.state.action.rawValue), UInt64(flame.state.timer), UInt64(flame.state.randomOffset.bitPattern), UInt64(flame.state.velocityY.bitPattern), UInt64(flame.state.forwardVelocity.bitPattern), UInt64(flame.state.animState), flame.state.tangible ? 1 : 0, flame.state.markedForDeletion ? 1 : 0, UInt64((flame.flameScale ?? -1).bitPattern)]
        fingerprint = hash(fingerprint, flameValues)

        parent.action = .cycle
        parent.timer = 101
        let expire = SM64BouncingFireballKernel.tick(
            SM64BouncingFireballTickInput(surfaceContact: true), state: &parent
        )
        require(expire.effects.contains(.markForDeletion), "fireball surface deletion")
        let expireValues: [UInt64] = [UInt64(expire.effects.rawValue), UInt64(expire.state.action.rawValue), UInt64(expire.state.timer), UInt64(expire.state.randomOffset.bitPattern), UInt64(expire.state.velocityY.bitPattern), UInt64(expire.state.forwardVelocity.bitPattern), UInt64(expire.state.animState), expire.state.tangible ? 1 : 0, expire.state.markedForDeletion ? 1 : 0, UInt64((expire.flameScale ?? -1).bitPattern)]
        fingerprint = hash(fingerprint, expireValues)

        var child = SM64BouncingFireballFlameState()
        let childLand = SM64BouncingFireballFlameKernel.tick(
            SM64BouncingFireballFlameTickInput(landed: true), state: &child
        )
        require(childLand.state.action == .bouncing && childLand.effects.contains(.landed), "fireball child land")
        let childLandValues: [UInt64] = [UInt64(childLand.effects.rawValue), UInt64(childLand.state.action.rawValue), UInt64(childLand.state.timer), UInt64(childLand.state.velocityY.bitPattern), UInt64(childLand.state.forwardVelocity.bitPattern), childLand.state.markedForDeletion ? 1 : 0]
        fingerprint = hash(fingerprint, childLandValues)
        child.timer = 101
        let childExpire = SM64BouncingFireballFlameKernel.tick(
            SM64BouncingFireballFlameTickInput(surfaceContact: true), state: &child
        )
        require(childExpire.effects.contains(.markForDeletion), "fireball child deletion")
        let childExpireValues: [UInt64] = [UInt64(childExpire.effects.rawValue), UInt64(childExpire.state.action.rawValue), UInt64(childExpire.state.timer), UInt64(childExpire.state.velocityY.bitPattern), UInt64(childExpire.state.forwardVelocity.bitPattern), childExpire.state.markedForDeletion ? 1 : 0]
        fingerprint = hash(fingerprint, childExpireValues)

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64BouncingFireballObjectBridge()
        let id = try bridge.spawnFireball(in: engineState, position: .init(x: 10, y: 20, z: 30))
        _ = bridge.tick(state: engineState, inputs: [id: SM64BouncingFireballTickInput(distanceToMario: 1_000)])
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [id: SM64BouncingFireballTickInput(distanceToMario: 1_000)]
        )
        require(bridgeTick.effects.contains { $0.objectID == id && $0.effects.contains(.spawnFlame) }, "fireball bridge child spawn")
        require(bridge.registeredIDs.count == 2, "fireball bridge stable child")
        for effect in bridgeTick.effects {
            let bridgeValues: [UInt64] = [
                UInt64(effect.objectID.traceSubject), UInt64(effect.kind.rawValue),
                UInt64(effect.action), UInt64(effect.effects.rawValue),
                UInt64(effect.spawnedChildren.count), UInt64(effect.flameScale.bitPattern),
                effect.markedForDeletion ? 1 : 0
            ]
            fingerprint = hash(fingerprint, bridgeValues)
        }

        var routedDeletionFrames = 0
        for _ in 0..<130 {
            _ = bridge.tick(
                state: engineState,
                inputs: [id: SM64BouncingFireballTickInput(
                    distanceToMario: 1_000,
                    surfaceContact: true
                )]
            )
            routedDeletionFrames += bridge.deliveryLog.filter { $0.deleted == [id] }.count
            if engineState.objects.record(for: id) == nil { break }
        }
        require(routedDeletionFrames == 1, "fireball deletion routed through owner thread")
        require(engineState.objects.record(for: id) == nil, "fireball end-of-frame unload")
        fingerprint = hash(fingerprint, [
            UInt64(routedDeletionFrames),
            UInt64(bridge.registeredIDs.count),
            engineState.objects.record(for: id) == nil ? 1 : 0
        ])

        print(String(format: "bouncingFireballFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern bouncing fireball smoke passed")
    }
}
