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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func hashPosition(_ initial: UInt64, _ position: SM64ObjectVector3?) -> UInt64 {
    guard let position else { return hashU64(initial, 0) }
    var hash = hashU64(initial, 1)
    hash = hashFloat(hash, position.x)
    hash = hashFloat(hash, position.y)
    return hashFloat(hash, position.z)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBullyRewardPresentationSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 32)
        let bridge = SM64BullyObjectBridge()
        let smallID = try bridge.spawnBully(in: engine, size: .small, homeY: 100)
        let chillID = try bridge.spawnBully(in: engine, size: .big, subtype: .chill, homeY: 1_100)
        let genericID = try bridge.spawnBully(in: engine, size: .big, subtype: .generic, homeY: 1_100)

        var small = bridge.state(for: smallID)!
        small.action = .lavaDeath
        require(bridge.setState(small, for: smallID, in: engine.objects), "small reward state")
        var chill = bridge.state(for: chillID)!
        chill.action = .lavaDeath
        require(bridge.setState(chill, for: chillID, in: engine.objects), "Chief Chilly reward state")
        var generic = bridge.state(for: genericID)!
        generic.action = .lavaDeath
        require(bridge.setState(generic, for: genericID, in: engine.objects), "generic reward state")

        let tick = bridge.tick(
            state: engine,
            inputs: [
                smallID: SM64BullyTickInput(floorCollisionFlags: 1),
                chillID: SM64BullyTickInput(floorCollisionFlags: 1),
                genericID: SM64BullyTickInput(floorCollisionFlags: 1)
            ],
            presentEffects: true,
            spawnRewards: true,
            spawnBridge: true
        )
        require(tick.effects.count == 3, "Bully reward effect count")
        guard let smallEffect = tick.effects.first(where: { $0.objectID == smallID }),
              let chillEffect = tick.effects.first(where: { $0.objectID == chillID }),
              let genericEffect = tick.effects.first(where: { $0.objectID == genericID }) else {
            preconditionFailure("Bully reward effects missing")
        }
        require(smallEffect.coinPosition == SM64ObjectVector3(x: 0, y: 410, z: 0), "coin source position")
        require(chillEffect.starPosition == SM64ObjectVector3(x: 130, y: 1_600, z: -4_335), "Chief Chilly star position")
        require(genericEffect.starPosition == SM64ObjectVector3(x: 0, y: 950, z: -6_800), "generic Bully star position")
        require(genericEffect.bridgePosition == SM64ObjectVector3(x: 0, y: 154, z: -5_631), "generic Bully bridge position")
        require(smallEffect.spawnedChildren.count == 1, "coin child spawn")
        require(chillEffect.spawnedChildren.count == 1, "Chief Chilly star child spawn")
        require(genericEffect.spawnedChildren.count == 2, "generic reward/bridge child spawn")
        require(smallEffect.presentedEffects.map(\.kind) == [.sound, .particle], "coin presentation ordering")
        require(chillEffect.presentedEffects.map(\.kind) == [.particle, .star], "Chief Chilly presentation ordering")
        require(genericEffect.presentedEffects.map(\.kind) == [.particle, .star], "generic presentation ordering")
        require(bridge.deliveryLog.count == 3, "Bully reward delivery count")
        require(bridge.deliveryLog.allSatisfy { $0.deleted.count == 1 }, "Bully parent deletion delivery")

        var fingerprint = fnvOffset
        for effect in tick.effects {
            fingerprint = hashU64(fingerprint, UInt64(effect.objectID.traceSubject))
            fingerprint = hashU64(fingerprint, UInt64(effect.size.rawValue))
            fingerprint = hashU64(fingerprint, UInt64(effect.effects.rawValue))
            fingerprint = hashU64(fingerprint, UInt64(effect.action.rawValue))
            fingerprint = hashU64(fingerprint, effect.markedForDeletion ? 1 : 0)
            fingerprint = hashPosition(fingerprint, effect.coinPosition)
            fingerprint = hashPosition(fingerprint, effect.starPosition)
            fingerprint = hashPosition(fingerprint, effect.bridgePosition)
            fingerprint = hashU64(fingerprint, UInt64(effect.spawnedChildren.count))
            for child in effect.spawnedChildren {
                fingerprint = hashU64(fingerprint, UInt64(child.traceSubject))
                if let record = engine.objects.record(for: child) {
                    fingerprint = hashPosition(fingerprint, record.position)
                    fingerprint = hashU64(fingerprint, UInt64(record.model))
                    fingerprint = hashU64(fingerprint, UInt64(record.parent.traceSubject))
                } else {
                    fingerprint = hashU64(fingerprint, 0)
                }
            }
            fingerprint = hashU64(fingerprint, UInt64(effect.presentedEffects.count))
            for intent in effect.presentedEffects {
                fingerprint = hashU64(fingerprint, UInt64(intent.kind.rawValue))
                fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(intent.value)))
                fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(intent.auxiliary)))
            }
        }
        for delivery in bridge.deliveryLog {
            fingerprint = hashU64(fingerprint, UInt64(delivery.delivered.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.presented.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.spawned.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.deleted.count))
            fingerprint = hashU64(fingerprint, UInt64(delivery.rejected.count))
        }

        print(String(format: "bullyRewardPresentationFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bully reward presentation smoke passed")
    }
}
