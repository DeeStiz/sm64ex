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

private func hashResult(_ initial: UInt64, _ result: SM64SLWalkingPenguinMovementResult) -> UInt64 {
    var hash = initial
    hash = hashU32(hash, result.position.x.bitPattern)
    hash = hashU32(hash, result.position.y.bitPattern)
    hash = hashU32(hash, result.position.z.bitPattern)
    hash = hashU32(hash, result.velocity.x.bitPattern)
    hash = hashU32(hash, result.velocity.y.bitPattern)
    hash = hashU32(hash, result.velocity.z.bitPattern)
    hash = hashU32(hash, result.forwardVelocity.bitPattern)
    hash = hashU32(hash, result.moveFlags)
    hash = hashU32(hash, result.hitEdge ? 1 : 0)
    hash = hashU32(hash, result.enteredWater ? 1 : 0)
    hash = hashU32(hash, result.atWaterSurface ? 1 : 0)
    hash = hashU32(hash, result.leftGround ? 1 : 0)
    return hashU32(hash, result.bounced ? 1 : 0)
}

private func input(
    start: SM64ObjectVector3,
    candidate: SM64ObjectVector3,
    velocityY: Float = 0,
    forwardVelocity: Float = 6,
    moveYaw: Int16 = 0,
    floorHeight: Float = 0,
    floorRoom: Int8 = 0,
    objectRoom: Int8 = -1,
    moveFlags: UInt32 = SM64SLWalkingPenguinMovement.onGround,
    gravity: Float = -4,
    bounciness: Float = -0.5,
    dragStrength: Float = 0,
    buoyancy: Float = 2,
    nativeStepScale: Float = 1,
    intendedFloorHeight: Float = 0,
    intendedFloorNormalY: Float = 1,
    intendedFloorRoom: Int8 = 0,
    intendedFloorExists: Bool = true,
    waterLevel: Float = -11_000,
    activeFarAway: Bool = false
) -> SM64SLWalkingPenguinMovementInput {
    SM64SLWalkingPenguinMovementInput(
        startPosition: start,
        candidatePosition: candidate,
        velocityY: velocityY,
        forwardVelocity: forwardVelocity,
        moveYaw: moveYaw,
        floorHeight: floorHeight,
        floorRoom: floorRoom,
        objectRoom: objectRoom,
        moveFlags: moveFlags,
        gravity: gravity,
        bounciness: bounciness,
        dragStrength: dragStrength,
        buoyancy: buoyancy,
        nativeStepScale: nativeStepScale,
        intendedFloorHeight: intendedFloorHeight,
        intendedFloorNormalY: intendedFloorNormalY,
        intendedFloorRoom: intendedFloorRoom,
        intendedFloorExists: intendedFloorExists,
        waterLevel: waterLevel,
        activeFarAway: activeFarAway
    )
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernSLWalkingPenguinMovementSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let ground = SM64SLWalkingPenguinMovement.resolve(input(
            start: .zero,
            candidate: SM64ObjectVector3(x: 6, y: 0, z: 0)
        ))!
        require(ground.position.y == 0 && ground.moveFlags & SM64SLWalkingPenguinMovement.onGround != 0, "ground clamp and on-ground flag")
        require(ground.velocity.y == 2, "penguin buoyancy-scaled ground bounce")
        fingerprint = hashResult(fingerprint, ground)

        let edge = SM64SLWalkingPenguinMovement.resolve(input(
            start: .zero,
            candidate: SM64ObjectVector3(x: 100, y: 0, z: 0),
            intendedFloorHeight: -60
        ))!
        require(edge.hitEdge && edge.position.x == 0, "downward edge is rejected while grounded")
        fingerprint = hashResult(fingerprint, edge)

        let steepUp = SM64SLWalkingPenguinMovement.resolve(input(
            start: .zero,
            candidate: SM64ObjectVector3(x: 6, y: 0, z: 0),
            intendedFloorHeight: 100,
            intendedFloorNormalY: 0.1
        ))!
        require(!steepUp.hitEdge && steepUp.position.x == 0, "steep upward slope is rejected")
        fingerprint = hashResult(fingerprint, steepUp)

        let allowedSlope = SM64SLWalkingPenguinMovement.resolve(input(
            start: .zero,
            candidate: SM64ObjectVector3(x: 6, y: 0, z: 0),
            intendedFloorHeight: 100,
            intendedFloorNormalY: 0.5
        ))!
        require(!allowedSlope.hitEdge && allowedSlope.position.x == 6, "permissive slope moves")
        fingerprint = hashResult(fingerprint, allowedSlope)

        let enteredWater = SM64SLWalkingPenguinMovement.resolve(input(
            start: SM64ObjectVector3(x: 0, y: 10, z: 0),
            candidate: SM64ObjectVector3(x: 6, y: 10, z: 0),
            moveFlags: 0,
            waterLevel: 20
        ))!
        require(enteredWater.enteredWater && enteredWater.moveFlags & SM64SLWalkingPenguinMovement.inAir != 0, "water entry flags")
        fingerprint = hashResult(fingerprint, enteredWater)

        let underwater = SM64SLWalkingPenguinMovement.resolve(input(
            start: SM64ObjectVector3(x: 0, y: 10, z: 0),
            candidate: SM64ObjectVector3(x: 6, y: 10, z: 0),
            moveFlags: SM64SLWalkingPenguinMovement.underwaterOffGround,
            waterLevel: 20
        ))!
        require(underwater.moveFlags & SM64SLWalkingPenguinMovement.underwaterOffGround != 0, "underwater off-ground flag")
        require(underwater.moveFlags & SM64SLWalkingPenguinMovement.inAir == 0, "underwater off-ground clears in-air")
        fingerprint = hashResult(fingerprint, underwater)

        let yawed = SM64SLWalkingPenguinMovement.resolve(input(
            start: .zero,
            candidate: SM64ObjectVector3(x: 4.2426405, y: 0, z: 4.2426405),
            moveYaw: 0x2000
        ))!
        require(yawed.velocity.x > 4 && yawed.velocity.z > 4, "canonical yaw decomposes forward velocity")
        fingerprint = hashResult(fingerprint, yawed)

        let dragged = SM64SLWalkingPenguinMovement.resolve(input(
            start: .zero,
            candidate: SM64ObjectVector3(x: -6, y: 0, z: 0),
            forwardVelocity: -6,
            dragStrength: 100
        ))!
        require(dragged.forwardVelocity < 0, "negative forward velocity sign is retained")
        fingerprint = hashResult(fingerprint, dragged)

        print(String(format: "slWalkingPenguinMovementFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern SL walking penguin movement smoke passed")
    }
}
