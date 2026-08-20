import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64WfBreakableWallOutput) -> [UInt64] { [output.tangible ? 1 : 0, output.exploded ? 1 : 0, output.playPuzzleJingle ? 1 : 0, output.playWallExplosion ? 1 : 0, UInt64(output.interactionType), UInt64(bitPattern: Int64(output.damageOrCoinValue)), UInt64(bitPattern: Int64(output.spawnCoins))] }

@main
struct SM64WfBreakableWallSmoke {
    static func main() {
        let idle = SM64WfBreakableWallBehavior.update(.init(marioShotFromCannon: false, collidedWithMario: true, rightVariant: true))
        let left = SM64WfBreakableWallBehavior.update(.init(marioShotFromCannon: true, collidedWithMario: true, rightVariant: false))
        let right = SM64WfBreakableWallBehavior.update(.init(marioShotFromCannon: true, collidedWithMario: true, rightVariant: true))
        precondition(!idle.tangible && !idle.exploded)
        precondition(left.tangible && left.exploded && left.playWallExplosion && !left.playPuzzleJingle && left.interactionType == 8 && left.damageOrCoinValue == 1 && left.spawnCoins == 1)
        precondition(right.playPuzzleJingle)
        var fingerprint = offset
        for output in [idle, left, right] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "wfBreakableWallFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern WF breakable wall smoke passed")
    }
}
