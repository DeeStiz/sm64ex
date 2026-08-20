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
struct SM64JrbFloatingBoxSmoke {
    static func main() {
        let zero = SM64JrbFloatingBoxBehavior.update(.init(timer: 0, homeY: 100))
        let peak = SM64JrbFloatingBoxBehavior.update(.init(timer: 16, homeY: 100))
        precondition(zero.timer == 1 && zero.positionY == 100)
        precondition(peak.timer == 17 && peak.positionY == 110)
        var fingerprint = offset
        for output in [zero, peak] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, UInt64(output.positionY.bitPattern))
        }
        print(String(format: "jrbFloatingBoxFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern JRB floating box smoke passed")
    }
}
