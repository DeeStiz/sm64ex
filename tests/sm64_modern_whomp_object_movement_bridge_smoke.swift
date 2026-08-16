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
    effect: SM64WhompObjectEffectRecord,
    record: SM64ObjectRecord
) -> UInt64 {
    guard let collision = effect.collision, let movement = effect.movement else {
        preconditionFailure("Whomp owner movement effect is missing collision or movement")
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
enum SM64ModernWhompObjectMovementBridgeSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor(), wall()])
        let engine = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64WhompObjectBridge()
        let id = try bridge.spawnWhomp(
            in: engine,
            size: .normal,
            homeX: 290,
            action: SM64WhompAction.chase,
            wallHitboxRadius: 20
        )
        _ = engine.objects.mutate(id) { record in
            record.position = SM64ObjectVector3(x: 290, y: 0, z: 0)
        }

        let first = bridge.tick(
            state: engine,
            inputs: [id: SM64WhompTickInput(distanceToMario: 1_000, angleToMario: 0)],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let firstEffect = first.effects.first,
              let firstRecord = engine.objects.record(for: id) else {
            preconditionFailure("Whomp first owner movement result missing")
        }
        require(firstEffect.action == .chase, "Whomp action remains chase")
        require(firstEffect.collision?.floorSurfaceID == 1, "Whomp floor identity")
        require(firstEffect.collision?.floorRoom == 3, "Whomp floor room")
        require(firstEffect.collision?.wallSurfaceIDs == [2], "Whomp wall identity")
        require(firstEffect.collision?.position.x == 320, "Whomp wall projection before action")
        require(firstEffect.movement?.position == SM64ObjectVector3(x: 320, y: 0, z: 9),
                "Whomp standard movement position")
        require(firstEffect.movement?.velocity.y == 2, "Whomp source bounce constant")
        require(firstEffect.movement?.moveFlags == SM64WhompCollision.landed,
                "Whomp first landing flag")
        require(firstRecord.position == firstEffect.movement?.position,
                "Whomp record follows first movement")

        var fingerprint = hashEffect(fnvOffset, effect: firstEffect, record: firstRecord)
        let second = bridge.tick(
            state: engine,
            inputs: [id: SM64WhompTickInput(distanceToMario: 1_000, angleToMario: 0)],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let secondEffect = second.effects.first,
              let secondRecord = engine.objects.record(for: id) else {
            preconditionFailure("Whomp second owner movement result missing")
        }
        require(secondEffect.movement?.position == SM64ObjectVector3(x: 320, y: 0, z: 18),
                "Whomp second movement position")
        require(secondEffect.movement?.moveFlags == SM64WhompCollision.onGround,
                "Whomp second ground transition")
        require(secondRecord.moveFlags == SM64WhompCollision.onGround,
                "Whomp record publishes second ground transition")
        fingerprint = hashEffect(fingerprint, effect: secondEffect, record: secondRecord)

        print(String(format: "whompObjectMovementBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Whomp owner collision/movement bridge smoke passed")
    }
}
