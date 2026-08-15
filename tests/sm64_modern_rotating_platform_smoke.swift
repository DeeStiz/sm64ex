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

private func append(_ output: SM64RotatingPlatformOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.angleVelocityYaw)))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.faceYaw)))
    fingerprint = hashU32(fingerprint, output.playsLoopSound ? 1 : 0)
}

@main
enum SM64ModernRotatingPlatformSmoke {
    static func main() {
        let waiting = SM64RotatingPlatformBehavior.update(
            SM64RotatingPlatformInput(action: 0, timer: 60, speedByte: 0x08, faceYaw: 0x1000)
        )
        let starts = SM64RotatingPlatformBehavior.update(
            SM64RotatingPlatformInput(action: 0, timer: 61, speedByte: 0x08, faceYaw: 0x1000)
        )
        let spinning = SM64RotatingPlatformBehavior.update(
            SM64RotatingPlatformInput(action: 1, timer: 10, speedByte: -8, faceYaw: 0x1000)
        )
        let stops = SM64RotatingPlatformBehavior.update(
            SM64RotatingPlatformInput(action: 1, timer: 127, speedByte: 0x08, faceYaw: 0x1000)
        )
        precondition(waiting.action == 0 && waiting.angleVelocityYaw == 0)
        precondition(starts.action == 1 && starts.angleVelocityYaw == 0)
        precondition(spinning.angleVelocityYaw == -0x80 && spinning.faceYaw == 0x0F80)
        precondition(spinning.playsLoopSound && stops.action == 0)

        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(starts, to: &fingerprint)
        append(spinning, to: &fingerprint)
        append(stops, to: &fingerprint)
        print(String(format: "rotatingPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern rotating platform smoke passed")
    }
}
