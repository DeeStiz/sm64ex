import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ r: SM64MarioGrabbedActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue); x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument); x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = hf(x, r.position.x)
    x = hf(x, r.position.y); x = hf(x, r.position.z)
    x = h8(x, r.shouldQueueRumble ? 1 : 0); x = h16(x, r.rumbleDistance)
    return h8(x, r.shouldSyncGraphics ? 1 : 0)
}

private func hash(_ h: UInt64, _ r: SM64MarioTornadoActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue); x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument); x = h16(x, r.actionTimer)
    x = h16(x, r.animationID); x = hf(x, r.proposedPosition.x)
    x = hf(x, r.proposedPosition.y); x = hf(x, r.proposedPosition.z)
    x = hf(x, r.position.x); x = hf(x, r.position.y)
    x = hf(x, r.position.z); x = hf(x, r.velocity.x); x = hf(x, r.velocity.y)
    x = hf(x, r.velocity.z); x = hf(x, r.floorHeight)
    x = hf(x, r.tornadoPositionY); x = h16(x, UInt16(bitPattern: r.tornadoYawVelocity))
    x = h16(x, UInt16(bitPattern: r.angleVelocityY)); x = h16(x, UInt16(bitPattern: r.twirlYaw))
    x = h16(x, UInt16(bitPattern: r.graphicsYaw)); x = h8(x, r.shouldUpdateFloor ? 1 : 0)
    x = h8(x, r.shouldPlayTwirlSound ? 1 : 0); x = h8(x, r.shouldResetRumble ? 1 : 0)
    return h8(x, r.shouldSyncGraphics ? 1 : 0)
}

private func grabbed(
    status: UInt32 = 0, yaw: Int16 = 0x1000,
    position: SM64ObjectVector3 = .init(x: 1, y: 2, z: 3),
    faceYaw: Int16 = 0x0800, forwardVelocity: Float = 0
) -> SM64MarioGrabbedActionInput {
    SM64MarioGrabbedActionInput(
        interactionStatus: status, usedObjectYaw: yaw, graphicsPosition: position,
        faceYaw: faceYaw, forwardVelocity: forwardVelocity
    )
}

private func tornado(
    position: SM64ObjectVector3 = .init(x: 40, y: 120, z: -25),
    velocity: SM64ObjectVector3 = .init(x: 1, y: -2, z: 3),
    usedPosition: SM64ObjectVector3 = .zero,
    hitboxHeight: Float = 300,
    tornadoY: Float = 20, tornadoYaw: Int16 = 0x0100,
    angleYaw: Int16 = 0x0200, twirlYaw: Int16 = 0x7F00,
    argument: UInt32 = 0, timer: UInt16 = 5, faceYaw: Int16 = 0x1000,
    floorHeight: Float = 110, floorFound: Bool = false,
    nextFloorHeight: Float = 0,
    wallPosition: SM64ObjectVector3 = .init(x: 39, y: 19, z: -24),
    animationPastEnd: Bool = false
) -> SM64MarioTornadoActionInput {
    SM64MarioTornadoActionInput(
        position: position, velocity: velocity, usedObjectPosition: usedPosition,
        usedObjectHitboxHeight: hitboxHeight, tornadoPositionY: tornadoY,
        tornadoYawVelocity: tornadoYaw, angleVelocityY: angleYaw, twirlYaw: twirlYaw,
        actionArgument: argument, actionTimer: timer, faceYaw: faceYaw,
        floorHeight: floorHeight, floorFound: floorFound,
        nextFloorHeight: nextFloorHeight, wallAdjustedPosition: wallPosition,
        animationPastEnd: animationPastEnd
    )
}

@main
enum SM64ModernMarioGrabbedTornadoSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let grabbedIdle = SM64MarioGrabbedAction.update(grabbed())!
        precondition(grabbedIdle.intent == .continueAction && grabbedIdle.animationID == 0x58)
        fingerprint = hash(fingerprint, grabbedIdle)

        let thrownForward = SM64MarioGrabbedAction.update(
            grabbed(status: 0x04, yaw: 0x2200, forwardVelocity: 12)
        )!
        precondition(thrownForward.action == SM64MarioActionID.thrownForward)
        precondition(thrownForward.actionArgument == 1 && thrownForward.shouldQueueRumble)
        fingerprint = hash(fingerprint, thrownForward)

        let thrownBackward = SM64MarioGrabbedAction.update(
            grabbed(status: 0x44, yaw: -0x1200, forwardVelocity: -12)
        )!
        precondition(thrownBackward.action == SM64MarioActionID.thrownBackward)
        precondition(thrownBackward.actionArgument == 0)
        fingerprint = hash(fingerprint, thrownBackward)

        let tornadoStep = SM64MarioTornadoAction.update(tornado(animationPastEnd: true))!
        precondition(tornadoStep.intent == .continueAction)
        precondition(tornadoStep.animationID == 0x95 && tornadoStep.shouldResetRumble)
        precondition(tornadoStep.actionArgument == 1 && tornadoStep.shouldPlayTwirlSound)
        fingerprint = hash(fingerprint, tornadoStep)

        let tornadoFloor = SM64MarioTornadoAction.update(tornado(
            position: .init(x: 10, y: 20, z: 30),
            velocity: .init(x: 0, y: 1, z: 0), usedPosition: .init(x: 2, y: 4, z: 6),
            tornadoY: 5, tornadoYaw: 0x0F00, angleYaw: 0x3000, twirlYaw: 0x7000,
            argument: 1, timer: 9, faceYaw: -0x1000, floorHeight: 0,
            floorFound: true, nextFloorHeight: 7,
            wallPosition: .init(x: 3, y: 12, z: 9)
        ))!
        precondition(tornadoFloor.shouldUpdateFloor && tornadoFloor.floorHeight == 7)
        precondition(tornadoFloor.animationID == 0x94)
        fingerprint = hash(fingerprint, tornadoFloor)

        let tornadoExit = SM64MarioTornadoAction.update(tornado(
            velocity: .init(x: 0, y: 10, z: 0), hitboxHeight: 300, tornadoY: 295
        ))!
        precondition(tornadoExit.intent == .twirling)
        precondition(tornadoExit.action == SM64MarioActionID.twirling)
        precondition(tornadoExit.velocity.y == 20)
        fingerprint = hash(fingerprint, tornadoExit)

        precondition(SM64MarioGrabbedAction.update(grabbed(
            position: .init(x: .infinity, y: 0, z: 0)
        )) == nil)
        precondition(SM64MarioTornadoAction.update(tornado(
            position: .init(x: .infinity, y: 0, z: 0)
        )) == nil)

        print(String(format: "marioGrabbedTornadoFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario grabbed/tornado smoke passed")
    }
}
