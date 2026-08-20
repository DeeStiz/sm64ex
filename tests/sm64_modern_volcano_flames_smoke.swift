import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64VolcanoFlamesSmoke {
    static func main() {
        let output = SM64VolcanoFlamesBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, forwardVelocity: 2, velocityY: 0, gravity: -4, timer: 0, animationState: 0, landedOrWaterSurface: false))
        precondition(output.position == .init(x: 10, y: 16, z: -2) && output.velocityY == -4 && output.animationState == 1 && !output.shouldDelete)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.position.x.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.y.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.z.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.velocityY.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.animationState)); fingerprint=hash(fingerprint,output.shouldDelete ? 1:0)
        print(String(format:"volcanoFlamesFingerprint=0x%016llx",fingerprint)); print("SM64 Modern volcano flames smoke passed")
    }
}
