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

private func row(_ output: SM64DonutPlatformOutput) -> [UInt64] {
    [
        UInt64(output.role.rawValue),
        UInt64(bitPattern: Int64(output.timer)),
        UInt64(output.spawnedMask),
        UInt64(output.clearMask),
        output.shouldDelete ? 1 : 0,
        output.exploded ? 1 : 0,
    ]
}

@main
struct SM64DonutPlatformSmoke {
    static func main() {
        let spawn = SM64DonutPlatformBehavior.update(.init(
            role: .spawner, timer: 0, position: .zero, homePosition: .zero,
            gravity: 0, distanceToMario: 1_500, marioOnPlatform: false,
            onGround: false, spawnMask: 0b101, spawnedMask: 0, platformIndex: -1
        ))
        let home = SM64DonutPlatformBehavior.update(.init(
            role: .platform, timer: 0, position: .init(x: 1, y: 2, z: 3),
            homePosition: .init(x: 10, y: 20, z: 30), gravity: 0,
            distanceToMario: 1_000, marioOnPlatform: false, onGround: false,
            spawnMask: 0, spawnedMask: 0, platformIndex: 0
        ))
        let shake = SM64DonutPlatformBehavior.update(.init(
            role: .platform, timer: 16, position: .zero, homePosition: .zero,
            gravity: 0, distanceToMario: 500, marioOnPlatform: true, onGround: false,
            spawnMask: 0, spawnedMask: 0, platformIndex: 0
        ))
        let far = SM64DonutPlatformBehavior.update(.init(
            role: .platform, timer: 1, position: .zero, homePosition: .zero,
            gravity: -0.1, distanceToMario: 3_000, marioOnPlatform: false, onGround: false,
            spawnMask: 0, spawnedMask: 0, platformIndex: 2
        ))
        let explode = SM64DonutPlatformBehavior.update(.init(
            role: .platform, timer: 1, position: .zero, homePosition: .zero,
            gravity: -0.1, distanceToMario: 1_000, marioOnPlatform: false, onGround: true,
            spawnMask: 0, spawnedMask: 0, platformIndex: 2
        ))
        precondition(spawn.spawnedMask == 0b101 && spawn.timer == 1)
        precondition(home.position == .init(x: 10, y: 20, z: 30) && home.timer == 0)
        precondition(shake.gravity == -0.1 && shake.timer == 17)
        precondition(far.shouldDelete && far.clearMask == 4)
        precondition(explode.exploded && !explode.shouldDelete && explode.clearMask == 4)
        var fingerprint = offset
        for output in [spawn, home, shake, far, explode] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "donutPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Donut Platform smoke passed")
    }
}
