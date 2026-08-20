import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt32) -> UInt64 {
    var result = seed
    for byte in 0..<4 { result ^= UInt64((value >> UInt32(byte * 8)) & 0xff); result &*= prime }
    return result
}
@main
enum SM64ModernTiltingBowserLavaPlatformSmoke {
    static func main() {
        let output = SM64TiltingBowserLavaPlatformBehavior.update(.init(
            faceAngles: .init(pitch: 0x1000, yaw: 0x8000, roll: -0x200),
            angleVelocity: .init(pitch: 3, yaw: -0x400, roll: 7)
        ))
        precondition(output.faceAngles == .init(pitch: 0x1003, yaw: 0x7C00, roll: -0x1F9))
        precondition(output.collisionModelRequested)
        var fingerprint = offset
        fingerprint = hash(fingerprint, UInt32(bitPattern: output.faceAngles.pitch))
        fingerprint = hash(fingerprint, UInt32(bitPattern: output.faceAngles.yaw))
        fingerprint = hash(fingerprint, UInt32(bitPattern: output.faceAngles.roll))
        print(String(format: "tiltingBowserLavaPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern tilting Bowser lava platform smoke passed")
    }
}
