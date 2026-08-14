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

private func hashDecision(_ initial: UInt64, _ decision: SM64MarioActionDecision) -> UInt64 {
    var hash = hashU32(initial, decision.action ?? UInt32.max)
    hash = hashU32(hash, decision.argument)
    hash = hashU16(hash, UInt16(bitPattern: decision.faceYaw ?? Int16.min))
    return hashU8(hash, decision.shouldDropHeldObject ? 1 : 0)
}

private func state(
    input: SM64MarioInputFlags = [],
    health: Int16 = 0x880,
    quicksand: Float = 0,
    actionArgument: UInt32 = 0,
    actionState: UInt16 = 0,
    intendedYaw: Int16 = 0x1234
) -> SM64MarioState {
    var result = SM64MarioState()
    result.input = input
    result.health = health
    result.quicksandDepth = quicksand
    result.actionArgument = actionArgument
    result.actionState = actionState
    result.intendedYaw = intendedYaw
    return result
}

@main
enum SM64ModernMarioActionCancelsSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let held = SM64MarioActionCancelContext(heldObjectPresent: true)

        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.idle(state: state(quicksand: 31), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.idle(state: state(input: [.inPoisonGas, .aPressed]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.commonIdle(state: state(input: [.unknown10, .aPressed]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.commonIdle(state: state(input: [.nonzeroAnalog]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.commonIdle(state: state(input: [.bPressed]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.commonIdle(state: state(input: [.zDown]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.idle(state: state(health: 0x2FF), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.idle(
                state: state(actionState: 3),
                context: SM64MarioActionCancelContext(terrainIsSnow: true)
            )
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.idle(state: state(actionState: 3), context: .init())
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.crouching(state: state(input: [.zDown, .nonzeroAnalog]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.crouching(state: state(input: [.zDown, .bPressed]), context: held)
        )
        fingerprint = hashDecision(
            fingerprint,
            SM64MarioActionCancels.startCrouching(state: state(input: [.aPressed]), context: held)
        )
        print(String(format: "marioActionCancelsFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario action-cancels smoke passed")
    }
}
