import Foundation
private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }
@main struct SM64UnusedFakeStarSmoke { static func main() { let output = SM64UnusedFakeStarBehavior.update(.init(position: .zero, facePitch: 0x2000, faceYaw: 0x4000)); precondition(output.facePitch == 0x2100 && output.faceYaw == 0x4100); var fingerprint = fnvOffset; fingerprint = hash(fingerprint, UInt64(output.facePitch)); fingerprint = hash(fingerprint, UInt64(output.faceYaw)); print(String(format: "unusedFakeStarFingerprint=0x%016llx", fingerprint)); print("SM64 Modern unused fake star smoke passed") } }
