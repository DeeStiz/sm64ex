import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 { hash ^= (value >> UInt64(byte * 8)) & 0xff; hash &*= fnvPrime }
    return hash
}

@main
struct SM64ObjectBubbleSmoke {
    static func main() {
        let below = SM64ObjectBubbleBehavior.update(.init(position: .init(x: 0, y: 50, z: 0), waterLevel: 100))
        let above = SM64ObjectBubbleBehavior.update(.init(position: .init(x: 0, y: 101, z: 0), waterLevel: 100))
        precondition(!below.shouldDeactivate && !below.spawnSplash)
        precondition(above.shouldDeactivate && above.spawnSplash)
        var fingerprint = fnvOffset
        for output in [below, above] {
            fingerprint = hashU64(fingerprint, output.shouldDeactivate ? 1 : 0)
            fingerprint = hashU64(fingerprint, output.spawnSplash ? 1 : 0)
        }
        print(String(format: "objectBubbleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern object bubble smoke passed")
    }
}
