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

private func floor() -> SM64Surface {
    SM64Surface(
        id: 1,
        room: 4,
        vertex1: SM64SurfaceVec3s(x: -2_000, y: 0, z: -2_000),
        vertex2: SM64SurfaceVec3s(x: 2_000, y: 0, z: 2_000),
        vertex3: SM64SurfaceVec3s(x: 2_000, y: 0, z: -2_000),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: 0
    )
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashMovement(
    _ initial: UInt64,
    effect: SM64EyerokObjectEffectRecord,
    record: SM64ObjectRecord
) -> UInt64 {
    guard let collision = effect.collision, let movement = effect.movement else {
        preconditionFailure("Eyerok hand movement result missing")
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
enum SM64ModernEyerokHandMovementBridgeSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor()])
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64EyerokObjectBridge()
        let bossID = try bridge.spawnBoss(in: engine, homeX: 0, homeY: 100, homeZ: 0)
        _ = bridge.tick(state: engine)

        let handID = bridge.registeredHandIDs[0]
        var boss = bridge.bossState(for: bossID)!
        boss.action = .fight
        boss.activeHand = 0
        boss.busyHand = 1
        require(bridge.setBossState(boss, for: bossID, in: engine.objects), "Eyerok movement boss state")
        var hand = bridge.handState(for: handID)!
        hand.action = .smash
        hand.positionY = 100
        hand.homeZ = -300
        hand.positionZ = -300
        hand.timer = 21
        hand.gravity = -20
        require(bridge.setHandState(hand, for: handID, in: engine.objects), "Eyerok movement hand state")

        let tick = bridge.tick(
            state: engine,
            collisionWorld: world,
            advanceMovement: true
        )
        guard let effect = tick.effects.first(where: { $0.objectID == handID }),
              let record = engine.objects.record(for: handID),
              let collision = effect.collision,
              let movement = effect.movement else {
            preconditionFailure("Eyerok hand owner movement result missing")
        }
        require(effect.handAction == .smash, "Eyerok movement action remains smash")
        require(collision.floorSurfaceID == 1 && collision.floorRoom == 4,
                "Eyerok movement floor identity")
        require(collision.moveFlags & SM64EyerokHandCollision.inAir != 0,
                "Eyerok movement in-air flag")
        require(movement.position.y == 80, "Eyerok source gravity step")
        require(record.position == movement.position, "Eyerok movement record publication")
        require(record.floorRoom == 4 && record.wallHitboxRadius == 0,
                "Eyerok movement floor/radius publication")

        let fingerprint = hashMovement(fnvOffset, effect: effect, record: record)
        print(String(format: "eyerokHandMovementFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Eyerok hand movement bridge smoke passed")
    }
}
