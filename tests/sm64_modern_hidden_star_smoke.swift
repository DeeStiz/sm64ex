import Foundation
private let off: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= prime }; return result }
@main struct HiddenStarSmoke {
    static func main() {
        let idle = SM64HiddenStarBehavior.updateParent(.init(action: .waiting, timer: 0, triggerCounter: 4))
        let ready = SM64HiddenStarBehavior.updateParent(.init(action: .waiting, timer: 0, triggerCounter: 5))
        let reveal = SM64HiddenStarBehavior.updateParent(.init(action: .reveal, timer: 3, triggerCounter: 5))
        let trigger = SM64HiddenStarBehavior.updateTrigger(.init(triggerCounter: 4, collidedWithMario: true))
        precondition(idle.action == .waiting && ready.action == .reveal && reveal.spawnStar && reveal.spawnMist && reveal.shouldDelete && trigger.triggerCounter == 5 && trigger.spawnNumber == nil && trigger.playSound && trigger.shouldDelete)
        var fingerprint = off
        fingerprint = hash(fingerprint, UInt64(idle.action.rawValue)); fingerprint = hash(fingerprint, UInt64(ready.action.rawValue)); fingerprint = hash(fingerprint, UInt64(reveal.spawnStar ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(reveal.spawnMist ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(trigger.triggerCounter)); fingerprint = hash(fingerprint, UInt64(trigger.shouldDelete ? 1 : 0))
        print(String(format: "hiddenStarFingerprint=0x%016llx", fingerprint)); print("SM64 Modern hidden-star smoke passed")
    }
}
