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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func floor() -> SM64Surface {
    SM64Surface(
        id: 1,
        room: 3,
        vertex1: SM64SurfaceVec3s(x: -2_000, y: 0, z: -2_000),
        vertex2: SM64SurfaceVec3s(x: 2_000, y: 0, z: 2_000),
        vertex3: SM64SurfaceVec3s(x: 2_000, y: 0, z: -2_000),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: 0
    )
}

private func wall() -> SM64Surface {
    SM64Surface(
        id: 2,
        flags: SM64SurfaceCollisionWorld.xProjectionFlag,
        lowerY: -100,
        upperY: 100,
        vertex1: SM64SurfaceVec3s(x: 300, y: -100, z: -100),
        vertex2: SM64SurfaceVec3s(x: 300, y: 100, z: -100),
        vertex3: SM64SurfaceVec3s(x: 300, y: 100, z: 100),
        normal: SM64SurfaceVec3f(x: 1, y: 0, z: 0),
        originOffset: -300
    )
}

private func hashEffect(
    _ initial: UInt64,
    effect: SM64BigBooObjectEffectRecord,
    record: SM64ObjectRecord
) -> UInt64 {
    guard let collision = effect.collision, let movement = effect.movement else {
        preconditionFailure("Big Boo owner movement effect is missing collision or movement")
    }
    var hash = hashFloat(initial, collision.position.x)
    hash = hashFloat(hash, collision.position.y)
    hash = hashFloat(hash, collision.position.z)
    hash = hashFloat(hash, collision.floorHeight)
    hash = hashU32(hash, collision.floorSurfaceID ?? UInt32.max)
    hash = hashU32(hash, UInt32(bitPattern: Int32(collision.floorRoom)))
    hash = hashU32(hash, UInt32(collision.wallSurfaceIDs.count))
    for id in collision.wallSurfaceIDs { hash = hashU32(hash, id) }
    hash = hashU32(hash, collision.moveFlags)
    hash = hashU32(hash, collision.hitWall ? 1 : 0)
    hash = hashFloat(hash, movement.position.x)
    hash = hashFloat(hash, movement.position.y)
    hash = hashFloat(hash, movement.position.z)
    hash = hashFloat(hash, movement.velocity.y)
    hash = hashFloat(hash, movement.forwardVelocity)
    hash = hashU32(hash, movement.moveFlags)
    hash = hashFloat(hash, record.position.x)
    hash = hashFloat(hash, record.position.y)
    hash = hashFloat(hash, record.position.z)
    hash = hashFloat(hash, record.gravity)
    hash = hashFloat(hash, record.buoyancy)
    return hashU32(hash, record.moveFlags)
}

@main
enum SM64ModernBigBooObjectMovementBridgeSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor(), wall()])
        let engine = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64BigBooObjectBridge()
        let id = try bridge.spawnBigBoo(
            in: engine,
            variant: .ghostHunt,
            homeX: 290,
            action: .chase
        )
        _ = engine.objects.mutate(id) { record in
            record.position = SM64ObjectVector3(x: 290, y: 0, z: 0)
        }

        let tick = bridge.tick(
            state: engine,
            inputs: [id: SM64BigBooTickInput(
                distanceToMario: 1_000,
                angleToMario: 0,
                marioInAir: true
            )],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let effect = tick.effects.first,
              let record = engine.objects.record(for: id) else {
            preconditionFailure("Big Boo owner movement result missing")
        }
        require(effect.action == .chase, "Big Boo action remains chase")
        require(effect.collision?.floorSurfaceID == 1, "Big Boo floor identity")
        require(effect.collision?.floorRoom == 3, "Big Boo floor room")
        require(effect.collision?.wallSurfaceIDs == [2], "Big Boo wall identity")
        require(effect.collision?.position.x == 330, "Big Boo wall projection")
        require(effect.movement?.position == SM64ObjectVector3(x: 330, y: 0, z: 10),
                "Big Boo standard movement position")
        require(effect.movement?.velocity.y == 0, "Big Boo external movement vertical velocity")
        require(effect.movement?.forwardVelocity == 9.9, "Big Boo source drag constant")
        require(effect.movement?.moveFlags == SM64BigBooCollision.inAir,
                "Big Boo first airborne movement flag")
        require(record.position == effect.movement?.position,
                "Big Boo record follows movement")
        require(record.wallHitboxRadius == SM64BigBooCollision.wallHitboxRadius,
                "Big Boo record wall radius")
        require(record.buoyancy == SM64BigBooCollision.buoyancy,
                "Big Boo record buoyancy")
        require(record.dragStrength == SM64BigBooCollision.dragStrength,
                "Big Boo record drag")

        let fingerprint = hashEffect(fnvOffset, effect: effect, record: record)
        print(String(format: "bigBooObjectMovementBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Big Boo owner collision/movement bridge smoke passed")
    }
}
