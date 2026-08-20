import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64WhitePuffSmoke2Smoke {
    static func main() {
        let output = SM64WhitePuffSmoke2Behavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, forwardVelocity: 2, velocityY: 4, gravity: -1, timer: 0, animationState: -1, initialOffsetX: 1, initialOffsetZ: 2))
        precondition(output.position == .init(x: 11, y: 23, z: 0) && output.velocityY == 3 && output.animationState == 0 && !output.shouldDeactivate)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.velocityY.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.animationState)))
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "whitePuffSmoke2Fingerprint=0x%016llx", fingerprint))
        print("SM64 Modern white puff smoke 2 smoke passed")
    }
}
