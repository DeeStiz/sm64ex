import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
@main struct SM64ExclamationBoxSmoke {
    static func main() {
        let initClosed = SM64ExclamationBoxBehavior.update(.init(action: 0, timer: 0, behaviorByte: 0, saveCollected: false, overrideActive: false, attacked: false, phase: 0))
        let mark = SM64ExclamationBoxBehavior.update(.init(action: 1, timer: 0, behaviorByte: 0, saveCollected: false, overrideActive: false, attacked: false, phase: 0))
        let hit = SM64ExclamationBoxBehavior.update(.init(action: 2, timer: 0, behaviorByte: 8, saveCollected: true, overrideActive: false, attacked: true, phase: 0))
        let wobble = SM64ExclamationBoxBehavior.update(.init(action: 3, timer: 7, behaviorByte: 8, saveCollected: true, overrideActive: false, attacked: false, phase: 0x4000))
        let star = SM64ExclamationBoxBehavior.update(.init(action: 4, timer: 0, behaviorByte: 8, saveCollected: true, overrideActive: false, attacked: false, phase: 0))
        let returnBox = SM64ExclamationBoxBehavior.update(.init(action: 5, timer: 301, behaviorByte: 0, saveCollected: false, overrideActive: false, attacked: false, phase: 0))
        precondition(initClosed.action == 1 && !initClosed.tangible, "exclamation box closed init")
        precondition(mark.spawnRotatingMark && mark.model == 0x83, "exclamation box mark")
        precondition(hit.action == 3 && hit.velocityY == 30, "exclamation box attack")
        precondition(wobble.action == 4 && wobble.scaleY >= 0, "exclamation box wobble")
        precondition(star.shouldDelete && star.content == .spawnedStar && star.spawnTriangles, "exclamation box star content")
        precondition(returnBox.action == 2 && returnBox.visible && returnBox.tangible, "exclamation box return")
        var fingerprint = offset
        for output in [initClosed, mark, hit, wobble, star, returnBox] {
            fingerprint = hash(fingerprint, output.action); fingerprint = hash(fingerprint, output.timer); fingerprint = hash(fingerprint, output.animationState); fingerprint = hash(fingerprint, UInt64(output.visible ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.tangible ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.model)); fingerprint = hash(fingerprint, output.scaleX); fingerprint = hash(fingerprint, output.scaleY); fingerprint = hash(fingerprint, output.graphYOffset); fingerprint = hash(fingerprint, output.phase); fingerprint = hash(fingerprint, output.velocityY); fingerprint = hash(fingerprint, UInt64(output.spawnRotatingMark ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.content.rawValue)); fingerprint = hash(fingerprint, output.contentParameter); fingerprint = hash(fingerprint, UInt64(output.spawnMist ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.spawnTriangles ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.playBreakSound ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.loadCollisionModel ? 1 : 0))
        }
        print(String(format: "exclamationBoxFingerprint=0x%016llx", fingerprint)); print("SM64 Modern exclamation-box smoke passed")
    }
}
