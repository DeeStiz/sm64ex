import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64FlameBouncingSmoke {
    static func main() {
        let output = SM64FlameBouncingBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, forwardVelocity: 20, velocityY: 0, gravity: -1, timer: 0, animationState: 0, initialScale: 2, distanceToBowser: 1000, bowserExists: false, bowserHeldState: 0, floorHazard: false))
        precondition(output.position == .init(x: 10, y: 49, z: 11) && output.forwardVelocity == 15 && output.velocityY == 29 && output.scale == 2 && output.animationState == 1 && !output.shouldDelete)
        var fingerprint = fnvOffset; fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.forwardVelocity.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.velocityY.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.animationState)); fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        print(String(format: "flameBouncingFingerprint=0x%016llx", fingerprint)); print("SM64 Modern bouncing flame smoke passed")
    }
}
