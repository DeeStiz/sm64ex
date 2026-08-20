import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64SmallPiranhaFlameSmoke {
    static func main() {
        let output = SM64SmallPiranhaFlameBehavior.update(.init(mode: .ephemeral, position: .init(x: 10, y: 20, z: -4), moveYaw: 0, movePitch: 0, currentSpeed: 0, targetSpeed: 0, targetYaw: 0, timer: 0, scaleZ: 2, animationState: 0, graphYOffset: 0, distanceTravelled: 0, flyGuySpawnTimer: 8, flyGuySpawnInterval: 8, randomScaleJitter: 0, initialAnimationState: 3, moveFlags: 0))
        precondition(output.position == .init(x: 10, y: 20, z: -4) && output.scaleX == 1.8 && output.scaleY == 2 && output.animationState == 3 && output.shouldDelete == false)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.scaleX.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.scaleY.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.animationState)); fingerprint=hash(fingerprint,output.shouldDelete ? 1:0); print(String(format:"smallPiranhaFlameFingerprint=0x%016llx",fingerprint)); print("SM64 Modern small Piranha flame smoke passed")
    }
}
