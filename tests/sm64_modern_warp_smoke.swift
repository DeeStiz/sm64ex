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
struct SM64WarpSmoke {
    static func main() {
        let normalZero = SM64WarpBehavior.update(.init(variant: .normal, behaviorByte: 0, timer: 0, interactionStatus: 7))
        let normalMax = SM64WarpBehavior.update(.init(variant: .normal, behaviorByte: 0xFF, timer: 1, interactionStatus: 9))
        let normalSeven = SM64WarpBehavior.update(.init(variant: .normal, behaviorByte: 7, timer: 2, interactionStatus: 11))
        let fadingZero = SM64WarpBehavior.update(.init(variant: .fading, behaviorByte: 0, timer: 0, interactionStatus: 3))
        let fadingSeven = SM64WarpBehavior.update(.init(variant: .fading, behaviorByte: 7, timer: 1, interactionStatus: 5))
        let pipe = SM64WarpBehavior.update(.init(variant: .pipe, behaviorByte: 7, timer: 0, interactionStatus: 1))
        let exitPodium = SM64WarpBehavior.update(.init(variant: .exitPodium, behaviorByte: 0xFF, timer: 0, interactionStatus: 1))

        precondition(normalZero.hitboxRadius == 50 && normalZero.hitboxHeight == 50 && normalZero.interactionSubtype == 0 && normalZero.clearInteraction)
        precondition(normalMax.hitboxRadius == 10_000 && normalSeven.hitboxRadius == 70)
        precondition(fadingZero.hitboxRadius == 85 && fadingZero.interactionSubtype == 1 && fadingSeven.hitboxRadius == 70)
        precondition(pipe.hitboxRadius == 70 && pipe.collisionModel && pipe.hitboxHeight == 50)
        precondition(exitPodium.hitboxRadius == 50 && exitPodium.collisionModel && exitPodium.collisionDataIdentity == 0x74746D5F706F6469)

        var fingerprint = fnvOffset
        for output in [normalZero, normalMax, normalSeven, fadingZero, fadingSeven, pipe, exitPodium] {
            fingerprint = hash(fingerprint, UInt64(output.variant.rawValue))
            fingerprint = hash(fingerprint, UInt64(output.hitboxRadius.bitPattern))
            fingerprint = hash(fingerprint, UInt64(output.hitboxHeight.bitPattern))
            fingerprint = hash(fingerprint, UInt64(output.interactionSubtype))
            fingerprint = hash(fingerprint, UInt64(output.clearInteraction ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.collisionModel ? 1 : 0))
            fingerprint = hash(fingerprint, output.collisionDataIdentity)
        }
        print(String(format: "warpFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern warp smoke passed")
    }
}
