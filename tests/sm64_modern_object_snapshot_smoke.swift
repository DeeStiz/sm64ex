import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hex(_ value: UInt64) -> String {
    String(format: "0x%016llx", value)
}

@main
enum SM64ModernObjectSnapshotSmoke {
    static func main() throws {
        let pool = SM64ObjectPool(capacity: 4)
        let player = try pool.spawn(in: .player, behaviorIdentity: 0x20)
        let actor = try pool.spawn(in: .generalActor, behaviorIdentity: 0x40, parent: player)
        require(pool.setPlatform(actor, platform: player), "platform reference")
        require(pool.setCollidedObject(actor, slot: 0, collidedObject: player), "collision reference 0")
        require(pool.setCollidedObject(actor, slot: 2, collidedObject: actor), "collision reference 2")
        require(!pool.setCollidedObject(actor, slot: 4, collidedObject: player), "collision slot bounds")
        require(!pool.setParent(actor, parent: SM64ObjectID(slot: 3, generation: 1)), "stale parent rejection")

        require(pool.mutate(actor) { record in
            record.activeFlags = 0x0101
            record.action = 7
            record.subAction = 3
            record.timer = -2
            record.position = SM64ObjectVector3(x: 1.5, y: -2.25, z: 3.75)
            record.velocity = SM64ObjectVector3(x: -4.5, y: 5.25, z: -6.125)
            record.moveAngles = SM64ObjectAngles(pitch: 0x1234, yaw: -32768, roll: 0x7fff)
            record.moveFlags = 0x1234_5678
            record.interactionStatus = -9
            record.heldState = 2
            record.objectFlags = 0x400
            record.forwardVelocity = -1.25
            record.graphFlags = 0x00a5
        }, "actor state mutation")

        guard let record = pool.record(for: actor) else { preconditionFailure("missing actor") }
        let snapshot = SM64ObjectSnapshotV4(record: record)
        require(snapshot.subject == 2, "C slot subject")
        require(snapshot.actorValues.count == 20 && snapshot.relationValues.count == 7, "fixed snapshot widths")
        require(snapshot.relationValues == [1, 0, 1, 1, 0, 2, 0], "C relation subjects")
        require(pool.schema4Snapshots().map(\.subject) == [1, 2], "ordered object snapshots")

        print("actorFingerprint=\(hex(snapshot.actorFingerprint))")
        print("relationFingerprint=\(hex(snapshot.relationFingerprint))")
        print("combinedFingerprint=\(hex(snapshot.combinedFingerprint))")
        print("SM64 Modern object snapshot smoke passed")
    }
}
