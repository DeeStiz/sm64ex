import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64WhitePuffSmokeSmoke {
    static func main() {
        let output = SM64WhitePuffSmokeBehavior.update(.init(position: .init(x: 10, y: 100, z: -4), timer: 0, animationState: -1, initialScale: 3))
        precondition(output.position == .init(x: 10, y: 0, z: -4) && output.scale == 3 && output.animationState == 0 && !output.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.animationState)))
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "whitePuffSmokeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern white puff smoke smoke passed")
    }
}
