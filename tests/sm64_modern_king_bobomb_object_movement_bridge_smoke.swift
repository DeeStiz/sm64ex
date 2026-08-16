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
    effect: SM64KingBobombObjectEffect,
    record: SM64ObjectRecord
) -> UInt64 {
    guard let collision = effect.collision, let movement = effect.movement else {
        preconditionFailure("owner movement effect is missing collision or movement")
    }
    var hash = hashU32(initial, collision.floorSurfaceID ?? UInt32.max)
    hash = hashU32(hash, collision.moveFlags)
    hash = hashU32(hash, UInt32(collision.wallSurfaceIDs.count))
    for id in collision.wallSurfaceIDs { hash = hashU32(hash, id) }
    hash = hashFloat(hash, movement.position.x)
    hash = hashFloat(hash, movement.position.y)
    hash = hashFloat(hash, movement.position.z)
    hash = hashFloat(hash, movement.velocity.y)
    hash = hashFloat(hash, movement.forwardVelocity)
    hash = hashU32(hash, movement.moveFlags)
    hash = hashFloat(hash, record.position.x)
    hash = hashFloat(hash, record.position.y)
    hash = hashFloat(hash, record.position.z)
    hash = hashFloat(hash, record.floorHeight)
    return hashU32(hash, record.moveFlags)
}

@main
enum SM64ModernKingBobombObjectMovementBridgeSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor(), wall()])
        let engine = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64KingBobombObjectBridge()
        let id = try bridge.spawnKingBobomb(
            in: engine,
            position: SM64ObjectVector3(x: 290, y: 0, z: 0),
            wallHitboxRadius: 20,
            action: SM64KingBobombBehavior.grabbedAction
        )

        let tick = bridge.tick(
            state: engine,
            environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
                angleToMario: 0x200,
                positionY: 0,
                animationNearEnd: true
            ))],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let effect = tick.effects.first,
              let collision = effect.collision,
              let movement = effect.movement,
              let record = engine.objects.record(for: id) else {
            preconditionFailure("King Bob-omb owner movement result missing")
        }
        require(collision.floorSurfaceID == 1, "owner prepass publishes floor identity")
        require(collision.floorRoom == 3, "owner prepass publishes floor room")
        require(collision.wallSurfaceIDs == [2], "owner prepass publishes wall identity")
        require(collision.position.x == 320, "owner prepass projects wall before action")
        require(movement.position.x == 320, "standard movement starts from projected position")
        require(movement.position.y == 0, "standard movement clamps to floor")
        require(movement.velocity.y == 2, "standard movement applies King Bob-omb bounce")
        require(movement.moveFlags & SM64KingBobombCollision.landed != 0, "landing flag reaches owner")
        require(effect.output.state.forwardVelocity == 0, "first action phase leaves movement speed unchanged")
        require(record.position == movement.position, "owner record follows movement x/z and floor y")
        require(record.floorHeight == 0, "owner record floor height")
        require(record.floorRoom == 3, "owner record floor room")
        require(record.moveFlags == movement.moveFlags, "owner record movement flags")

        var fingerprint = hashEffect(fnvOffset, effect: effect, record: record)
        let next = bridge.tick(
            state: engine,
            environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
                angleToMario: 0x200,
                positionY: record.position.y
            ))],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let nextEffect = next.effects.first,
              let nextRecord = engine.objects.record(for: id) else {
            preconditionFailure("King Bob-omb second movement result missing")
        }
        require(nextEffect.movement != nil, "owner movement remains enabled on the next tick")
        require(nextEffect.output.state.forwardVelocity == 3, "action runs after movement and publishes next speed")
        require(nextRecord.position.x == 320, "wall projection remains generation-safe")
        fingerprint = hashEffect(fingerprint, effect: nextEffect, record: nextRecord)

        print(String(format: "kingBobombObjectMovementBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb owner collision/movement bridge smoke passed")
    }
}
