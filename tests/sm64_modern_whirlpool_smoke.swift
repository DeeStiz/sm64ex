import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

@main
struct SM64WhirlpoolSmoke {
    static func main() {
        let near = SM64WhirlpoolBehavior.update(.init(distanceToMario: 4_000, position: .zero, initialFacePitch: 0x1000, initialFaceRoll: 0x2000, facePitch: 0, faceRoll: 0, faceYaw: 0, timer: 0))
        let far = SM64WhirlpoolBehavior.update(.init(distanceToMario: 6_000, position: .zero, initialFacePitch: 0, initialFaceRoll: 0, facePitch: 0, faceRoll: 0, faceYaw: 0x1F40, timer: 1))
        precondition(near.particleCount == 60 && near.visible && near.faceYaw == 0x1F40)
        precondition(far.particleCount == 0 && !far.visible && far.faceYaw == 0x3E80)
        var fingerprint = offset
        for output in [near, far] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.faceYaw)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.particleCount)))
            fingerprint = hash(fingerprint, output.visible ? 1 : 0)
        }
        print(String(format: "whirlpoolFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern whirlpool smoke passed")
    }
}
