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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashTick(
    _ initial: UInt64,
    _ tick: SM64SmallPenguinSchedulerTickResult,
    record: SM64ObjectRecord?
) -> UInt64 {
    var hash = hashU32(initial, UInt32(tick.scheduler.frame))
    hash = hashU32(hash, UInt32(tick.effects.count))
    for effect in tick.effects {
        hash = hashI32(hash, effect.output.state.action)
        hash = hashI32(hash, effect.output.state.timer)
        hash = hashI32(hash, effect.output.state.animation)
        hash = hashFloat(hash, effect.output.state.forwardVelocity)
        if let collision = effect.collision {
            hash = hashU32(hash, collision.floorSurfaceID ?? UInt32.max)
            hash = hashU32(hash, collision.moveFlags)
        } else {
            hash = hashU32(hash, UInt32.max)
            hash = hashU32(hash, 0)
        }
        if let movement = effect.movement {
            hash = hashFloat(hash, movement.position.x)
            hash = hashFloat(hash, movement.position.y)
            hash = hashFloat(hash, movement.position.z)
            hash = hashFloat(hash, movement.velocity.y)
            hash = hashFloat(hash, movement.forwardVelocity)
            hash = hashU32(hash, movement.moveFlags)
        } else {
            hash = hashU32(hash, 0)
            hash = hashU32(hash, 0)
            hash = hashU32(hash, 0)
            hash = hashU32(hash, 0)
            hash = hashU32(hash, 0)
            hash = hashU32(hash, 0)
        }
    }
    guard let record else { return hashU32(hash, 0) }
    hash = hashU32(hash, 1)
    hash = hashFloat(hash, record.position.x)
    hash = hashFloat(hash, record.position.y)
    hash = hashFloat(hash, record.position.z)
    hash = hashI32(hash, record.action)
    hash = hashI32(hash, record.timer)
    return hashU32(hash, record.moveFlags)
}

private func floor() -> SM64Surface {
    SM64Surface(
        id: 1,
        vertex1: SM64SurfaceVec3s(x: -100, y: 0, z: -100),
        vertex2: SM64SurfaceVec3s(x: 100, y: 0, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: 0, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: 0
    )
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSmallPenguinMovementBridgeSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor()])
        let engineState = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64SmallPenguinObjectBridge()
        let id = try bridge.spawnPenguin(
            in: engineState,
            position: SM64ObjectVector3(x: 0, y: 0, z: -40),
            moveYaw: 0,
            wallHitboxRadius: 0
        )
        let environment = SM64SmallPenguinInput(
            distanceToMario: 200,
            angleToMario: 0,
            soundStateID: 1,
            randomUnknown110: 0,
            randomUnknown108: 0,
            randomUnknown104: 0
        )
        var fingerprint = fnvOffset
        for frame in 0..<4 {
            let tick = bridge.tick(
                state: engineState,
                environments: [id: environment],
                collisionWorld: world,
                advanceMovement: true
            )
            guard let effect = tick.effects.first,
                  let record = engineState.objects.record(for: id) else {
                preconditionFailure("small-penguin movement effect/record missing")
            }
            require(effect.collision?.floorSurfaceID == 1, "floor identity before behavior")
            require(effect.movement != nil, "standard movement result published")
            require(record.floorHeight == 0, "floor height synchronized")
            require(record.position.y == 0, "ground movement clamps position")
            if frame > 0 {
                require(record.position.z > -40, "free action forward movement reaches object record")
            }
            fingerprint = hashTick(fingerprint, tick, record: record)
        }
        guard let record = engineState.objects.record(for: id) else {
            preconditionFailure("small-penguin record missing after movement")
        }
        require(record.homePosition == SM64ObjectVector3(x: 0, y: 0, z: -40), "movement does not rewrite home position")
        require(record.moveFlags & SM64SmallPenguinMovement.onGround != 0, "ground flag survives movement")

        require(engineState.objects.markForDeletion(id), "mark small penguin movement object")
        let retired = bridge.tick(state: engineState)
        require(retired.scheduler.unloaded == [id], "movement unload ordering")
        require(bridge.registeredIDs.isEmpty, "movement bridge cleanup")

        print(String(format: "smallPenguinMovementBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern small penguin movement bridge smoke passed")
    }
}
