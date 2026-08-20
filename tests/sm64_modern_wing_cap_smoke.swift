import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
@main struct SM64WingCapSmoke {
    static func main() {
        let rolling = SM64WingCapBehavior.update(.init(action: 0, timer: 0, faceYaw: 100, forwardVelocity: 2, interacted: false))
        let tangible = SM64WingCapBehavior.update(.init(action: 0, timer: 21, faceYaw: 0, forwardVelocity: 0, interacted: false))
        precondition(rolling.faceYaw == 356 && !rolling.tangible && tangible.tangible && tangible.opacity == 255)
        var fingerprint = offset; for output in [rolling, tangible] { fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.action))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.faceYaw))); fingerprint = hash(fingerprint, UInt64(output.gravity.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.opacity)); fingerprint = hash(fingerprint, output.tangible ? 1 : 0) }
        print(String(format: "wingCapFingerprint=0x%016llx", fingerprint)); print("SM64 Modern wing cap smoke passed")
    }
}
