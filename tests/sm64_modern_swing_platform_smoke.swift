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

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func append(_ output: SM64SwingPlatformOutput, to fingerprint: inout UInt64) {
    fingerprint = hashF32(fingerprint, output.angle)
    fingerprint = hashF32(fingerprint, output.speed)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceRoll))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.angleVelocityRoll))
}

@main
enum SM64ModernSwingPlatformSmoke {
    static func main() {
        precondition(SM64SwingPlatformBehavior.initialize() == 8192)

        let clockwise = SM64SwingPlatformBehavior.update(
            SM64SwingPlatformInput(angle: 8192, speed: 0, faceRoll: 0)
        )
        let counterClockwise = SM64SwingPlatformBehavior.update(
            SM64SwingPlatformInput(angle: -2, speed: 0, faceRoll: -2)
        )
        let fractional = SM64SwingPlatformBehavior.update(
            SM64SwingPlatformInput(angle: 12.75, speed: 1.5, faceRoll: 12)
        )
        let negativeFractional = SM64SwingPlatformBehavior.update(
            SM64SwingPlatformInput(angle: -12.75, speed: -1.5, faceRoll: -12)
        )

        precondition(clockwise.speed == -4 && clockwise.faceRoll == 8188)
        precondition(clockwise.angleVelocityRoll == 8188)
        precondition(counterClockwise.speed == 4 && counterClockwise.faceRoll == 2)
        precondition(fractional.faceRoll == 10 && fractional.angleVelocityRoll == -2)
        precondition(negativeFractional.faceRoll == -10 && negativeFractional.angleVelocityRoll == 2)

        var fingerprint = fnvOffset
        append(clockwise, to: &fingerprint)
        append(counterClockwise, to: &fingerprint)
        append(fractional, to: &fingerprint)
        append(negativeFractional, to: &fingerprint)
        print(String(format: "swingPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern swing platform smoke passed")
    }
}
