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

private func append(
    _ output: SM64SeesawPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.facePitch))
    fingerprint = hashF32(fingerprint, output.pitchVelocity)
    fingerprint = hashU32(fingerprint, output.playsRockingSound ? 1 : 0)
}

@main
enum SM64ModernSeesawPlatformSmoke {
    static func main() {
        let defaultInit = SM64SeesawPlatformBehavior.initialize(behaviorByte: 1)
        let bitsInit = SM64SeesawPlatformBehavior.initialize(behaviorByte: 2)
        precondition(defaultInit.collisionModelIndex == 1)
        precondition(defaultInit.collisionDistanceOverride == nil)
        precondition(bitsInit.collisionModelIndex == 2)
        precondition(bitsInit.collisionDistanceOverride == 2000)

        let accelerating = SM64SeesawPlatformBehavior.update(
            SM64SeesawPlatformInput(
                facePitch: 0,
                pitchVelocity: 0,
                distanceToMario: 100,
                angleToMario: 0,
                moveAngleYaw: 0,
                marioIsOnPlatform: true
            )
        )
        let decelerating = SM64SeesawPlatformBehavior.update(
            SM64SeesawPlatformInput(
                facePitch: 0,
                pitchVelocity: 20,
                distanceToMario: 100,
                angleToMario: Int16(bitPattern: 0x8000),
                moveAngleYaw: 0,
                marioIsOnPlatform: true
            )
        )
        let clamped = SM64SeesawPlatformBehavior.update(
            SM64SeesawPlatformInput(
                facePitch: 0,
                pitchVelocity: 49,
                distanceToMario: 1000,
                angleToMario: 0,
                moveAngleYaw: 0,
                marioIsOnPlatform: true
            )
        )
        let returning = SM64SeesawPlatformBehavior.update(
            SM64SeesawPlatformInput(
                facePitch: 20,
                pitchVelocity: -4,
                distanceToMario: 0,
                angleToMario: 0,
                moveAngleYaw: 0,
                marioIsOnPlatform: false
            )
        )

        precondition(accelerating.pitchVelocity == 2 && accelerating.facePitch == 0)
        precondition(!accelerating.playsRockingSound)
        precondition(decelerating.pitchVelocity == 16 && decelerating.playsRockingSound)
        precondition(clamped.pitchVelocity == 50)
        precondition(returning.facePitch == 16 && returning.pitchVelocity == -7)

        var fingerprint = fnvOffset
        append(accelerating, to: &fingerprint)
        append(decelerating, to: &fingerprint)
        append(clamped, to: &fingerprint)
        append(returning, to: &fingerprint)
        print(String(format: "seesawPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern seesaw platform smoke passed")
    }
}
