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

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernOwnerThreadEffectRouterSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 32)
        let source = try engineState.spawnObject(in: .generalActor, model: 0x6B, behaviorIdentity: 0x706F7374)
        let router = SM64OwnerThreadEffectRouter()
        router.enqueue(objectID: source, kind: .sound)
        router.enqueue(objectID: source, kind: .particle, value: 30, auxiliary: 0x8A)
        router.enqueue(objectID: source, kind: .cameraShake)
        router.enqueue(objectID: source, kind: .releaseChain)
        router.enqueue(objectID: source, kind: .spawnCoin, value: 5)
        router.enqueue(objectID: source, kind: .setRespawnBit, value: 1)
        router.enqueue(objectID: source, kind: .markForDeletion)
        let result = router.deliver(to: engineState.objects)

        require(result.delivered.count == 7, "effect delivery count")
        require(result.presented.map(\.kind) == [.sound, .particle, .cameraShake, .releaseChain], "presentation ordering")
        require(result.spawned.count == 5, "coin child count")
        require(result.deleted == [source], "source deletion")
        require(result.rejected.isEmpty, "effect rejection")
        require(engineState.objects.record(for: source)?.behaviorParams == 0x100, "respawn bit mutation")

        var fingerprint = fnvOffset
        for intent in result.delivered {
            fingerprint = hashU64(fingerprint, intent.sequence)
            fingerprint = hashU64(fingerprint, UInt64(intent.objectID.traceSubject))
            fingerprint = hashU64(fingerprint, UInt64(intent.kind.rawValue))
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(intent.value)))
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(intent.auxiliary)))
        }
        fingerprint = hashU64(fingerprint, UInt64(result.spawned.count))
        fingerprint = hashU64(fingerprint, UInt64(result.deleted.count))
        print(String(format: "ownerThreadEffectRouterFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern owner-thread effect router smoke passed")
    }
}
