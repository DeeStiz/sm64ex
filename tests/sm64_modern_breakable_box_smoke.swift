import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
@main struct SM64BreakableBoxSmoke {
    static func main() {
        let largeIdle = SM64BreakableBoxBehavior.update(.init(kind: .large, heldState: 0, action: 0, timer: 0, attacked: false, moveFlags: 0, lavaDeath: false, released: false, framesSinceReleased: 0, forwardVelocity: 0))
        let largeBreak = SM64BreakableBoxBehavior.update(.init(kind: .large, heldState: 0, action: 0, timer: 0, attacked: true, moveFlags: 0, lavaDeath: false, released: false, framesSinceReleased: 0, forwardVelocity: 0))
        let smallThrow = SM64BreakableBoxBehavior.update(.init(kind: .small, heldState: 2, action: 0, timer: 0, attacked: false, moveFlags: 0, lavaDeath: false, released: false, framesSinceReleased: 0, forwardVelocity: 0))
        let smallSlide = SM64BreakableBoxBehavior.update(.init(kind: .small, heldState: 0, action: 0, timer: 0, attacked: false, moveFlags: 1, lavaDeath: false, released: false, framesSinceReleased: 0, forwardVelocity: 25))
        let smallBreak = SM64BreakableBoxBehavior.update(.init(kind: .small, heldState: 0, action: 0, timer: 0, attacked: false, moveFlags: 2, lavaDeath: false, released: false, framesSinceReleased: 0, forwardVelocity: 10))
        let smallRespawn = SM64BreakableBoxBehavior.update(.init(kind: .small, heldState: 0, action: 0, timer: 0, attacked: false, moveFlags: 0, lavaDeath: false, released: false, framesSinceReleased: 901, forwardVelocity: 0))
        precondition(!largeIdle.shouldDelete && largeIdle.loadCollisionModel, "large box idle")
        precondition(largeBreak.shouldDelete && largeBreak.spawnCoins == 1 && largeBreak.playBreakSound, "large box break")
        precondition(smallThrow.forwardVelocity == 40 && smallThrow.velocityY == 20, "small box thrown")
        precondition(smallSlide.playLandingSound && smallSlide.spawnDust, "small box landing slide")
        precondition(smallBreak.shouldDelete && smallBreak.spawnCoins == 3 && smallBreak.spawnTriangles, "small box break")
        precondition(smallRespawn.shouldDelete && smallRespawn.shouldRespawn, "small box respawn fence")
        var fingerprint = offset
        for output in [largeIdle, largeBreak, smallThrow, smallSlide, smallBreak, smallRespawn] {
            fingerprint = hash(fingerprint, UInt64(output.kind.rawValue)); fingerprint = hash(fingerprint, output.action); fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, UInt64(output.visible ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.tangible ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.shouldRespawn ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.model)); fingerprint = hash(fingerprint, output.scale); fingerprint = hash(fingerprint, output.hitboxRadius); fingerprint = hash(fingerprint, output.hitboxHeight); fingerprint = hash(fingerprint, output.forwardVelocity); fingerprint = hash(fingerprint, output.velocityY); fingerprint = hash(fingerprint, output.spawnCoins); fingerprint = hash(fingerprint, UInt64(output.spawnDust ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.spawnMist ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.spawnTriangles ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.playLandingSound ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.playBreakSound ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.loadCollisionModel ? 1 : 0))
        }
        print(String(format: "breakableBoxFingerprint=0x%016llx", fingerprint)); print("SM64 Modern breakable-box smoke passed")
    }
}
