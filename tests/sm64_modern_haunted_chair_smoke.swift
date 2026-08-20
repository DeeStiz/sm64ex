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

private func row(_ output: SM64HauntedChairOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(output.position.y.bitPattern), UInt64(output.velocityY.bitPattern), UInt64(output.forwardVelocity.bitPattern), UInt64(bitPattern: Int64(output.launchCountdown)), output.shouldDelete ? 1 : 0, output.playLaunchSound ? 1 : 0]
}

@main
struct SM64HauntedChairSmoke {
    static func main() {
        let rise = SM64HauntedChairBehavior.update(.init(action: 0, timer: 31, position: .zero, velocityY: 0, forwardVelocity: 0, hasPianoParent: false, nearPiano: false, distanceToMario: 1_000, launchCountdown: 1, hitGroundOrWall: false))
        let lift = SM64HauntedChairBehavior.update(.init(action: 1, timer: 0, position: .zero, velocityY: 0, forwardVelocity: 0, hasPianoParent: false, nearPiano: false, distanceToMario: 1_000, launchCountdown: 40, hitGroundOrWall: false))
        let launch = SM64HauntedChairBehavior.update(.init(action: 1, timer: 70, position: .zero, velocityY: 0, forwardVelocity: 0, hasPianoParent: false, nearPiano: false, distanceToMario: 1_000, launchCountdown: 1, hitGroundOrWall: false))
        let death = SM64HauntedChairBehavior.update(.init(action: 1, timer: 80, position: .zero, velocityY: 0, forwardVelocity: 0, hasPianoParent: false, nearPiano: false, distanceToMario: 1_000, launchCountdown: 0, hitGroundOrWall: true))
        precondition(rise.action == 1 && rise.timer == 0 && rise.launchCountdown == 40)
        precondition(lift.position.y == 6 && lift.velocityY == 6)
        precondition(launch.forwardVelocity == 50 && launch.playLaunchSound && launch.launchCountdown == 0)
        precondition(death.shouldDelete)
        var fingerprint = offset
        for output in [rise, lift, launch, death] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "hauntedChairFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern haunted chair smoke passed")
    }
}
