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

private func append(
    _ output: SM64DecorativePendulumOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceRoll))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.angleVelocityRoll))
    fingerprint = hashU32(fingerprint, output.playsClockSound ? 1 : 0)
}

@main
enum SM64ModernDecorativePendulumSmoke {
    static func main() {
        let initialization = SM64DecorativePendulumBehavior.initialize()
        precondition(initialization.angleVelocityRoll == 0x100)
        precondition(initialization.initializesRoom)

        let rising = SM64DecorativePendulumBehavior.update(
            SM64DecorativePendulumInput(faceRoll: 100, angleVelocityRoll: 0x20)
        )
        let soundPositive = SM64DecorativePendulumBehavior.update(
            SM64DecorativePendulumInput(faceRoll: 100, angleVelocityRoll: 0x18)
        )
        let soundNegative = SM64DecorativePendulumBehavior.update(
            SM64DecorativePendulumInput(faceRoll: -100, angleVelocityRoll: -0x18)
        )
        let falling = SM64DecorativePendulumBehavior.update(
            SM64DecorativePendulumInput(faceRoll: -100, angleVelocityRoll: 0)
        )

        precondition(rising.faceRoll == 124 && rising.angleVelocityRoll == 0x18)
        precondition(!rising.playsClockSound)
        precondition(soundPositive.playsClockSound)
        precondition(soundNegative.playsClockSound)
        precondition(falling.faceRoll == -92 && falling.angleVelocityRoll == 8)

        var fingerprint = fnvOffset
        append(rising, to: &fingerprint)
        append(soundPositive, to: &fingerprint)
        append(soundNegative, to: &fingerprint)
        append(falling, to: &fingerprint)
        print(String(format: "decorativePendulumFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern decorative pendulum smoke passed")
    }
}
