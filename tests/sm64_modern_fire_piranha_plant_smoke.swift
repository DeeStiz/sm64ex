import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64FirePiranhaPlantSmoke {
    static func main() {
        let output = SM64FirePiranhaPlantBehavior.update(.init(neutralScale: 0.5, scale: 0, action: .hide, timer: 101, moveYaw: 0, angleToMario: 0x2000, distanceToMario: 300, active: false, activePlantCount: 0, health: 0, behaviorVariant: 0, deathSpinTimer: 0, deathSpinVelocity: 0, animationFrame: 0, renderingEnabled: true, nearAnimationEnd: false, attacked: false, killedCount: 0))
        precondition(output.action == .grow && output.active && output.activePlantCount == 1 && output.moveYaw == 0x2000)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.action.rawValue)); fingerprint=hash(fingerprint,output.active ? 1:0); fingerprint=hash(fingerprint,UInt64(output.activePlantCount)); fingerprint=hash(fingerprint,UInt64(bitPattern:Int64(output.moveYaw))); print(String(format:"firePiranhaPlantFingerprint=0x%016llx",fingerprint)); print("SM64 Modern fire Piranha Plant smoke passed")
    }
}
