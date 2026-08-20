import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }

@main
struct SM64BlueFishSmoke {
    static func main() {
        let dive = SM64BlueFishBehavior.update(.init(
            action: .dive, timer: 0, position: .zero, moveYaw: 0, facePitch: 0,
            angleVelocityPitch: 0, forwardVelocity: 0, randomAngle: 0x100,
            randomVelocity: 2, randomTime: 0, parentDuplicate: false
        ))
        let turn = SM64BlueFishBehavior.update(.init(
            action: .turn, timer: 15, position: .zero, moveYaw: 0, facePitch: 0,
            angleVelocityPitch: 0, forwardVelocity: 5, randomAngle: 0x100,
            randomVelocity: 2, randomTime: 0, parentDuplicate: false
        ))
        let duplicate = SM64BlueFishBehavior.update(.init(
            action: .turnBack, timer: 0, position: .zero, moveYaw: 0, facePitch: 0,
            angleVelocityPitch: 0, forwardVelocity: 5, randomAngle: 0x100,
            randomVelocity: 2, randomTime: 0, parentDuplicate: true
        ))
        precondition(dive.action == .dive && dive.forwardVelocity == 5 && dive.position.z == 5)
        precondition(turn.action == .ascend && turn.moveYaw == 0x100 && turn.timer == 0)
        precondition(duplicate.shouldDelete)
        let groupSpawn = SM64BlueFishBehavior.updateTankFishGroup(action: 0, room: 15)
        let groupLeave = SM64BlueFishBehavior.updateTankFishGroup(action: 1, room: 14)
        let groupReset = SM64BlueFishBehavior.updateTankFishGroup(action: 2, room: 14)
        precondition(groupSpawn.spawnFish && groupSpawn.childCount == 15 && groupSpawn.action == 1)
        precondition(!groupLeave.spawnFish && groupLeave.action == 2 && groupReset.action == 0)
        var fingerprint = offset
        for output in [dive, turn, duplicate] {
            fingerprint = hash(fingerprint, UInt64(output.action.rawValue))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.moveYaw)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.facePitch)))
            fingerprint = hash(fingerprint, output.forwardVelocity)
            fingerprint = hash(fingerprint, output.velocity.y)
            fingerprint = hash(fingerprint, output.animationAcceleration)
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
        }
        for output in [groupSpawn, groupLeave, groupReset] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.action)))
            fingerprint = hash(fingerprint, UInt64(output.spawnFish ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.childCount))
        }
        print(String(format: "blueFishFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern blue-fish smoke passed")
    }
}
