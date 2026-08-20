import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64PyramidTopFragmentOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.faceYaw)), UInt64(bitPattern: Int64(output.facePitch)), UInt64(output.scale.bitPattern), UInt64(output.friction.bitPattern), UInt64(output.buoyancy.bitPattern), UInt64(bitPattern: Int64(output.animationState)), output.deactivated ? 1 : 0] }
@main struct SM64PyramidTopFragmentSmoke {
    static func main() {
        let active = SM64PyramidTopFragmentBehavior.update(.init(timer: 0, faceYaw: 0, facePitch: 0, scale: 0.8))
        let retired = SM64PyramidTopFragmentBehavior.update(.init(timer: 60, faceYaw: 0x7000, facePitch: 0x7000, scale: 3))
        precondition(active.timer == 1 && active.faceYaw == 0x1000 && active.facePitch == 0x1000 && !active.deactivated)
        precondition(retired.timer == 61 && retired.faceYaw == 0x8000 && retired.facePitch == 0x8000 && retired.deactivated)
        var fingerprint = offset; for output in [active, retired] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "pyramidTopFragmentFingerprint=0x%016llx", fingerprint)); print("SM64 Modern pyramid top fragment smoke passed")
    }
}
