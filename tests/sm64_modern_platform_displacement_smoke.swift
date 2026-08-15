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
    _ output: SM64PlatformDisplacementOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, output.position.x.bitPattern)
    fingerprint = hashU32(fingerprint, output.position.y.bitPattern)
    fingerprint = hashU32(fingerprint, output.position.z.bitPattern)
    fingerprint = hashU32(
        fingerprint,
        UInt32(UInt16(bitPattern: output.faceYaw))
    )
    fingerprint = hashU32(fingerprint, output.rotationApplied ? 1 : 0)
}

@main
enum SM64ModernPlatformDisplacementSmoke {
    static func main() {
        let mario = SM64PlatformDisplacement.apply(
            SM64PlatformDisplacementInput(
                position: .init(x: 12.5, y: 40, z: -8),
                platformPosition: .init(x: 10, y: 20, z: 30),
                platformVelocity: .init(x: 3, y: 9, z: -4),
                angleVelocity: .init(pitch: 0x0400, yaw: 0x0800, roll: 0x0200),
                faceAngles: .init(pitch: 0x1000, yaw: 0x2000, roll: 0x3000),
                nativeStepScale: 0.5,
                isMario: true,
                faceYaw: 0x1111
            )
        )
        let object = SM64PlatformDisplacement.apply(
            SM64PlatformDisplacementInput(
                position: .init(x: -4, y: 1.5, z: 8),
                platformPosition: .init(x: 0, y: 0, z: 0),
                platformVelocity: .init(x: 2, y: -3, z: 5),
                angleVelocity: .zero,
                faceAngles: .init(pitch: 0x2000, yaw: 0x3000, roll: 0x4000),
                nativeStepScale: 2,
                isMario: false,
                faceYaw: 0x2222
            )
        )
        precondition(mario.rotationApplied && !object.rotationApplied)
        precondition(mario.faceYaw == Int16(bitPattern: 0x1911))
        precondition(object.position == .init(x: 0, y: 1.5, z: 18))

        var fingerprint = fnvOffset
        append(mario, to: &fingerprint)
        append(object, to: &fingerprint)
        print(String(format: "platformDisplacementFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern platform displacement smoke passed")
    }
}
