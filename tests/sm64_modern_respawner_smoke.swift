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
enum SM64ModernRespawnerSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        let engine = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64RespawnerObjectBridge()
        let respawner = try bridge.spawnRespawner(
            in: engine,
            position: SM64ObjectVector3(x: 10, y: 20, z: 30),
            modelToRespawn: 0x77,
            behaviorToRespawn: 0x6268_765F_746573,
            minSpawnDistance: 100,
            behaviorParams: 0x1234
        )

        let nearTick = bridge.tick(
            state: engine,
            inputs: [respawner: SM64RespawnerTickInput(distanceToMario: 100)]
        )
        require(nearTick.effects.count == 1 && nearTick.effects[0].spawnedObject == nil,
                "respawner radius boundary")
        require(engine.objects.record(for: respawner) != nil, "respawner remains in radius")
        fingerprint = hashU64(fingerprint, UInt64(nearTick.effects[0].effects.rawValue))

        let farTick = bridge.tick(
            state: engine,
            inputs: [respawner: SM64RespawnerTickInput(distanceToMario: 101)]
        )
        guard let effect = farTick.effects.first, let child = effect.spawnedObject else {
            preconditionFailure("respawner child missing")
        }
        require(effect.effects.contains(.spawnObject), "respawner spawn effect")
        require(farTick.scheduler.unloaded == [respawner], "respawner retires after spawn")
        guard let childRecord = engine.objects.record(for: child) else {
            preconditionFailure("respawner child record missing")
        }
        require(childRecord.model == 0x77, "respawner model transfer")
        require(childRecord.behaviorIdentity == 0x6268_765F_746573, "respawner behavior transfer")
        require(childRecord.behaviorParams == 0x1234, "respawner behavior params transfer")
        require(childRecord.position == SM64ObjectVector3(x: 10, y: 20, z: 30),
                "respawner transform transfer")
        fingerprint = hashU64(fingerprint, UInt64(effect.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(child.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(farTick.deliveries.count))

        print(String(format: "respawnerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern respawner smoke passed")
    }
}
