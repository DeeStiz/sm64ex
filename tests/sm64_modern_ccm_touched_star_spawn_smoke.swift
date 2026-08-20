import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64CcmTouchedStarSpawnSmoke {
    static func main() {
        let idle = SM64CcmTouchedStarSpawnBehavior.update(.init(enteredSlide: false, position: .init(x: 1, y: 2, z: 3)))
        let triggered = SM64CcmTouchedStarSpawnBehavior.update(.init(enteredSlide: true, position: .init(x: 1, y: 2, z: 3)))
        precondition(idle.position == .init(x: 1, y: 2, z: 3) && !idle.spawnStar && !idle.shouldDelete)
        precondition(triggered.position == .init(x: 2780, y: 102, z: 4666) && triggered.spawnStar && triggered.shouldDelete)
        precondition(triggered.starPosition == .init(x: 2500, y: -4350, z: 5750))
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(idle.spawnStar ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(idle.shouldDelete ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(triggered.position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(triggered.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(triggered.position.z.bitPattern)); fingerprint = hash(fingerprint, UInt64(triggered.spawnStar ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(triggered.shouldDelete ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(triggered.starPosition.y.bitPattern))
        print(String(format: "ccmTouchedStarSpawnFingerprint=0x%016llx", fingerprint)); print("SM64 Modern CCM touched-star smoke passed")
    }
}
