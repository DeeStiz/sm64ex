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
    _ output: SM64StaticCheckeredPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.facePitch))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceYaw))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceRoll))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.velocityPitch))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.velocityYaw))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.velocityRoll))
}

@main
enum SM64ModernStaticCheckeredPlatformSmoke {
    static func main() {
        let free = SM64StaticCheckeredPlatformBehavior.update(SM64StaticCheckeredPlatformInput(
            mode: 0, facePitch: 100, faceYaw: 200, faceRoll: 300,
            velocityPitch: 1, velocityYaw: 2, velocityRoll: 3,
            debugPitch: 9, debugYaw: 8, debugRoll: 7,
            debugVelocityPitch: -4, debugVelocityYaw: -5, debugVelocityRoll: -6
        ))
        let reset = SM64StaticCheckeredPlatformBehavior.update(SM64StaticCheckeredPlatformInput(
            mode: 1, facePitch: 100, faceYaw: 200, faceRoll: 300,
            velocityPitch: 1, velocityYaw: 2, velocityRoll: 3,
            debugPitch: 9, debugYaw: 8, debugRoll: 7,
            debugVelocityPitch: 7, debugVelocityYaw: -8, debugVelocityRoll: 9
        ))
        let set = SM64StaticCheckeredPlatformBehavior.update(SM64StaticCheckeredPlatformInput(
            mode: 2, facePitch: 100, faceYaw: 200, faceRoll: 300,
            velocityPitch: 1, velocityYaw: 2, velocityRoll: 3,
            debugPitch: 1, debugYaw: -2, debugRoll: 3,
            debugVelocityPitch: 10, debugVelocityYaw: 20, debugVelocityRoll: 30
        ))
        let rotate = SM64StaticCheckeredPlatformBehavior.update(SM64StaticCheckeredPlatformInput(
            mode: 3, facePitch: 100, faceYaw: 200, faceRoll: 300,
            velocityPitch: 1, velocityYaw: 2, velocityRoll: 3,
            debugPitch: 9, debugYaw: 8, debugRoll: 7,
            debugVelocityPitch: 7, debugVelocityYaw: -8, debugVelocityRoll: 9
        ))
        precondition(free == SM64StaticCheckeredPlatformOutput(
            facePitch: 100, faceYaw: 200, faceRoll: 300,
            velocityPitch: -4, velocityYaw: -5, velocityRoll: -6
        ))
        precondition(reset == SM64StaticCheckeredPlatformOutput(
            facePitch: 0, faceYaw: 0, faceRoll: 0,
            velocityPitch: 7, velocityYaw: -8, velocityRoll: 9
        ))
        precondition(set == SM64StaticCheckeredPlatformOutput(
            facePitch: 4096, faceYaw: -8192, faceRoll: 12288,
            velocityPitch: 10, velocityYaw: 20, velocityRoll: 30
        ))
        precondition(rotate == SM64StaticCheckeredPlatformOutput(
            facePitch: 107, faceYaw: 192, faceRoll: 309,
            velocityPitch: 7, velocityYaw: -8, velocityRoll: 9
        ))
        var fingerprint = fnvOffset
        append(free, to: &fingerprint)
        append(reset, to: &fingerprint)
        append(set, to: &fingerprint)
        append(rotate, to: &fingerprint)
        print(String(format: "staticCheckeredPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern static checkered platform smoke passed")
    }
}
