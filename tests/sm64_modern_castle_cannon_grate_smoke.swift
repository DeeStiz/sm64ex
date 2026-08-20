import Foundation
private let off: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= prime }; return result }
@main struct GrateSmoke {
    static func main() {
        let below = SM64CastleCannonGrateBehavior.update(.init(totalStarCount: 119))
        let at = SM64CastleCannonGrateBehavior.update(.init(totalStarCount: 120))
        precondition(!below.shouldDeactivate && at.shouldDeactivate && below.collisionDistance == 4000 && at.shouldLoadCollisionModel)
        var fingerprint = off; fingerprint = hash(fingerprint, 0); fingerprint = hash(fingerprint, 1); fingerprint = hash(fingerprint, UInt64(below.collisionDistance.bitPattern)); fingerprint = hash(fingerprint, UInt64(at.shouldDeactivate ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(at.shouldLoadCollisionModel ? 1 : 0))
        print(String(format: "castleCannonGrateFingerprint=0x%016llx", fingerprint)); print("SM64 Modern castle cannon grate smoke passed")
    }
}
