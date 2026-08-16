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

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64DecorativePendulumSchedulerTickResult,
    objectID: SM64ObjectID,
    record: SM64ObjectRecord?
) -> UInt64 {
    var hash = hashU64(initial, tick.scheduler.frame)
    hash = hashU64(hash, UInt64(tick.scheduler.listCounts[SM64ObjectList.default.rawValue]))
    hash = hashU64(hash, UInt64(tick.scheduler.objectCounter))
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashU64(hash, UInt64(effect.objectID.slot))
        hash = hashU64(hash, UInt64(effect.objectID.generation))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.faceRoll)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(effect.output.angleVelocityRoll)))
        hash = hashU64(hash, effect.output.playsClockSound ? 1 : 0)
        hash = hashU64(hash, UInt64(effect.presentedEffects.count))
        for intent in effect.presentedEffects {
            hash = hashU64(hash, UInt64(intent.kind.rawValue))
            hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
        }
    }
    hash = hashU64(hash, UInt64(tick.deliveries.count))
    for delivery in tick.deliveries {
        hash = hashU64(hash, UInt64(delivery.presented.count))
        for intent in delivery.presented {
            hash = hashU64(hash, UInt64(intent.kind.rawValue))
            hash = hashU64(hash, UInt64(bitPattern: Int64(intent.value)))
        }
    }
    hash = hashU64(hash, UInt64(objectID.slot))
    hash = hashU64(hash, UInt64(objectID.generation))
    hash = hashU64(hash, UInt64(bitPattern: Int64(record?.faceAngles.roll ?? 0)))
    return hashU64(hash, UInt64(bitPattern: Int64(record?.angleVelocity.roll ?? 0)))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernDecorativePendulumObjectBridgeSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64DecorativePendulumObjectBridge()
        let pendulum = try bridge.spawnPendulum(
            in: engine,
            position: SM64ObjectVector3(x: 100, y: 200, z: 300),
            faceRoll: 100
        )
        _ = engine.objects.mutate(pendulum) { record in
            record.angleVelocity.roll = 0x20
        }

        var fingerprint = fnvOffset
        var tick = bridge.tick(state: engine)
        require(tick.scheduler.listCounts[SM64ObjectList.default.rawValue] == 1, "default list owns pendulum")
        require(tick.scheduler.objectCounter == 1, "pendulum contributes to object counter")
        require(tick.scheduler.updated == [pendulum], "pendulum is live scheduler update")
        require(tick.effects.first?.output.faceRoll == 124, "pendulum roll advances")
        require(tick.effects.first?.output.angleVelocityRoll == 0x18, "pendulum acceleration matches C")
        require(tick.effects.first?.presentedEffects.isEmpty == true, "no clock sound before hit")
        fingerprint = hashTick(fingerprint, tick, objectID: pendulum, record: engine.objects.record(for: pendulum))

        _ = engine.objects.mutate(pendulum) { record in
            record.faceAngles.roll = 100
            record.angleVelocity.roll = 0x18
        }
        tick = bridge.tick(state: engine)
        require(tick.effects.first?.output.faceRoll == 116, "positive sound roll matches C")
        require(tick.effects.first?.output.angleVelocityRoll == 0x10, "positive sound threshold matches C")
        require(tick.effects.first?.presentedEffects.count == 1, "clock sound is presented")
        require(tick.effects.first?.presentedEffects.first?.kind == .sound, "clock effect is sound")
        require(tick.effects.first?.presentedEffects.first?.value == SM64DecorativePendulumObjectBridge.clockSoundValue, "clock sound value transfers")
        fingerprint = hashTick(fingerprint, tick, objectID: pendulum, record: engine.objects.record(for: pendulum))

        _ = engine.objects.mutate(pendulum) { record in
            record.faceAngles.roll = -100
            record.angleVelocity.roll = -0x18
        }
        tick = bridge.tick(state: engine)
        require(tick.effects.first?.output.faceRoll == -116, "negative sound roll matches C")
        require(tick.effects.first?.output.angleVelocityRoll == -0x10, "negative sound threshold matches C")
        require(tick.deliveries.first?.presented.first?.value == SM64DecorativePendulumObjectBridge.clockSoundValue, "negative clock sound transfers")
        fingerprint = hashTick(fingerprint, tick, objectID: pendulum, record: engine.objects.record(for: pendulum))

        print(String(format: "decorativePendulumObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern decorative pendulum object bridge smoke passed")
    }
}
