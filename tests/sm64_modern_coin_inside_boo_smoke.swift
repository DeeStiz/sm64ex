import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }

@main
struct SM64CoinInsideBooSmoke {
    static func main() {
        let inside = SM64CoinInsideBooBehavior.update(.init(
            action: .inside,
            timer: 0,
            position: .zero,
            velocity: .zero,
            parentPosition: .init(x: 10, y: 20, z: 30),
            parentDying: false,
            marioMoveYaw: 0,
            levelIsBBH: true,
            landed: false,
            interacted: false
        ))
        let release = SM64CoinInsideBooBehavior.update(.init(
            action: .inside,
            timer: 0,
            position: .zero,
            velocity: .zero,
            parentPosition: .init(x: 10, y: 20, z: 30),
            parentDying: true,
            marioMoveYaw: 0x4000,
            levelIsBBH: true,
            landed: false,
            interacted: false
        ))
        let collected = SM64CoinInsideBooBehavior.update(.init(
            action: .released,
            timer: 91,
            position: .init(x: 1, y: 2, z: 3),
            velocity: .init(x: 3, y: 35, z: 0),
            parentPosition: .zero,
            parentDying: false,
            marioMoveYaw: 0,
            levelIsBBH: false,
            landed: true,
            interacted: true
        ))
        precondition(inside.position == .init(x: 10, y: 20, z: 30) && inside.blueModel && inside.scale == 0.7 && !inside.tangible)
        precondition(release.action == .released && release.velocity.y == 35 && release.velocity.x == 3)
        precondition(collected.tangible && collected.spawnGoldenSparkles && collected.shouldDelete)
        var fingerprint = offset
        for output in [inside, release, collected] {
            fingerprint = hash(fingerprint, UInt64(output.action.rawValue))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, output.position.x)
            fingerprint = hash(fingerprint, output.position.y)
            fingerprint = hash(fingerprint, output.position.z)
            fingerprint = hash(fingerprint, output.velocity.x)
            fingerprint = hash(fingerprint, output.velocity.y)
            fingerprint = hash(fingerprint, output.velocity.z)
            fingerprint = hash(fingerprint, UInt64(output.tangible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.blueModel ? 1 : 0))
            fingerprint = hash(fingerprint, output.scale)
            fingerprint = hash(fingerprint, UInt64(output.spawnGoldenSparkles ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
        }
        print(String(format: "coinInsideBooFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern coin-inside-Boo smoke passed")
    }
}
