import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64PyramidPillarTouchDetectorOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.parentTouchedCount)), output.tangible ? 1 : 0, output.deactivated ? 1 : 0] }
@main struct SM64PyramidPillarTouchDetectorSmoke {
    static func main() {
        let idle = SM64PyramidPillarTouchDetectorBehavior.update(.init(parentTouchedCount: 3, collidedWithMario: false))
        let hit = SM64PyramidPillarTouchDetectorBehavior.update(.init(parentTouchedCount: 3, collidedWithMario: true))
        precondition(idle.parentTouchedCount == 3 && !idle.deactivated && hit.parentTouchedCount == 4 && hit.deactivated)
        var fingerprint = offset; for output in [idle, hit] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "pyramidPillarTouchDetectorFingerprint=0x%016llx", fingerprint)); print("SM64 Modern pyramid pillar touch detector smoke passed")
    }
}
