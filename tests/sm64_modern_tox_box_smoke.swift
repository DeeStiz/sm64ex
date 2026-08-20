import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64ToxBoxOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.action)), UInt64(output.positionY.bitPattern), UInt64(output.forwardVelocity.bitPattern), UInt64(bitPattern: Int64(output.facePitch)), UInt64(bitPattern: Int64(output.faceRoll)), output.playMoveSound ? 1 : 0, output.shakeScreen ? 1 : 0, output.loadCollisionModel ? 1 : 0] }
@main struct SM64ToxBoxSmoke {
    static func main() {
        let idle = SM64ToxBoxBehavior.update(.init(action: 0, timer: 0, positionY: 0, homeY: 100, facePitch: 0, faceRoll: 0, initialDirectionAction: 6, nextDirectionAction: 4, behaviorVariant: 0))
        let wait = SM64ToxBoxBehavior.update(.init(action: 1, timer: 20, positionY: 0, homeY: 100, facePitch: 0, faceRoll: 0, initialDirectionAction: 4, nextDirectionAction: 5, behaviorVariant: 0))
        let move = SM64ToxBoxBehavior.update(.init(action: 4, timer: 7, positionY: 0, homeY: 100, facePitch: 0, faceRoll: 0, initialDirectionAction: 4, nextDirectionAction: 6, behaviorVariant: 0))
        let side = SM64ToxBoxBehavior.update(.init(action: 6, timer: 7, positionY: 0, homeY: 100, facePitch: 0, faceRoll: 0, initialDirectionAction: 4, nextDirectionAction: 7, behaviorVariant: 0))
        precondition(idle.action == 6 && wait.action == 5 && wait.positionY == 103 && move.action == 6 && move.facePitch == 0x800 && move.playMoveSound && side.action == 7 && side.faceRoll == 0x800)
        var fingerprint = offset; for output in [idle, wait, move, side] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "toxBoxFingerprint=0x%016llx", fingerprint)); print("SM64 Modern Tox Box smoke passed")
    }
}
