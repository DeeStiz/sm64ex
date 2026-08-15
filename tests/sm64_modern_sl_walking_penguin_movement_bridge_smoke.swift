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

private func hashMovement(
    _ initial: UInt64,
    _ movement: SM64SLWalkingPenguinMovementResult,
    record: SM64ObjectRecord
) -> UInt64 {
    var hash = initial
    hash = hashFloat(hash, movement.position.x)
    hash = hashFloat(hash, movement.position.y)
    hash = hashFloat(hash, movement.position.z)
    hash = hashFloat(hash, movement.velocity.x)
    hash = hashFloat(hash, movement.velocity.y)
    hash = hashFloat(hash, movement.velocity.z)
    hash = hashFloat(hash, movement.forwardVelocity)
    hash = hashU32(hash, movement.moveFlags)
    hash = hashU32(hash, movement.hitEdge ? 1 : 0)
    hash = hashU32(hash, movement.enteredWater ? 1 : 0)
    hash = hashU32(hash, movement.atWaterSurface ? 1 : 0)
    hash = hashU32(hash, movement.leftGround ? 1 : 0)
    hash = hashU32(hash, movement.bounced ? 1 : 0)
    hash = hashFloat(hash, record.position.x)
    hash = hashFloat(hash, record.position.y)
    hash = hashFloat(hash, record.position.z)
    hash = hashFloat(hash, record.velocity.y)
    hash = hashFloat(hash, record.forwardVelocity)
    return hashU32(hash, record.moveFlags)
}

private func triangle(id: UInt32) -> SM64Surface {
    SM64Surface(
        id: id,
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
enum SM64ModernSLWalkingPenguinMovementBridgeSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [triangle(id: 1)])
        let engineState = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64SLWalkingPenguinObjectBridge()
        let id = try bridge.spawnPenguin(
            in: engineState,
            position: SM64ObjectVector3(x: 600, y: 0, z: 0),
            moveYaw: 0
        )
        var fingerprint = fnvOffset

        for expectedFlags in [SM64SLWalkingPenguinMovement.landed, SM64SLWalkingPenguinMovement.onGround] {
            let tick = bridge.tick(
                state: engineState,
                collisionWorld: world,
                advanceMovement: true
            )
            guard let effect = tick.effects.first,
                  let movement = effect.movement,
                  let record = engineState.objects.record(for: id) else {
                preconditionFailure("movement bridge result missing")
            }
            require(!movement.hitEdge, "flat floor admits candidate movement")
            require(movement.moveFlags & expectedFlags != 0, "ground transition flag is published")
            require(record.position == movement.position, "record position follows movement")
            require(record.velocity == movement.velocity, "record velocity follows movement")
            require(record.moveFlags == movement.moveFlags, "record move flags follow movement")
            fingerprint = hashMovement(fingerprint, movement, record: record)
        }

        print(String(format: "slWalkingPenguinMovementBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern SL walking penguin movement bridge smoke passed")
    }
}
