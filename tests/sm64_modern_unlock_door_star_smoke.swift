import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64UnlockDoorStarOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.state)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.moveYaw)), UInt64(bitPattern: Int64(output.yawVelocity)), UInt64(output.scale.bitPattern), output.hidden ? 1 : 0, output.spawnParticles ? 1 : 0, output.shouldDelete ? 1 : 0, output.playMenuSound ? 1 : 0] }
@main struct SM64UnlockDoorStarSmoke {
    static func main() {
        let rise = SM64UnlockDoorStarBehavior.update(.init(state: 0, timer: 0, moveYaw: 0x7800, yawVelocity: 0x1000, positionY: 0, scale: 0.5))
        let wait = SM64UnlockDoorStarBehavior.update(.init(state: 1, timer: 29, moveYaw: 0, yawVelocity: 0x2000, positionY: 0, scale: 1))
        let particles = SM64UnlockDoorStarBehavior.update(.init(state: 2, timer: 20, moveYaw: 0, yawVelocity: 0x2400, positionY: 0, scale: 1))
        let done = SM64UnlockDoorStarBehavior.update(.init(state: 3, timer: 50, moveYaw: 0, yawVelocity: 0x2400, positionY: 0, scale: 1))
        precondition(rise.state == 0 && rise.timer == 1 && rise.scale == 0.5)
        precondition(wait.state == 2 && wait.timer == 0 && wait.playMenuSound)
        precondition(particles.state == 3 && particles.timer == 0 && particles.spawnParticles)
        precondition(done.shouldDelete)
        var fingerprint = offset
        for output in [rise, wait, particles, done] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "unlockDoorStarFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern unlock door star smoke passed")
    }
}
