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

@main
enum SM64ModernBullyMovementSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor()])
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BullyObjectBridge()
        let id = try bridge.spawnBully(in: engine, size: .small, homeY: 100, homeZ: -300, action: .patrol)
        let tick = bridge.tick(
            state: engine,
            inputs: [id: SM64BullyTickInput(angleToMario: 0, distanceFromHome: 0)],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let effect = tick.effects.first,
              let collision = effect.collision,
              let movement = effect.movement,
              let record = engine.objects.record(for: id) else {
            preconditionFailure("Bully movement result missing")
        }
        require(effect.action == .chase, "Bully patrol action transition")
        require(collision.floorSurfaceID == 1 && collision.floorRoom == 4, "Bully floor identity")
        require(collision.moveFlags & SM64BullyCollision.inAir != 0, "Bully prepass in-air flag")
        require(movement.position == SM64ObjectVector3(x: 0, y: 96, z: -295), "Bully object-step position")
        require(movement.velocity.y == -4, "Bully gravity")
        require(movement.forwardVelocity == 5, "Bully airborne forward speed")
        require(movement.collisionFlags == 0, "Bully airborne collision flags")
        require(record.position == movement.position, "Bully movement record publication")
        require(record.floorRoom == 4 && record.wallHitboxRadius == 0, "Bully floor/radius publication")

        var fingerprint = hashFloat(fnvOffset, collision.position.x)
        fingerprint = hashFloat(fingerprint, collision.position.y)
        fingerprint = hashFloat(fingerprint, collision.position.z)
        fingerprint = hashFloat(fingerprint, collision.floorHeight)
        fingerprint = hashU32(fingerprint, collision.floorSurfaceID ?? UInt32.max)
        fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(collision.floorRoom)))
        fingerprint = hashU32(fingerprint, collision.moveFlags)
        fingerprint = hashU32(fingerprint, collision.collisionFlags)
        fingerprint = hashFloat(fingerprint, movement.position.x)
        fingerprint = hashFloat(fingerprint, movement.position.y)
        fingerprint = hashFloat(fingerprint, movement.position.z)
        fingerprint = hashFloat(fingerprint, movement.velocity.y)
        fingerprint = hashFloat(fingerprint, movement.forwardVelocity)
        fingerprint = hashU32(fingerprint, movement.moveFlags)
        fingerprint = hashU32(fingerprint, movement.collisionFlags)
        fingerprint = hashFloat(fingerprint, record.position.x)
        fingerprint = hashFloat(fingerprint, record.position.y)
        fingerprint = hashFloat(fingerprint, record.position.z)
        fingerprint = hashFloat(fingerprint, record.forwardVelocity)
        fingerprint = hashFloat(fingerprint, record.gravity)
        fingerprint = hashFloat(fingerprint, record.buoyancy)
        fingerprint = hashU32(fingerprint, record.moveFlags)
        print(String(format: "bullyMovementFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bully movement smoke passed")
    }
}
