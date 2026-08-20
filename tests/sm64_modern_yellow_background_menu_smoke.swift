import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64YellowBackgroundMenuOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.faceAngleYaw)), UInt64(output.scale.bitPattern)] }
@main struct SM64YellowBackgroundMenuSmoke { static func main() { let first = SM64YellowBackgroundMenuBehavior.update(.init(timer: 0)); let later = SM64YellowBackgroundMenuBehavior.update(.init(timer: 1)); precondition(first.timer == 1 && first.faceAngleYaw == -32768 && first.scale == 9); precondition(later.timer == 2 && later.faceAngleYaw == -32768 && later.scale == 9); var fingerprint = offset; for output in [first, later] { for value in row(output) { fingerprint = hash(fingerprint, value) } }; print(String(format: "yellowBackgroundMenuFingerprint=0x%016llx", fingerprint)); print("SM64 Modern yellow background menu smoke passed") } }
