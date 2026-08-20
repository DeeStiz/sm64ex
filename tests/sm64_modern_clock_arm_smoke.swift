import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
@main struct SM64ClockArmSmoke {
    static func main() {
        let wait = SM64ClockArmBehavior.update(.init(kind: .hour, action: 0, timer: 3, roll: 100, angleVelocity: -32, surface: .default))
        let rotate = SM64ClockArmBehavior.update(.init(kind: .hour, action: 1, timer: 4, roll: 100, angleVelocity: -32, surface: .other))
        let minute = SM64ClockArmBehavior.update(.init(kind: .minute, action: 1, timer: 4, roll: 0xA000, angleVelocity: -0x180, surface: .painting))
        precondition(wait.action == 0 && wait.rotating, "clock arm safety wait")
        precondition(rotate.action == 1 && rotate.roll == 68, "clock arm rotation")
        precondition(minute.action == 2 && minute.speedSetting == .slow && !minute.rotating, "clock minute speed selection")
        var fingerprint = offset
        for output in [wait, rotate, minute] { fingerprint = hash(fingerprint, UInt64(output.action)); fingerprint = hash(fingerprint, UInt64(output.timer)); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.roll))); fingerprint = hash(fingerprint, UInt64(output.speedSetting?.rawValue ?? 255)); fingerprint = hash(fingerprint, UInt64(output.rotating ? 1 : 0)) }
        print(String(format: "clockArmFingerprint=0x%016llx", fingerprint)); print("SM64 Modern clock-arm smoke passed")
    }
}
