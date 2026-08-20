import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
@main struct SM64CastleFlagSmoke {
    static func main() { let fresh = SM64CastleFlagBehavior.update(.init(initialized: false, animationFrame: 0, randomFrame: 34)); let stable = SM64CastleFlagBehavior.update(.init(initialized: true, animationFrame: 12, randomFrame: 0)); precondition(fresh.animationFrame == 27 && fresh.timer == 1, "castle flag frame clamp"); precondition(stable.animationFrame == 12, "castle flag stable frame"); var f = offset; for output in [fresh, stable] { f = hash(f, UInt64(output.initialized ? 1 : 0)); f = hash(f, UInt64(output.animationFrame)); f = hash(f, UInt64(output.timer)) }; print(String(format: "castleFlagFingerprint=0x%016llx", f)); print("SM64 Modern castle-flag smoke passed") }
}
