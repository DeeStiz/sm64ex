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

private func row(_ output: SM64BowlingBallOutput) -> [UInt64] {
    [
        UInt64(output.role.rawValue),
        UInt64(bitPattern: Int64(output.action)),
        UInt64(bitPattern: Int64(output.timer)),
        output.spawnBall ? 1 : 0,
        output.tangible ? 1 : 0,
        output.visible ? 1 : 0,
        output.resetToHome ? 1 : 0,
        output.shouldDelete ? 1 : 0,
    ]
}

@main
struct SM64BowlingBallSmoke {
    static func main() {
        let initialized = SM64BowlingBallBehavior.update(.init(
            role: .rolling, action: 0, timer: 0, position: .zero,
            homePosition: .zero, moveYaw: 0, targetYaw: 0,
            forwardVelocity: 0, velocityY: 0, behaviorParam: 4,
            distanceToMario: 4_000, marioY: 0, periodMinus1: 0,
            maxSpawnDistance: 0, spawnAdmission: false, pathEnded: false,
            grounded: false, landed: false, floorFlat: false
        ))
        let rolling = SM64BowlingBallBehavior.update(.init(
            role: .rolling, action: 1, timer: 2, position: .zero,
            homePosition: .zero, moveYaw: 0, targetYaw: 0,
            forwardVelocity: 20, velocityY: 0, behaviorParam: 0,
            distanceToMario: 4_000, marioY: 0, periodMinus1: 0,
            maxSpawnDistance: 0, spawnAdmission: false, pathEnded: false,
            grounded: false, landed: false, floorFlat: false
        ))
        let spawned = SM64BowlingBallBehavior.update(.init(
            role: .spawner, action: 0, timer: 0, position: .init(x: 0, y: 100, z: 0),
            homePosition: .zero, moveYaw: 0, targetYaw: 0,
            forwardVelocity: 0, velocityY: 0, behaviorParam: 0,
            distanceToMario: 5_000, marioY: 0, periodMinus1: 127,
            maxSpawnDistance: 7_000, spawnAdmission: true, pathEnded: false,
            grounded: false, landed: false, floorFlat: false
        ))
        let freeIdle = SM64BowlingBallBehavior.update(.init(
            role: .free, action: 0, timer: 8, position: .zero,
            homePosition: .init(x: 10, y: 20, z: 30), moveYaw: 0, targetYaw: 0,
            forwardVelocity: 0, velocityY: 0, behaviorParam: 0,
            distanceToMario: 2_000, marioY: 0, periodMinus1: 0,
            maxSpawnDistance: 0, spawnAdmission: false, pathEnded: false,
            grounded: false, landed: false, floorFlat: false
        ))
        let freeReset = SM64BowlingBallBehavior.update(.init(
            role: .free, action: 1, timer: 4, position: .init(x: 4, y: 5, z: 6),
            homePosition: .init(x: 10, y: 20, z: 30), moveYaw: 0, targetYaw: 0,
            forwardVelocity: 15, velocityY: 0, behaviorParam: 0,
            distanceToMario: 7_000, marioY: 0, periodMinus1: 0,
            maxSpawnDistance: 0, spawnAdmission: false, pathEnded: false,
            grounded: true, landed: false, floorFlat: false
        ))

        precondition(initialized.action == 1 && initialized.timer == 0 && initialized.forwardVelocity == 10 && initialized.scale == 0.3)
        precondition(rolling.position.z == 20 && rolling.cameraShake && rolling.action == 1)
        precondition(spawned.spawnBall && spawned.timer == 1)
        precondition(freeIdle.action == 1 && freeIdle.visible && freeIdle.tangible)
        precondition(freeReset.action == 2 && freeReset.resetToHome && !freeReset.visible && !freeReset.tangible)

        var fingerprint = offset
        for output in [initialized, rolling, spawned, freeIdle, freeReset] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "bowlingBallFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern bowling-ball smoke passed")
    }
}
