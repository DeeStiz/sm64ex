import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

private func row(_ output: SM64EndBirdsOutput) -> [UInt64] {
    [UInt64(output.role.rawValue), UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(output.scale.bitPattern), UInt64(output.forwardVelocity.bitPattern), output.shouldDelete ? 1 : 0, output.playFlyAwaySound ? 1 : 0]
}

@main
struct SM64EndBirdsSmoke {
    static func main() {
        let birds1Init = SM64EndBirdsBehavior.update(.init(role: .birds1, action: 0, timer: 0, position: .zero, targetPosition: .init(x: -554, y: 3044, z: -1314), cutsceneTimer: 1, endBirdVelocity: 30))
        let birds1Delete = SM64EndBirdsBehavior.update(.init(role: .birds1, action: 1, timer: 0, position: .zero, targetPosition: .init(x: -554, y: 3044, z: -1314), cutsceneTimer: 0, endBirdVelocity: 30))
        let birds2Init = SM64EndBirdsBehavior.update(.init(role: .birds2, action: 0, timer: 0, position: .zero, targetPosition: .init(x: 0, y: 0, z: 14_000), cutsceneTimer: 1, endBirdVelocity: 0))
        let birds2Move = SM64EndBirdsBehavior.update(.init(role: .birds2, action: 1, timer: 2, position: .zero, targetPosition: .init(x: 0, y: 0, z: 14_000), cutsceneTimer: 1, endBirdVelocity: 30))
        precondition(birds1Init.action == 1 && birds1Init.timer == 0 && birds1Init.scale == 0.7)
        precondition(birds1Delete.shouldDelete && birds1Delete.playFlyAwaySound)
        precondition(birds2Init.action == 1 && birds2Init.forwardVelocity == 30)
        precondition(birds2Move.position.z > 0 && !birds2Move.shouldDelete)
        var fingerprint = offset
        for output in [birds1Init, birds1Delete, birds2Init, birds2Move] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "endBirdsFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern end birds smoke passed")
    }
}
