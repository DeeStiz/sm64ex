import Foundation
private let off: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
@main struct SM64TowerDoorSmoke {
    static func main() {
        let idle = SM64TowerDoorBehavior.update(.init(timer: 0, faceYaw: 0x5000, marioAttacking: false))
        let steady = SM64TowerDoorBehavior.update(.init(timer: 1, faceYaw: 0x5000, marioAttacking: false))
        let attack = SM64TowerDoorBehavior.update(.init(timer: 4, faceYaw: 0x5000, marioAttacking: true))
        precondition(idle.timer == 1 && idle.faceYaw == 0x1000 && !idle.shouldDelete, "tower-door first-frame yaw")
        precondition(steady.timer == 2 && steady.faceYaw == 0x5000 && !steady.shouldDelete, "tower-door steady route")
        precondition(attack.timer == 5 && attack.faceYaw == 0x5000 && attack.spawnMist && attack.spawnTriangleBreak && attack.playWallExplosionSound && attack.shouldDelete, "tower-door attack explosion")
        var f = off
        for output in [idle, steady, attack] { f = hash(f, output.timer); f = hash(f, output.faceYaw); f = hash(f, UInt64(output.spawnMist ? 1 : 0)); f = hash(f, UInt64(output.spawnTriangleBreak ? 1 : 0)); f = hash(f, output.spawnedCoins); f = hash(f, UInt64(output.playWallExplosionSound ? 1 : 0)); f = hash(f, UInt64(output.shouldDelete ? 1 : 0)) }
        print(String(format: "towerDoorFingerprint=0x%016llx", f)); print("SM64 Modern tower-door smoke passed")
    }
}
