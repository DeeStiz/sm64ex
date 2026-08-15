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

private func hashValues(_ initial: UInt64, _ values: [UInt64]) -> UInt64 {
    values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernChainChompReleaseSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var post = SM64ChainChompPostState(homeY: 200)

        let pound = SM64ChainChompPostKernel.tick(
            SM64ChainChompPostTickInput(marioGroundPounding: true), state: &post
        )
        require(pound.effects == [.poundSound], "wooden post pound admission")
        require(pound.state.speedY == -70, "wooden post pound speed")
        fingerprint = hashValues(fingerprint, [
            UInt64(pound.effects.rawValue), UInt64(pound.state.speedY.bitPattern),
            UInt64(pound.state.offsetY.bitPattern), UInt64(pound.state.timer)
        ])

        let drop = SM64ChainChompPostKernel.tick(
            SM64ChainChompPostTickInput(distanceToMario: 500), state: &post
        )
        require(drop.state.offsetY == -45 && drop.effects.contains(.updatePosition), "wooden post first drop")
        fingerprint = hashValues(fingerprint, [
            UInt64(drop.effects.rawValue), UInt64(drop.state.speedY.bitPattern),
            UInt64(drop.state.offsetY.bitPattern), UInt64(drop.state.timer)
        ])

        post.offsetY = -150
        post.speedY = -70
        post.marioPounding = true
        let release = SM64ChainChompPostKernel.tick(
            SM64ChainChompPostTickInput(distanceToMario: 500), state: &post
        )
        require(release.state.offsetY == -190 && release.effects.contains(.releaseChain), "wooden post release")
        fingerprint = hashValues(fingerprint, [
            UInt64(release.effects.rawValue), UInt64(release.state.speedY.bitPattern),
            UInt64(release.state.offsetY.bitPattern), release.state.parentIsSelf ? 1 : 0,
            UInt64(release.state.timer)
        ])

        var coins = SM64ChainChompPostState(homeY: 0)
        coins.totalMarioAngle = 0x30_000
        coins.timer = 10
        let coinResult = SM64ChainChompPostKernel.tick(
            SM64ChainChompPostTickInput(distanceToMario: 100, angleToMario: 1), state: &coins
        )
        require(coinResult.effects.contains(.spawnCoins), "wooden post coin orbit")
        require(coinResult.state.numLootCoins == 0 && coinResult.state.respawnInfoBits == 1, "wooden post coin fence")
        fingerprint = hashValues(fingerprint, [
            UInt64(coinResult.effects.rawValue), UInt64(coinResult.state.numLootCoins),
            UInt64(coinResult.state.respawnInfoBits), UInt64(coinResult.state.timer)
        ])

        var gate = SM64ChainChompGateState()
        let gateResult = SM64ChainChompGateKernel.tick(hitGate: true, state: &gate)
        require(gateResult.effects.rawValue == 0x1F && gateResult.state.markedForDeletion, "gate destruction effects")
        fingerprint = hashValues(fingerprint, [
            UInt64(gateResult.effects.rawValue), gateResult.state.markedForDeletion ? 1 : 0
        ])

        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let parent = try engineState.spawnObject(in: .generalActor, model: 0x66, behaviorIdentity: 0x706172656E74)
        let bridge = SM64ChainChompReleaseObjectBridge()
        let postID = try bridge.spawnWoodenPost(in: engineState, parent: parent, homeY: 200)
        let gateID = try bridge.spawnGate(in: engineState, parent: parent, position: .init(x: 10, y: 20, z: 30))
        require(postID.traceSubject == 2 && gateID.traceSubject == 3, "release object stable IDs")
        let bridgeTick = bridge.tick(
            state: engineState,
            postInputs: [postID: SM64ChainChompPostTickInput(marioGroundPounding: true)],
            gateHits: [gateID: true]
        )
        require(bridgeTick.effects.count == 2, "release bridge effect count")
        require(bridgeTick.effects.contains { $0.kind == .woodenPost && $0.effects.contains(.poundSound) }, "release bridge post effect")
        require(bridgeTick.effects.contains { $0.kind == .gate && $0.markedForDeletion }, "release bridge gate effect")
        require(engineState.objects.record(for: gateID)?.activeFlags ?? 0 & SM64ObjectPool.activeFlagActive == 0, "gate owner deletion")
        for effect in bridgeTick.effects {
            fingerprint = hashValues(fingerprint, [
                UInt64(effect.objectID.traceSubject), UInt64(effect.kind.rawValue),
                UInt64(effect.effects.rawValue), UInt64(effect.spawnedCoins),
                effect.markedForDeletion ? 1 : 0
            ])
        }

        print(String(format: "chainChompReleaseFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Chain Chomp release smoke passed")
    }
}
