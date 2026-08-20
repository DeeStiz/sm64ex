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

@main
struct SM64SnowmanHeadSmoke {
    static func main() {
        let dialog = SM64SnowmanHeadBehavior.update(.init(
            action: 0, timer: 4, positionY: -994, moveFlags: 0,
            dialogTriggered: true, dialogCompleted: false
        ))
        let falling = SM64SnowmanHeadBehavior.update(.init(
            action: 2, timer: 8, positionY: -1000, moveFlags: 0x08,
            dialogTriggered: false, dialogCompleted: false
        ))
        let explode = SM64SnowmanHeadBehavior.update(.init(
            action: 3, timer: 12, positionY: -1000, moveFlags: 0,
            dialogTriggered: false, dialogCompleted: false
        ))
        let reward = SM64SnowmanHeadBehavior.update(.init(
            action: 4, timer: 20, positionY: -994, moveFlags: 0,
            dialogTriggered: false, dialogCompleted: true
        ))
        precondition(dialog.action == 1 && dialog.timer == 0)
        precondition(falling.action == 3 && falling.timer == 0)
        precondition(explode.action == 4 && explode.positionY == -994 && explode.explosionJingle)
        precondition(reward.action == 1 && reward.mistAndStar && reward.pushMario)

        var fingerprint = offset
        for output in [dialog, falling, explode, reward] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.action)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, output.explosionJingle ? 1 : 0)
            fingerprint = hash(fingerprint, output.mistAndStar ? 1 : 0)
        }
        print(String(format: "snowmanHeadFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern snowman head smoke passed")
    }
}
