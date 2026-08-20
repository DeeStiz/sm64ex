import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64ThiIslandTopOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.environmentDelta)), output.environmentSet.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.max, output.waterDrained ? 1 : 0, output.hidden ? 1 : 0, output.loadCollisionModel ? 1 : 0, output.spawnParticles ? 1 : 0, output.spawnTriangleParticles ? 1 : 0, output.playActivateSound ? 1 : 0, output.playDrainSound ? 1 : 0, output.playPuzzleJingle ? 1 : 0] }
@main struct SM64ThiIslandTopSmoke {
    static func main() {
        let hugeDry = SM64ThiIslandTopBehavior.update(.init(role: .huge, action: 0, timer: 0, waterDrained: false, distanceToMario: 2_000, marioGroundPound: false))
        let hugeWet = SM64ThiIslandTopBehavior.update(.init(role: .huge, action: 0, timer: 0, waterDrained: true, distanceToMario: 2_000, marioGroundPound: false))
        let tinyHit = SM64ThiIslandTopBehavior.update(.init(role: .tiny, action: 0, timer: 0, waterDrained: false, distanceToMario: 400, marioGroundPound: true))
        let tinyDone = SM64ThiIslandTopBehavior.update(.init(role: .tiny, action: 1, timer: 50, waterDrained: false, distanceToMario: 2_000, marioGroundPound: false))
        precondition(hugeDry.loadCollisionModel && hugeWet.hidden && hugeWet.environmentSet == 3_000 && tinyHit.action == 1 && tinyHit.spawnParticles && tinyDone.waterDrained && tinyDone.action == 2)
        var fingerprint = offset; for output in [hugeDry, hugeWet, tinyHit, tinyDone] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "thiIslandTopFingerprint=0x%016llx", fingerprint)); print("SM64 Modern THI island top smoke passed")
    }
}
