import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
@main struct SM64NormalCapSmoke {
    static func main() {
        let roll = SM64NormalCapBehavior.update(.init(action: 0, timer: 0, faceYaw: 100, facePitch: 20, forwardVelocity: 2, verticalVelocity: 0, capPhase: 0, floorLanded: false, interacted: false, deactivated: false, course: .ssl))
        let settle = SM64NormalCapBehavior.update(.init(action: 0, timer: 8, faceYaw: 0, facePitch: 100, forwardVelocity: 0, verticalVelocity: 5, capPhase: 0, floorLanded: true, interacted: false, deactivated: false, course: .other))
        let gone = SM64NormalCapBehavior.update(.init(action: 0, timer: 0, faceYaw: 0, facePitch: 0, forwardVelocity: 0, verticalVelocity: 0, capPhase: 0, floorLanded: false, interacted: false, deactivated: true, course: .sl))
        precondition(roll.faceYaw == 356 && roll.facePitch == 180 && roll.savePosition && settle.capPhase == 2 && settle.facePitch == 0 && gone.deactivated && gone.saveFlag == 2)
        var fingerprint = offset; for output in [roll, settle, gone] { fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.faceYaw))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.facePitch))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.capPhase))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.saveFlag))); fingerprint = hash(fingerprint, output.deactivated ? 1 : 0) }
        print(String(format: "normalCapFingerprint=0x%016llx", fingerprint)); print("SM64 Modern normal cap smoke passed")
    }
}
