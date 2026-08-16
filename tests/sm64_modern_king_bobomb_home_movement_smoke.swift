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

private func hashStart(_ initial: UInt64, _ start: SM64KingBobombHomeArcStart) -> UInt64 {
    var hash = hashU32(initial, UInt32(UInt16(bitPattern: start.moveYaw)))
    hash = hashFloat(hash, start.forwardVelocity)
    hash = hashFloat(hash, start.velocityY)
    hash = hashFloat(hash, start.gravity)
    return hashU32(hash, UInt32(bitPattern: start.flightFrames))
}

private func hashStep(_ initial: UInt64, _ step: SM64KingBobombHomeArcStep) -> UInt64 {
    var hash = hashFloat(initial, step.position.x)
    hash = hashFloat(hash, step.position.y)
    hash = hashFloat(hash, step.position.z)
    hash = hashFloat(hash, step.velocity.x)
    hash = hashFloat(hash, step.velocity.y)
    return hashFloat(hash, step.velocity.z)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func floor() -> SM64Surface {
    SM64Surface(
        id: 1,
        vertex1: SM64SurfaceVec3s(x: -2_000, y: 0, z: -2_000),
        vertex2: SM64SurfaceVec3s(x: 2_000, y: 0, z: 2_000),
        vertex3: SM64SurfaceVec3s(x: 2_000, y: 0, z: -2_000),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: 0
    )
}

@main
enum SM64ModernKingBobombHomeMovementSmoke {
    static func main() throws {
        let start = SM64KingBobombHomeMovement.start(
            SM64KingBobombHomeArcInput(
                currentPosition: SM64ObjectVector3(x: 100, y: 0, z: 0),
                homePosition: SM64ObjectVector3(x: 0, y: 0, z: 100),
                initialVelocityY: 100,
                gravity: -4
            )
        )!
        require(start.flightFrames == 49, "source arc flight duration")
        require(start.forwardVelocity > 2.8 && start.forwardVelocity < 3, "source arc planar speed")
        let step = SM64KingBobombHomeMovement.step(
            SM64KingBobombHomeArcStepInput(
                position: SM64ObjectVector3(x: 100, y: 0, z: 0),
                moveYaw: start.moveYaw,
                forwardVelocity: start.forwardVelocity,
                velocityY: start.velocityY,
                gravity: start.gravity,
                nativeStepScale: 1
            )
        )!
        require(step.position.y == 96, "home arc applies gravity without terminal clamp")
        require(step.position.x < 100 && step.position.z > 0, "home arc advances toward home")
        require(step.velocity.y == 96, "home arc velocity update")

        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor()])
        let engine = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64KingBobombObjectBridge()
        let id = try bridge.spawnKingBobomb(
            in: engine,
            position: SM64ObjectVector3(x: 100, y: 0, z: 0),
            homePosition: SM64ObjectVector3(x: 0, y: 0, z: 100),
            wallHitboxRadius: 0,
            action: SM64KingBobombBehavior.returnHomeAction
        )
        let first = bridge.tick(
            state: engine,
            environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(positionY: 0))],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let firstEffect = first.effects.first,
              let arc = firstEffect.homeArcStart,
              let firstRecord = engine.objects.record(for: id) else {
            preconditionFailure("owner home arc start is missing")
        }
        require(arc == start, "owner arc setup matches value helper")
        require(firstEffect.output.state.subAction == 1, "owner home action advances after arc setup")
        require(firstRecord.homePosition == SM64ObjectVector3(x: 0, y: 0, z: 100), "owner home transform is preserved")

        let second = bridge.tick(
            state: engine,
            environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
                positionY: firstRecord.position.y
            ))],
            collisionWorld: world,
            advanceMovement: true
        )
        guard let secondEffect = second.effects.first,
              let movement = secondEffect.movement,
              let secondRecord = engine.objects.record(for: id) else {
            preconditionFailure("owner home arc movement is missing")
        }
        require(movement.position.y == 96, "owner home arc moves vertically")
        require(secondRecord.position == movement.position, "owner record follows home arc")
        require(secondRecord.position.x < 100 && secondRecord.position.z > 0, "owner record follows home target")

        var fingerprint = hashStart(fnvOffset, start)
        fingerprint = hashStep(fingerprint, step)
        print(String(format: "kingBobombHomeMovementFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb home movement smoke passed")
    }
}
