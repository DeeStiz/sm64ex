import Foundation
private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }
@main struct SM64NoOpSmoke { static func main() { let output = SM64NoOpBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), faceAngles: .init(pitch: 1, yaw: 2, roll: 3))); precondition(output.position == .init(x: 10, y: 20, z: -4) && output.faceAngles == .init(pitch: 1, yaw: 2, roll: 3) && output.scriptBreaks); var fingerprint = fnvOffset; fingerprint = hash(fingerprint, output.scriptBreaks ? 1 : 0); fingerprint = hash(fingerprint, UInt64(output.faceAngles.yaw)); print(String(format: "noOpFingerprint=0x%016llx", fingerprint)); print("SM64 Modern no-op behavior smoke passed") } }
