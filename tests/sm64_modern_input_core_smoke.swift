import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 {
        hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashState(_ initial: UInt64, _ state: SM64ControllerState) -> UInt64 {
    var hash = initial
    hash = hashU16(hash, UInt16(bitPattern: state.rawStickX))
    hash = hashU16(hash, UInt16(bitPattern: state.rawStickY))
    hash = hashU16(hash, UInt16(bitPattern: state.extStickX))
    hash = hashU16(hash, UInt16(bitPattern: state.extStickY))
    hash = hashU32(hash, state.stickX.bitPattern)
    hash = hashU32(hash, state.stickY.bitPattern)
    hash = hashU32(hash, state.stickMagnitude.bitPattern)
    hash = hashU16(hash, state.buttonDown)
    return hashU16(hash, state.buttonPressed)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernInputCoreSmoke {
    static func main() {
        let a: UInt16 = 0x8000
        let b: UInt16 = 0x4000
        var normalizer = SM64ControllerInputNormalizer()
        let samples: [(SM64ControllerRawSample, Bool)] = [
            (SM64ControllerRawSample(buttons: a), true),
            (SM64ControllerRawSample(buttons: a, rawStickX: 7, rawStickY: -7), false),
            (SM64ControllerRawSample(buttons: a | b, rawStickX: 8, rawStickY: -8), false),
            (SM64ControllerRawSample(buttons: b, rawStickX: 63, rawStickY: -63), true),
            (SM64ControllerRawSample(buttons: 0, rawStickX: -128, rawStickY: 127), true),
            (SM64ControllerRawSample(connected: false), true),
        ]

        var fingerprint = fnvOffset
        var states: [SM64ControllerState] = []
        for (sample, advanceLegacyDomain) in samples {
            let state = normalizer.update(sample, advanceLegacyDomain: advanceLegacyDomain)
            states.append(state)
            fingerprint = hashState(fingerprint, state)
        }
        require(states[0].buttonPressed == a, "first rising edge")
        require(states[1].buttonPressed == 0 && states[1].stickX == 0, "held edge and deadzone")
        require(states[2].buttonPressed == 0 && states[2].stickX == 2 && states[2].stickY == -2, "native hold")
        require(states[3].buttonPressed == b && states[3].stickMagnitude == 64, "logical edge and clamp")
        require(states[5] == .disconnected, "disconnect reset")
        print(String(format: "inputCoreFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern input core smoke passed")
    }
}
