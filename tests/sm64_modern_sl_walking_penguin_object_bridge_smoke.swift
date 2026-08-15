import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashI32(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU32(initial, UInt32(bitPattern: value))
}

private func hashEffect(
    _ initial: UInt64,
    _ effect: SM64SLWalkingPenguinObjectEffect,
    record: SM64ObjectRecord
) -> UInt64 {
    var hash = hashU32(initial, effect.objectID.traceSubject)
    hash = hashI32(hash, effect.action)
    hash = hashI32(hash, effect.currentStep)
    hash = hashI32(hash, effect.currentStepTimer)
    hash = hashU32(hash, effect.forwardVelocity.bitPattern)
    hash = hashI32(hash, effect.animation)
    hash = hashU32(hash, effect.animationSpeed.bitPattern)
    hash = hashU32(hash, UInt32(UInt16(bitPattern: effect.angleVelocityYaw)))
    hash = hashU32(hash, UInt32(UInt16(bitPattern: effect.moveYaw)))
    hash = hashU32(hash, effect.completedTurn ? 1 : 0)
    hash = hashI32(hash, record.action)
    hash = hashI32(hash, record.previousAction)
    hash = hashI32(hash, record.timer)
    hash = hashU32(hash, record.position.x.bitPattern)
    return hashU32(hash, record.position.z.bitPattern)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSLWalkingPenguinObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64SLWalkingPenguinObjectBridge()
        let id = try bridge.spawnPenguin(
            in: engineState,
            position: SM64ObjectVector3(x: 600, y: 12, z: -40),
            moveYaw: 0x2000
        )
        var fingerprint = fnvOffset

        for _ in 0..<8 {
            let tick = bridge.tick(state: engineState)
            require(tick.effects.count == 1, "one penguin effect per owner-thread tick")
            guard let record = engineState.objects.record(for: id),
                  let effect = tick.effects.first else {
                preconditionFailure("walking penguin record/effect missing")
            }
            require(record.action == effect.action, "action synchronized to object record")
            require(record.timer > 0, "owner-thread timer advanced")
            require(record.animationState == effect.animation, "animation synchronized")
            require(record.forwardVelocity == effect.forwardVelocity, "speed synchronized")
            fingerprint = hashEffect(fingerprint, effect, record: record)
        }

        guard let beforeDelete = engineState.objects.record(for: id) else {
            preconditionFailure("walking penguin missing before deletion")
        }
        require(beforeDelete.position.x > 600, "owner-thread movement reached object record")
        require(bridge.state(for: id) != nil, "bridge retains live generation")

        require(engineState.objects.markForDeletion(id), "mark walking penguin for deletion")
        let deletionTick = bridge.tick(state: engineState)
        require(deletionTick.scheduler.unloaded == [id], "deletion unload ordering")
        require(engineState.objects.record(for: id) == nil, "object pool unload")
        require(bridge.state(for: id) == nil, "bridge stale generation cleanup")
        require(bridge.registeredIDs.isEmpty, "bridge registry cleanup")

        print(String(format: "slWalkingPenguinObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern SL walking penguin object bridge smoke passed")
    }
}
