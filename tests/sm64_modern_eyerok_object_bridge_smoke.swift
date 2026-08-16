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

private func hashEffect(_ initial: UInt64, _ effect: SM64EyerokObjectEffectRecord) -> UInt64 {
    var hash = hashU64(initial, UInt64(effect.objectID.traceSubject))
    hash = hashU64(hash, UInt64(effect.parentID?.traceSubject ?? 0))
    hash = hashU64(hash, UInt64(effect.kind.rawValue))
    hash = hashU64(hash, UInt64(bitPattern: Int64(effect.side)))
    hash = hashU64(hash, UInt64(effect.bossAction?.rawValue ?? 0xff))
    hash = hashU64(hash, UInt64(effect.handAction?.rawValue ?? 0xff))
    hash = hashU64(hash, UInt64(effect.bossEffects.rawValue))
    hash = hashU64(hash, UInt64(effect.handEffects.rawValue))
    hash = hashU64(hash, UInt64(effect.starPosition == nil ? 0 : 1))
    hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
    for child in effect.spawnedChildren {
        hash = hashU64(hash, UInt64(child.traceSubject))
    }
    hash = hashU64(hash, UInt64(effect.presentedEffects.count))
    for intent in effect.presentedEffects {
        hash = hashU64(hash, UInt64(intent.kind.rawValue))
        hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernEyerokObjectBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64EyerokObjectBridge()
        let bossID = try bridge.spawnBoss(in: engine, homeX: 10, homeY: 20, homeZ: 30)

        let first = bridge.tick(state: engine)
        guard let firstBoss = first.effects.first else {
            preconditionFailure("Eyerok boss owner result missing")
        }
        require(firstBoss.kind == .boss, "Eyerok boss record kind")
        require(firstBoss.bossEffects == .spawnHands, "Eyerok owner hand-spawn effect")
        require(firstBoss.spawnedChildren.count == 2, "Eyerok owner hand count")
        require(bridge.registeredHandIDs.count == 2, "Eyerok owner hand registration")

        let handIDs = bridge.registeredHandIDs
        let leftID = handIDs[0]
        let rightID = handIDs[1]
        for handID in handIDs {
            guard let record = engine.objects.record(for: handID) else {
                preconditionFailure("Eyerok hand record missing")
            }
            require(record.parent == bossID, "Eyerok hand parent generation")
            require(record.objectList == .generalActor, "Eyerok hand list")
            require(record.hitboxRadius == SM64EyerokObjectBridge.handHitboxRadius,
                    "Eyerok hand hitbox radius")
        }

        var boss = try XCTState(bridge.bossState(for: bossID), message: "Eyerok boss state missing")
        boss.action = .fight
        boss.numHands = 2
        boss.activeHand = 1
        boss.busyHand = 0
        require(bridge.setBossState(boss, for: bossID, in: engine.objects), "Eyerok boss state set")

        guard var right = bridge.handState(for: rightID) else {
            preconditionFailure("Eyerok right hand state missing")
        }
        right.action = .open
        require(bridge.setHandState(right, for: rightID, in: engine.objects), "Eyerok right hand state set")
        let openTick = bridge.tick(
            state: engine,
            handInputs: [rightID: SM64EyerokHandInput(
                parentAction: .fight,
                angleToMario: 0x2000,
                animationEnded: true
            )],
            presentEffects: true
        )
        guard let openEffect = openTick.effects.first(where: { $0.objectID == rightID }),
              let rightRecord = engine.objects.record(for: rightID) else {
            preconditionFailure("Eyerok open owner result missing")
        }
        require(openEffect.kind == .hand && openEffect.handAction == .showEye,
                "Eyerok open-to-eye owner action")
        require(openEffect.handEffects == .openAnimation, "Eyerok open animation intent")
        require(rightRecord.interactionType == SM64EyerokObjectBridge.handHitboxInteractType,
                "Eyerok eye collision admission")

        guard var attackHand = bridge.handState(for: rightID) else {
            preconditionFailure("Eyerok attack state missing")
        }
        attackHand.health = 1
        attackHand.action = .showEye
        require(bridge.setHandState(attackHand, for: rightID, in: engine.objects),
                "Eyerok attack state set")
        let attackTick = bridge.tick(
            state: engine,
            handInputs: [rightID: SM64EyerokHandInput(
                parentAction: .fight,
                angleToMario: -0x4000,
                receivedAttack: true
            )],
            presentEffects: true
        )
        guard let attackEffect = attackTick.effects.first(where: { $0.objectID == rightID }),
              let attackBoss = bridge.bossState(for: bossID),
              let attackRecord = engine.objects.record(for: rightID) else {
            preconditionFailure("Eyerok attack owner result missing")
        }
        require(attackEffect.handAction == .die, "Eyerok lethal owner action")
        require(attackEffect.handEffects.contains(.shortSound), "Eyerok attack effect")
        require(attackEffect.presentedEffects.map(\.kind) == [.sound],
                "Eyerok attack presentation")
        require(attackBoss.numHands == 1, "Eyerok parent hand decrement")
        require(attackRecord.health == 0, "Eyerok owner health sync")
        require(bridge.parentID(for: rightID) == bossID, "Eyerok parent lookup")
        _ = leftID

        var fingerprint = hashEffect(fnvOffset, firstBoss)
        fingerprint = hashEffect(fingerprint, openEffect)
        fingerprint = hashEffect(fingerprint, attackEffect)
        print(String(format: "eyerokObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Eyerok owner bridge smoke passed")
    }

    private static func XCTState<T>(_ value: T?, message: String) throws -> T {
        guard let value else { throw NSError(domain: "SM64Modern", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
        return value
    }
}
