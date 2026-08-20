import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

@main
struct SM64JetStreamSmoke {
    static func main() {
        let near = SM64JetStreamBehavior.update(.init(distanceToMario: 4_000, position: .zero, timer: 0))
        let far = SM64JetStreamBehavior.update(.init(distanceToMario: 6_000, position: .zero, timer: 1))
        precondition(near.particleCount == 60 && near.visible && near.timer == 1)
        precondition(far.particleCount == 0 && !far.visible && far.timer == 2)
        var fingerprint = offset
        for output in [near, far] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.particleCount)))
            fingerprint = hash(fingerprint, output.visible ? 1 : 0)
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
        }
        print(String(format: "jetStreamFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Jet Stream smoke passed")
    }
}
