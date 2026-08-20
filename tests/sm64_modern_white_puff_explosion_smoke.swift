import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64WhitePuffExplosionSmoke {
    static func main() {
        let output = SM64WhitePuffExplosionBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), velocity: .init(x: 1, y: 2, z: 3), gravity: -1, dragStrength: 0, timer: 0, opacity: 0, initialScale: 254, behaviorParam: 2))
        precondition(output.position == .init(x: 11, y: 22, z: -1) && output.velocity.y == 1 && output.opacity == 233 && output.scale == 233 && !output.shouldDelete)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.velocity.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.opacity)))
        fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern))
        fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        print(String(format: "whitePuffExplosionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern white puff explosion smoke passed")
    }
}
