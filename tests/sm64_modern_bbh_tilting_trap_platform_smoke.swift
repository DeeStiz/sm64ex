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
    _ output: SM64BBHTiltingTrapPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.facePitch))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.angleVelocityPitch))
}

@main
enum SM64ModernBBHTiltingTrapPlatformSmoke {
    static func main() {
        let marioOn = SM64BBHTiltingTrapPlatformBehavior.update(
            SM64BBHTiltingTrapPlatformInput(
                timer: 0, previousAction: 0, distanceToMario: 500, angleToMario: 0,
                facePitch: 100, angleVelocityPitch: 0, marioOnPlatform: true
            )
        )
        let returning = SM64BBHTiltingTrapPlatformBehavior.update(
            SM64BBHTiltingTrapPlatformInput(
                timer: 0, previousAction: 0, distanceToMario: 0, angleToMario: 0,
                facePitch: 150, angleVelocityPitch: -200, marioOnPlatform: false
            )
        )
        let grace = SM64BBHTiltingTrapPlatformBehavior.update(
            SM64BBHTiltingTrapPlatformInput(
                timer: 0, previousAction: 0, distanceToMario: 0, angleToMario: 0,
                facePitch: 5000, angleVelocityPitch: -200, marioOnPlatform: false
            )
        )
        let released = SM64BBHTiltingTrapPlatformBehavior.update(
            SM64BBHTiltingTrapPlatformInput(
                timer: 16, previousAction: 0, distanceToMario: 0, angleToMario: 0,
                facePitch: 5000, angleVelocityPitch: -200, marioOnPlatform: false
            )
        )
        let negative = SM64BBHTiltingTrapPlatformBehavior.update(
            SM64BBHTiltingTrapPlatformInput(
                timer: 0, previousAction: 0, distanceToMario: 0, angleToMario: 0,
                facePitch: -5000, angleVelocityPitch: 200, marioOnPlatform: false
            )
        )
        precondition(marioOn == SM64BBHTiltingTrapPlatformOutput(
            action: 0, facePitch: 600, angleVelocityPitch: 500
        ))
        precondition(returning == SM64BBHTiltingTrapPlatformOutput(
            action: 1, facePitch: 0, angleVelocityPitch: 0
        ))
        precondition(grace == SM64BBHTiltingTrapPlatformOutput(
            action: 1, facePitch: 4800, angleVelocityPitch: -200
        ))
        precondition(released == grace)
        precondition(negative == SM64BBHTiltingTrapPlatformOutput(
            action: 1, facePitch: -4800, angleVelocityPitch: 200
        ))
        var fingerprint = fnvOffset
        append(marioOn, to: &fingerprint)
        append(returning, to: &fingerprint)
        append(grace, to: &fingerprint)
        append(released, to: &fingerprint)
        append(negative, to: &fingerprint)
        print(String(format: "bbhTiltingTrapPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern BBH tilting trap platform smoke passed")
    }
}
