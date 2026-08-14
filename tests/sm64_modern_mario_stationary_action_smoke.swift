import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashResult(_ initial: UInt64, _ result: SM64MarioStationaryActionResult) -> UInt64 {
    var hash = hashU32(initial, result.action ?? UInt32.max)
    hash = hashU32(hash, result.actionArgument)
    hash = hashU16(hash, result.animationID ?? UInt16.max)
    hash = hashU16(hash, result.actionState)
    hash = hashU16(hash, result.actionTimer)
    hash = hashU8(hash, result.shouldRunStationaryGroundStep ? 1 : 0)
    return hashU8(hash, result.shouldDropHeldObject ? 1 : 0)
}

private func decision(
    action: UInt32? = nil,
    argument: UInt32 = 0,
    drop: Bool = false
) -> SM64MarioActionDecision {
    SM64MarioActionDecision(
        action: action,
        argument: argument,
        faceYaw: nil,
        shouldDropHeldObject: drop
    )
}

private func input(
    action: UInt32,
    actionArgument: UInt32 = 0,
    actionState: UInt16 = 0,
    actionTimer: UInt16 = 0,
    cancel: SM64MarioActionDecision = decision(),
    snow: Bool = false,
    atEnd: Bool = false,
    pastEnd: Bool = false,
    floorBehindDeltaY: Float = 0,
    floorBehindDynamic: Bool = false
) -> SM64MarioStationaryActionInput {
    SM64MarioStationaryActionInput(
        action: action,
        actionArgument: actionArgument,
        actionState: actionState,
        actionTimer: actionTimer,
        cancelDecision: cancel,
        terrainIsSnow: snow,
        animationAtEnd: atEnd,
        animationPastEnd: pastEnd,
        floorBehindDeltaY: floorBehindDeltaY,
        floorBehindIsDynamic: floorBehindDynamic
    )
}

@main
enum SM64ModernMarioStationaryActionSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let idle = SM64MarioStationaryAction.update(input(action: SM64MarioActionID.idle))!
        precondition(idle.animationID == SM64MarioStationaryAnimationID.idleHeadLeft)
        precondition(idle.shouldRunStationaryGroundStep)
        fingerprint = hashResult(fingerprint, idle)

        let wallIdle = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.idle,
            actionArgument: 1,
            actionState: 2
        ))!
        precondition(wallIdle.animationID == SM64MarioStationaryAnimationID.standAgainstWall)
        fingerprint = hashResult(fingerprint, wallIdle)

        let cycle = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.idle,
            actionState: 2,
            actionTimer: 9,
            atEnd: true,
            floorBehindDeltaY: 0
        ))!
        precondition(cycle.actionState == 3 && cycle.actionTimer == 10)
        fingerprint = hashResult(fingerprint, cycle)

        let invalidSleep = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.idle,
            actionState: 2,
            actionTimer: 0,
            atEnd: true,
            floorBehindDeltaY: 25
        ))!
        precondition(invalidSleep.actionState == 0 && invalidSleep.actionTimer == 0)
        fingerprint = hashResult(fingerprint, invalidSleep)

        let sleeping = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.idle,
            actionState: 3,
            snow: true
        ))!
        precondition(sleeping.action == SM64MarioActionID.shivering && sleeping.animationID == nil)
        fingerprint = hashResult(fingerprint, sleeping)

        let crouching = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.crouching,
            cancel: decision(drop: true)
        ))!
        precondition(crouching.animationID == SM64MarioStationaryAnimationID.crouching)
        precondition(crouching.shouldDropHeldObject)
        fingerprint = hashResult(fingerprint, crouching)

        let startCrouching = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.startCrouching,
            pastEnd: true
        ))!
        precondition(startCrouching.action == SM64MarioActionID.crouching)
        fingerprint = hashResult(fingerprint, startCrouching)

        let cancelled = SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.idle,
            cancel: decision(action: SM64MarioActionID.punching, drop: true)
        ))!
        precondition(cancelled.action == SM64MarioActionID.punching && cancelled.animationID == nil)
        precondition(!cancelled.shouldRunStationaryGroundStep && cancelled.shouldDropHeldObject)
        fingerprint = hashResult(fingerprint, cancelled)

        precondition(SM64MarioStationaryAction.update(input(
            action: SM64MarioActionID.idle,
            actionState: 4
        )) == nil)

        print(String(format: "marioStationaryActionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario stationary-action smoke passed")
    }
}
