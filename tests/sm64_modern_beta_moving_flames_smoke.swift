import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64BetaMovingFlamesSmoke {
    static func main() {
        let output = SM64BetaMovingFlamesBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, movingFlameTimer: 0, animationState: 0))
        let spawn = SM64BetaMovingFlamesSpawnBehavior.update(.init(position: .zero, timer: 0, action: 0))
        precondition(output.position == .init(x: 10, y: 20, z: -4) && output.forwardVelocity == 0 && output.movingFlameTimer == 0x800 && output.animationState == 1 && output.scale == 5 && spawn.spawnChild && spawn.action == 1)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.forwardVelocity.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.movingFlameTimer)); fingerprint=hash(fingerprint,UInt64(output.animationState)); fingerprint=hash(fingerprint,UInt64(output.scale.bitPattern)); fingerprint=hash(fingerprint,spawn.spawnChild ? 1:0); fingerprint=hash(fingerprint,UInt64(spawn.action)); print(String(format:"betaMovingFlamesFingerprint=0x%016llx",fingerprint)); print("SM64 Modern Beta moving flames smoke passed")
    }
}
