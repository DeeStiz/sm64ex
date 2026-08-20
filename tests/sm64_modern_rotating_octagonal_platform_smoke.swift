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
    _ initialization: SM64RotatingOctagonalPlatformInitialization,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(initialization.collisionModelIndex))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: initialization.angleVelocityYaw))
}

private func append(
    _ output: SM64RotatingOctagonalPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceYaw))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.angleVelocityYaw))
}

@main
enum SM64ModernRotatingOctagonalPlatformSmoke {
    static func main() {
        let slow = SM64RotatingOctagonalPlatformBehavior.initialize(
            collisionModelIndex: 0, speedIndex: 0
        )
        let reverseFast = SM64RotatingOctagonalPlatformBehavior.initialize(
            collisionModelIndex: 1, speedIndex: 3
        )
        let clockwise = SM64RotatingOctagonalPlatformBehavior.update(
            SM64RotatingOctagonalPlatformInput(faceYaw: 0x1000, angleVelocityYaw: 300)
        )
        let counter = SM64RotatingOctagonalPlatformBehavior.update(
            SM64RotatingOctagonalPlatformInput(faceYaw: 0x1000, angleVelocityYaw: -600)
        )
        precondition(slow == SM64RotatingOctagonalPlatformInitialization(
            collisionModelIndex: 0, angleVelocityYaw: 300
        ))
        precondition(reverseFast == SM64RotatingOctagonalPlatformInitialization(
            collisionModelIndex: 1, angleVelocityYaw: -600
        ))
        precondition(clockwise == SM64RotatingOctagonalPlatformOutput(
            faceYaw: 0x112C, angleVelocityYaw: 300
        ))
        precondition(counter == SM64RotatingOctagonalPlatformOutput(
            faceYaw: 0x0DA8, angleVelocityYaw: -600
        ))
        var fingerprint = fnvOffset
        append(slow, to: &fingerprint)
        append(reverseFast, to: &fingerprint)
        append(clockwise, to: &fingerprint)
        append(counter, to: &fingerprint)
        print(String(format: "rotatingOctagonalPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern rotating octagonal platform smoke passed")
    }
}
