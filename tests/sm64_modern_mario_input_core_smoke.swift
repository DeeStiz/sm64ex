import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

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

private func hashState(_ initial: UInt64, _ state: SM64MarioInputState) -> UInt64 {
    var hash = hashU16(initial, state.input.rawValue)
    hash = hashU32(hash, state.intendedMagnitude.bitPattern)
    hash = hashU16(hash, UInt16(bitPattern: state.intendedYaw))
    hash = hashU16(hash, UInt16(state.framesSinceA))
    return hashU16(hash, UInt16(state.framesSinceB))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernMarioInputCoreSmoke {
    static func main() {
        var normalizer = SM64ControllerInputNormalizer()
        let firstController = normalizer.update(
            SM64ControllerRawSample(buttons: 0x8000, rawStickX: 38),
            advanceLegacyDomain: true
        )
        let first = SM64MarioInputCore.update(
            controller: firstController,
            squishTimer: 0,
            previousFramesSinceA: 7,
            previousFramesSinceB: 9,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        let secondController = normalizer.update(
            SM64ControllerRawSample(buttons: 0),
            advanceLegacyDomain: true
        )
        let second = SM64MarioInputCore.update(
            controller: secondController,
            squishTimer: 1,
            previousFramesSinceA: first.framesSinceA,
            previousFramesSinceB: first.framesSinceB,
            faceYaw: 0x1111,
            cameraYaw: 0x0200,
            firstPerson: true,
            interactionUnknown10: true,
            geometryFlags: [.inWater, .offFloor]
        )
        require(first.input == [.nonzeroAnalog, .aPressed, .aDown], "button and analog flags")
        require(first.intendedMagnitude == 8 && first.intendedYaw == 0x4200, "first joystick derivation")
        require(first.framesSinceA == 0 && first.framesSinceB == 10, "first frame timers")
        require(second.input == [.unknown5, .firstPerson, .unknown10, .inWater, .offFloor], "geometry and fallback flags")
        require(second.intendedMagnitude == 0 && second.intendedYaw == 0x1111, "second joystick derivation")

        var fingerprint = fnvOffset
        fingerprint = hashState(fingerprint, first)
        fingerprint = hashState(fingerprint, second)
        print(String(format: "marioInputCoreFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario input core smoke passed")
    }
}
