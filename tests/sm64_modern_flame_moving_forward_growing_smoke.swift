import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64FlameMovingForwardGrowingSmoke {
    static func main() {
        let output = SM64FlameMovingForwardGrowingBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, movePitch: 0, forwardVelocity: 30, scaleFactor: 3, timer: 0, animationState: 0, initialOffset: .init(x: 1, y: 0, z: 2), floorHeight: 0, initialAnimationState: 3, floorBelowPosition: false))
        precondition(output.position == .init(x: 11, y: 20, z: 28) && output.movePitch == 0 && output.scaleFactor == 3.5 && output.animationState == 4 && !output.shouldDelete)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.position.x.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.y.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.z.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.scaleFactor.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.animationState)); fingerprint=hash(fingerprint,output.shouldDelete ? 1:0); print(String(format:"flameMovingForwardGrowingFingerprint=0x%016llx",fingerprint)); print("SM64 Modern moving/growing flame smoke passed")
    }
}
