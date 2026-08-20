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
struct SM64DddWarpSmoke {
    static func main() {
        let before = SM64DddWarpBehavior.update(.init(paintingBeaten: false))
        let after = SM64DddWarpBehavior.update(.init(paintingBeaten: true))
        precondition(before.collisionDataIdentity == SM64DddWarpBehavior.preBossCollisionIdentity)
        precondition(after.collisionDataIdentity == SM64DddWarpBehavior.postBossCollisionIdentity)
        precondition(before.collisionDistance == 30_000 && after.collisionDistance == 30_000)
        precondition(before.shouldLoadCollisionModel && after.shouldLoadCollisionModel)

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, before.collisionDataIdentity)
        fingerprint = hash(fingerprint, UInt64(before.collisionDistance.bitPattern))
        fingerprint = hash(fingerprint, UInt64(before.shouldLoadCollisionModel ? 1 : 0))
        fingerprint = hash(fingerprint, after.collisionDataIdentity)
        fingerprint = hash(fingerprint, UInt64(after.collisionDistance.bitPattern))
        fingerprint = hash(fingerprint, UInt64(after.shouldLoadCollisionModel ? 1 : 0))
        print(String(format: "dddWarpFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern DDD warp smoke passed")
    }
}
