private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 24, by: 8) {
        result ^= UInt64((value >> UInt32(shift)) & 0xFF)
        result &*= fnvPrime
    }
    return result
}

private func hashBool(_ hash: UInt64, _ value: Bool) -> UInt64 {
    hashU32(hash, value ? 1 : 0)
}

private func record(
    _ hash: UInt64,
    state: SM64CheatState,
    health: UInt16,
    lives: UInt8,
    forwardVelocity: Float,
    currentVelocity: Float,
    lTriggerDown: Bool,
    actionAllowsPauseExit: Bool
) -> UInt64 {
    var result = hash
    for value in [
        state.enabled, state.moonJump, state.godMode, state.infiniteLives,
        state.superSpeed, state.responsive, state.exitAnywhere,
        state.hugeMario, state.tinyMario
    ] {
        result = hashBool(result, value)
    }
    let moonVelocity = SM64CheatPolicy.moonJumpVelocity(
        currentVelocity: currentVelocity,
        lTriggerDown: lTriggerDown,
        state: state
    )
    let action = SM64CheatPolicy.applyMarioAction(
        health: health, lives: lives,
        forwardVelocity: forwardVelocity, state: state
    )
    result = hashU32(result, moonVelocity.bitPattern)
    result = hashU32(result, UInt32(action.health))
    result = hashU32(result, UInt32(action.lives))
    result = hashU32(result, action.forwardVelocity.bitPattern)
    result = hashU32(result, SM64CheatPolicy.modelScale(for: state).bitPattern)
    result = hashBool(
        result,
        SM64CheatPolicy.canExitCourse(
            actionAllowsPauseExit: actionAllowsPauseExit, state: state
        )
    )
    return hashBool(
        result, SM64CheatPolicy.responsiveMovementEnabled(for: state)
    )
}

@main
enum SM64ModernCheatsSmoke {
    static func main() {
        let disabled = SM64CheatState.disabled
        var all = SM64CheatState(
            enabled: true,
            moonJump: true,
            godMode: true,
            infiniteLives: true,
            superSpeed: true,
            responsive: true,
            exitAnywhere: true,
            hugeMario: true,
            tinyMario: true
        )
        var fingerprint = fnvOffset
        fingerprint = record(
            fingerprint, state: disabled,
            health: 100, lives: 7, forwardVelocity: 10,
            currentVelocity: 3, lTriggerDown: true,
            actionAllowsPauseExit: false
        )
        fingerprint = record(
            fingerprint, state: all,
            health: 100, lives: 7, forwardVelocity: 10,
            currentVelocity: 3, lTriggerDown: true,
            actionAllowsPauseExit: false
        )
        fingerprint = record(
            fingerprint, state: all,
            health: 0x0400, lives: 99, forwardVelocity: 0,
            currentVelocity: 25, lTriggerDown: false,
            actionAllowsPauseExit: true
        )

        all.godMode = false
        all.infiniteLives = false
        all.superSpeed = false
        all.exitAnywhere = false
        all.hugeMario = false
        all.tinyMario = false
        fingerprint = record(
            fingerprint, state: all,
            health: 100, lives: 7, forwardVelocity: 10,
            currentVelocity: 3, lTriggerDown: true,
            actionAllowsPauseExit: false
        )

        precondition(
            SM64CheatPolicy.moonJumpVelocity(
                currentVelocity: 3, lTriggerDown: true, state: disabled
            ) == 3
        )
        precondition(SM64CheatPolicy.modelScale(for: disabled) == 1)
        print("cheatFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern cheats smoke passed")
    }
}
