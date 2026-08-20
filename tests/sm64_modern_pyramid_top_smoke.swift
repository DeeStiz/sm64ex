import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64PyramidTopOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.faceYaw)), UInt64(bitPattern: Int64(output.angleVelocityYaw)), UInt64(output.velocityY.bitPattern), UInt64(bitPattern: Int64(output.spawnFragments)), output.playPuzzleJingle ? 1 : 0, output.playSpinSound ? 1 : 0, output.spawnExplosionSound ? 1 : 0, output.deactivated ? 1 : 0] }
@main struct SM64PyramidTopSmoke {
    static func main() {
        let solved = SM64PyramidTopBehavior.update(.init(action: 0, timer: 0, pillarsTouched: 4, faceYaw: 0, angleVelocityYaw: 0, velocityY: 0, position: .zero, homePosition: .zero))
        let spinStart = SM64PyramidTopBehavior.update(.init(action: 1, timer: 0, pillarsTouched: 4, faceYaw: 0, angleVelocityYaw: 0, velocityY: 0, position: .zero, homePosition: .zero))
        let explode = SM64PyramidTopBehavior.update(.init(action: 2, timer: 0, pillarsTouched: 4, faceYaw: 0, angleVelocityYaw: 0, velocityY: 0, position: .zero, homePosition: .zero))
        precondition(solved.action == 1 && solved.playPuzzleJingle && spinStart.playSpinSound && spinStart.spawnFragments == 1 && explode.spawnFragments == 30 && explode.deactivated)
        var fingerprint = offset; for output in [solved, spinStart, explode] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "pyramidTopFingerprint=0x%016llx", fingerprint)); print("SM64 Modern pyramid top smoke passed")
    }
}
