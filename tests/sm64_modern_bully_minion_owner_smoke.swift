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

private func hashPosition(_ initial: UInt64, _ position: SM64ObjectVector3) -> UInt64 {
    var hash = hashU64(initial, UInt64(position.x.bitPattern))
    hash = hashU64(hash, UInt64(position.y.bitPattern))
    return hashU64(hash, UInt64(position.z.bitPattern))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBullyMinionOwnerSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64BullyObjectBridge()
        let parentID = try bridge.spawnBigBullyWithMinions(in: engine)
        let minions = bridge.minionIDs(for: parentID)
        require(minions.count == 3, "three source minions")
        require(engine.objects.record(for: minions[0])?.position == SM64ObjectVector3(x: 4_454, y: 307, z: -5_426), "minion one transform")
        require(engine.objects.record(for: minions[1])?.position == SM64ObjectVector3(x: 3_840, y: 307, z: -6_041), "minion two transform")
        require(engine.objects.record(for: minions[2])?.position == SM64ObjectVector3(x: 3_226, y: 307, z: -5_426), "minion three transform")

        var deathInputs: [SM64ObjectID: SM64BullyTickInput] = [:]
        for minion in minions {
            var state = bridge.state(for: minion)!
            state.action = .lavaDeath
            require(bridge.setState(state, for: minion, in: engine.objects), "minion death state")
            deathInputs[minion] = SM64BullyTickInput(floorCollisionFlags: 1)
        }
        deathInputs[parentID] = SM64BullyTickInput(floorCollisionFlags: 1)
        let deathTick = bridge.tick(state: engine, inputs: deathInputs, presentEffects: true)
        require(deathTick.effects.count == 4, "minion death plus parent effect count")
        require(deathTick.scheduler.unloaded.count == 3, "minion unload count")
        require(bridge.minionIDs(for: parentID).isEmpty, "minion mapping cleanup")
        require(bridge.state(for: parentID)?.knockbackCounter == 3, "parent minion knockout count")
        require(bridge.deliveryLog.filter { !$0.deleted.isEmpty }.count == 3, "minion deletion delivery")

        var parent = bridge.state(for: parentID)!
        parent.timer = 91
        require(bridge.setState(parent, for: parentID, in: engine.objects), "parent activation timer")
        let activateTick = bridge.tick(
            state: engine,
            inputs: [parentID: SM64BullyTickInput(floorCollisionFlags: 1)],
            presentEffects: true
        )
        guard let activateEffect = activateTick.effects.first else {
            preconditionFailure("parent activation effect missing")
        }
        require(activateEffect.action == .activateAndFall, "parent activation action")
        require(activateEffect.effects.contains(.music), "puzzle jingle intent")
        require(activateEffect.presentedEffects.map(\.kind) == [.music], "puzzle jingle presentation")

        let landTick = bridge.tick(
            state: engine,
            inputs: [parentID: SM64BullyTickInput(floorCollisionFlags: 0x9)],
            presentEffects: true
        )
        guard let landEffect = landTick.effects.first else {
            preconditionFailure("parent landing effect missing")
        }
        require(landEffect.action == .patrol, "parent landing action")
        require(landEffect.effects.contains([.sound, .cameraShake, .mist, .tangible]), "parent landing effects")
        require(landEffect.presentedEffects.map(\.kind) == [.sound, .particle, .cameraShake], "parent landing presentation")
        require(bridge.state(for: parentID)?.tangible == true, "parent tangible after activation")
        require(bridge.state(for: parentID)?.invisible == false, "parent visible after activation")

        var fingerprint = fnvOffset
        fingerprint = hashU64(fingerprint, UInt64(parentID.traceSubject))
        for minion in minions {
            fingerprint = hashU64(fingerprint, UInt64(minion.traceSubject))
        }
        for effect in deathTick.effects {
            fingerprint = hashU64(fingerprint, UInt64(effect.objectID.traceSubject))
            fingerprint = hashU64(fingerprint, UInt64(effect.effects.rawValue))
            fingerprint = hashU64(fingerprint, UInt64(effect.action.rawValue))
            fingerprint = hashU64(fingerprint, effect.markedForDeletion ? 1 : 0)
            fingerprint = hashU64(fingerprint, UInt64(effect.presentedEffects.count))
            for intent in effect.presentedEffects {
                fingerprint = hashU64(fingerprint, UInt64(intent.kind.rawValue))
            }
        }
        fingerprint = hashU64(fingerprint, UInt64(bridge.state(for: parentID)!.knockbackCounter))
        fingerprint = hashU64(fingerprint, UInt64(activateEffect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(activateEffect.action.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(activateEffect.presentedEffects.first!.kind.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(landEffect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(landEffect.action.rawValue))
        for intent in landEffect.presentedEffects {
            fingerprint = hashU64(fingerprint, UInt64(intent.kind.rawValue))
        }
        let parentRecord = engine.objects.record(for: parentID)!
        fingerprint = hashPosition(fingerprint, parentRecord.position)
        fingerprint = hashU64(fingerprint, parentRecord.action >= 0 ? UInt64(parentRecord.action) : 0)
        fingerprint = hashU64(fingerprint, parentRecord.intangibleTimer >= 0 ? UInt64(parentRecord.intangibleTimer) : 0)

        print(String(format: "bullyMinionOwnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bully minion owner smoke passed")
    }
}
