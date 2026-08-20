import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

@main
struct SM64CollectStarSmoke {
    static func main() {
        let fresh = SM64CollectStarBehavior.update(.init(starCollected: false, faceYaw: 0x4000, interactionStatus: 0))
        let collected = SM64CollectStarBehavior.update(.init(starCollected: true, faceYaw: 0x4800, interactionStatus: 0))
        let interacted = SM64CollectStarBehavior.update(.init(starCollected: false, faceYaw: 0, interactionStatus: 1))
        precondition(fresh.model == .star && fresh.faceYaw == 0x4800 && fresh.hitboxRadius == 80 && fresh.hitboxHeight == 50 && !fresh.shouldDelete)
        precondition(collected.model == .transparentStar && collected.faceYaw == 0x5000 && !collected.shouldDelete)
        precondition(interacted.shouldDelete && interacted.clearInteraction)

        var fingerprint = fnvOffset
        for output in [fresh, collected, interacted] {
            fingerprint = hash(fingerprint, UInt64(output.model.rawValue))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.faceYaw)))
            fingerprint = hash(fingerprint, UInt64(output.hitboxRadius.bitPattern))
            fingerprint = hash(fingerprint, UInt64(output.hitboxHeight.bitPattern))
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.clearInteraction ? 1 : 0))
        }
        print(String(format: "collectStarFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern collect-star smoke passed")
    }
}
