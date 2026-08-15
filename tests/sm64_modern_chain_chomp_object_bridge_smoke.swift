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

private func hashState(_ initial: UInt64, _ result: SM64ChainChompTickResult) -> UInt64 {
    let s = result.state
    var values: [UInt64] = [
        UInt64(result.effects.rawValue), UInt64(s.action.rawValue), UInt64(s.subAction.rawValue),
        UInt64(s.releaseStatus.rawValue), UInt64(s.homeX.bitPattern), UInt64(s.homeY.bitPattern), UInt64(s.homeZ.bitPattern),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(s.pivotX.bitPattern), UInt64(s.pivotY.bitPattern), UInt64(s.pivotZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)), UInt64(UInt16(bitPattern: s.facePitch)),
        UInt64(s.forwardVelocity.bitPattern), UInt64(s.velocityY.bitPattern), UInt64(s.gravity.bitPattern),
        UInt64(s.maxDistFromPivotPerPart.bitPattern), UInt64(s.maxDistBetweenParts.bitPattern),
        UInt64(s.distanceToPivot.bitPattern), UInt64(UInt16(bitPattern: s.targetPitch)),
        s.restrictedByChain ? 1 : 0, UInt64(s.elasticVelocity.bitPattern), s.hitGate ? 1 : 0,
        UInt64(s.numLunges), s.hidden ? 1 : 0, s.tangible ? 1 : 0, s.markedForDeletion ? 1 : 0,
        UInt64(s.timer)
    ]
    for segment in s.segments {
        values += [UInt64(segment.x.bitPattern), UInt64(segment.y.bitPattern), UInt64(segment.z.bitPattern)]
    }
    return values.reduce(initial, hashU64)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64ChainChompObjectEffectRecord) -> UInt64 {
    let values: [UInt64] = [
        UInt64(effect.objectID.traceSubject), UInt64(effect.kind.rawValue), UInt64(effect.index),
        UInt64(effect.effects.rawValue), UInt64(effect.action?.rawValue ?? 255), effect.markedForDeletion ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernChainChompObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var chomp = SM64ChainChompState(homeX: 10, homeY: 200, homeZ: 30)

        let far = SM64ChainChompKernel.tick(
            SM64ChainChompTickInput(distanceToMario: 4_000), state: &chomp
        )
        require(far.state.action == .uninitialized, "Chain Chomp far gate")
        fingerprint = hashState(fingerprint, far)

        let allocate = SM64ChainChompKernel.tick(
            SM64ChainChompTickInput(distanceToMario: 2_000), state: &chomp
        )
        require(allocate.state.action == .move && allocate.effects.contains(.allocateChain), "Chain Chomp allocation")
        fingerprint = hashState(fingerprint, allocate)

        chomp.timer = 41
        let lunge = SM64ChainChompKernel.tick(
            SM64ChainChompTickInput(distanceToMario: 300, angleToMario: 0, onGround: true, animationAtFrame: true),
            state: &chomp
        )
        require(lunge.state.subAction == .lunge && lunge.effects.contains(.lunge), "Chain Chomp lunge")
        fingerprint = hashState(fingerprint, lunge)

        let attack = SM64ChainChompKernel.tick(
            SM64ChainChompTickInput(distanceToMario: 300, angleToMario: 0, onGround: false, attacked: true),
            state: &chomp
        )
        require(attack.effects.contains(.attackStretch) && attack.state.targetPitch == -0x3000, "Chain Chomp attack stretch")
        fingerprint = hashState(fingerprint, attack)

        let unload = SM64ChainChompKernel.tick(
            SM64ChainChompTickInput(distanceToMario: 5_000), state: &chomp
        )
        require(unload.state.action == .unloadChain && unload.effects.contains(.unload), "Chain Chomp unload")
        fingerprint = hashState(fingerprint, unload)

        let engineState = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64ChainChompObjectBridge()
        let chompID = try bridge.spawnChainChomp(in: engineState, homeX: 5, homeY: 200, homeZ: 15)
        require(chompID.traceSubject == 1, "stable Chain Chomp slot")
        let tick = bridge.tick(
            state: engineState,
            inputs: [chompID: SM64ChainChompTickInput(distanceToMario: 200, angleToMario: 0)]
        )
        require(tick.effects.count == 6 && bridge.registeredIDs.count == 6, "Chain Chomp child allocation")
        for effect in tick.effects { fingerprint = hashEffect(fingerprint, effect) }

        print(String(format: "chainChompObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Chain Chomp object bridge smoke passed")
    }
}
