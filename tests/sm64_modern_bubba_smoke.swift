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

private func row(_ output: SM64BubbaOutput) -> [UInt64] {
    [
        UInt64(bitPattern: Int64(output.action)),
        UInt64(bitPattern: Int64(output.timer)),
        UInt64(bitPattern: Int64(output.attackTimer)),
        UInt64(bitPattern: Int64(output.animationState)),
        output.spawnWaterSplash ? 1 : 0,
        output.playChompSound ? 1 : 0,
    ]
}

@main
struct SM64BubbaSmoke {
    static func main() {
        let patrol = SM64BubbaBehavior.update(.init(
            action: 0, timer: 31, attackTimer: 0, position: .zero,
            moveYaw: 0, movePitch: 0, forwardVelocity: 4, velocityY: 0,
            targetYaw: 0, targetPitch: 0, pitchToMario: 0, pitchToHome: 0,
            angleToMario: 0, distanceToMario: 1_000, nearAndFacingMario: false,
            pitchAligned: false, inWater: false, wasInWater: false,
            waterLevel: 100, floorHeight: 0, hitWall: false, reflectedYaw: 0
        ))
        let bite = SM64BubbaBehavior.update(.init(
            action: 1, timer: 0, attackTimer: 0, position: .zero,
            moveYaw: 0, movePitch: 0, forwardVelocity: 4, velocityY: 0,
            targetYaw: 0, targetPitch: 0, pitchToMario: 0, pitchToHome: 0,
            angleToMario: 0, distanceToMario: 400, nearAndFacingMario: true,
            pitchAligned: true, inWater: false, wasInWater: false,
            waterLevel: 100, floorHeight: 0, hitWall: false, reflectedYaw: 0
        ))
        let jump = SM64BubbaBehavior.update(.init(
            action: 1, timer: 10, attackTimer: 21, position: .zero,
            moveYaw: 0, movePitch: 0, forwardVelocity: 0, velocityY: 0,
            targetYaw: 0, targetPitch: 0, pitchToMario: 0x1000, pitchToHome: 0,
            angleToMario: 0x2000, distanceToMario: 1_000, nearAndFacingMario: false,
            pitchAligned: false, inWater: false, wasInWater: false,
            waterLevel: 100, floorHeight: 0, hitWall: false, reflectedYaw: 0
        ))
        let waterEntry = SM64BubbaBehavior.update(.init(
            action: 0, timer: 0, attackTimer: 0, position: .zero,
            moveYaw: 0, movePitch: 0, forwardVelocity: 5, velocityY: 0,
            targetYaw: 0, targetPitch: 0, pitchToMario: 0, pitchToHome: 0,
            angleToMario: 0, distanceToMario: 5_000, nearAndFacingMario: false,
            pitchAligned: false, inWater: true, wasInWater: false,
            waterLevel: 100, floorHeight: 0, hitWall: false, reflectedYaw: 0
        ))
        let chomp = SM64BubbaBehavior.update(.init(
            action: 1, timer: 20, attackTimer: 1, position: .zero,
            moveYaw: 0, movePitch: 0, forwardVelocity: 0, velocityY: 0,
            targetYaw: 0, targetPitch: 0, pitchToMario: 0, pitchToHome: 0,
            angleToMario: 0, distanceToMario: 500, nearAndFacingMario: false,
            pitchAligned: false, inWater: false, wasInWater: false,
            waterLevel: 100, floorHeight: 0, hitWall: false, reflectedYaw: 0
        ))

        precondition(patrol.action == 1 && patrol.timer == 0 && patrol.forwardVelocity == 4.5)
        precondition(bite.attackTimer == 30 && bite.animationState == 1)
        precondition(jump.attackTimer == 20 && jump.forwardVelocity == 40 && jump.movePitch == 0x1000)
        precondition(waterEntry.spawnWaterSplash && waterEntry.inWaterMovementCheck())
        precondition(chomp.action == 0 && chomp.playChompSound)

        var fingerprint = offset
        for output in [patrol, bite, jump, waterEntry, chomp] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "bubbaFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bubba smoke passed")
    }
}

private extension SM64BubbaOutput {
    func inWaterMovementCheck() -> Bool { position.z > 0 && velocityY == 0 }
}
