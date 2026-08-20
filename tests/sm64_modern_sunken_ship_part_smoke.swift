import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
@main struct SM64SunkenShipPartSmoke {
    static func main() {
        let near = SM64SunkenShipPartBehavior.update(.init(distanceToMario: 5_000))
        let far = SM64SunkenShipPartBehavior.update(.init(distanceToMario: 12_000))
        precondition(near.opacity == 70 && far.opacity == 140 && near.disableRendering && far.disableRendering)
        var fingerprint = offset; for output in [near, far] { fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.opacity))); fingerprint = hash(fingerprint, output.disableRendering ? 1 : 0) }
        print(String(format: "sunkenShipPartFingerprint=0x%016llx", fingerprint)); print("SM64 Modern sunken ship part smoke passed")
    }
}
