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

private func hashResult(_ initial: UInt64, _ result: SM64MarioWalkAnimationResult) -> UInt64 {
    var hash = hashU16(initial, result.animationID)
    hash = hashU32(hash, UInt32(bitPattern: result.animationAcceleration))
    hash = hashU16(hash, result.actionTimer)
    hash = hashU16(hash, UInt16(bitPattern: result.walkingPitch))
    hash = hashU8(hash, result.sound.rawValue)
    hash = hashU16(hash, UInt16(bitPattern: result.soundFrame1))
    return hashU16(hash, UInt16(bitPattern: result.soundFrame2))
}

private func input(
    intended: Float,
    forward: Float,
    quicksand: Float = 0,
    timer: UInt16 = 0,
    past23: Bool = false,
    past1: Bool = false,
    past2: Bool = false,
    metal: Bool = false,
    pitch: Int16 = 0,
    runningPitch: Int16 = 0x1800
) -> SM64MarioWalkAnimationInput {
    SM64MarioWalkAnimationInput(
        intendedMagnitude: intended,
        forwardVelocity: forward,
        quicksandDepth: quicksand,
        actionTimer: timer,
        animationPastFrame23: past23,
        animationPastFrame1: past1,
        animationPastFrame2: past2,
        metalCap: metal,
        walkingPitch: pitch,
        runningPitch: runningPitch
    )
}

@main
enum SM64ModernMarioWalkAnimationSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let tiptoe = SM64MarioWalkAnimation.update(input(
            intended: 2, forward: 0, past1: true
        ))!
        precondition(tiptoe.animationID == SM64MarioWalkAnimationID.startTiptoe)
        precondition(tiptoe.animationAcceleration == 0x10000 && tiptoe.sound == .terrain)
        fingerprint = hashResult(fingerprint, tiptoe)

        let transition = SM64MarioWalkAnimation.update(input(
            intended: 10, forward: 0, timer: 0
        ))!
        precondition(transition.animationID == SM64MarioWalkAnimationID.walking && transition.actionTimer == 2)
        fingerprint = hashResult(fingerprint, transition)

        let walking = SM64MarioWalkAnimation.update(input(
            intended: 12, forward: 10, timer: 2, past1: true
        ))!
        precondition(walking.animationID == SM64MarioWalkAnimationID.walking)
        precondition(walking.animationAcceleration == 196608 && walking.sound == .terrain)
        fingerprint = hashResult(fingerprint, walking)

        let running = SM64MarioWalkAnimation.update(input(
            intended: 24, forward: 20, timer: 2, past2: true, pitch: -0x1000
        ))!
        precondition(running.animationID == SM64MarioWalkAnimationID.running)
        precondition(running.walkingPitch == -0x800 && running.sound == .terrain)
        fingerprint = hashResult(fingerprint, running)

        let metalTiptoe = SM64MarioWalkAnimation.update(input(
            intended: 3, forward: 2, timer: 1, past1: true, metal: true
        ))!
        precondition(metalTiptoe.animationID == SM64MarioWalkAnimationID.tiptoe)
        precondition(metalTiptoe.sound == .metalTiptoe)
        fingerprint = hashResult(fingerprint, metalTiptoe)

        let quicksand = SM64MarioWalkAnimation.update(input(
            intended: 16, forward: 8, quicksand: 60, past1: true
        ))!
        precondition(quicksand.animationID == SM64MarioWalkAnimationID.moveInQuicksand)
        precondition(quicksand.actionTimer == 0 && quicksand.sound == .quicksand)
        fingerprint = hashResult(fingerprint, quicksand)

        let postTiptoe = SM64MarioWalkAnimation.update(input(
            intended: 2, forward: 0, past23: true
        ))!
        precondition(postTiptoe.actionTimer == 2)
        fingerprint = hashResult(fingerprint, postTiptoe)

        precondition(SM64MarioWalkAnimation.update(input(
            intended: .infinity, forward: 0
        )) == nil)
        precondition(SM64MarioWalkAnimation.update(input(
            intended: 1, forward: 0, timer: 4
        )) == nil)

        print(String(format: "marioWalkAnimationFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario walk-animation smoke passed")
    }
}
