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

private func row(_ output: SM64MadPianoOutput) -> [UInt64] {
    [
        UInt64(bitPattern: Int64(output.action)),
        UInt64(bitPattern: Int64(output.timer)),
        UInt64(output.position.x.bitPattern),
        UInt64(output.position.z.bitPattern),
        UInt64(output.forwardVelocity.bitPattern),
        UInt64(bitPattern: Int64(output.moveYaw)),
        UInt64(bitPattern: Int64(output.faceYaw)),
        output.tangible ? 1 : 0,
        UInt64(output.effects.rawValue),
    ]
}

@main
struct SM64MadPianoSmoke {
    static func main() {
        let idleReset = SM64MadPianoBehavior.update(
            .init(timer: 25, distanceToMario: 600)
        )
        let trigger = SM64MadPianoBehavior.update(
            .init(timer: 21, distanceToMario: 499, marioForwardVelocity: 11)
        )
        let attackNear = SM64MadPianoBehavior.update(
            .init(
                action: SM64MadPianoBehavior.attackAction,
                timer: 31,
                moveYaw: 0,
                angleToMario: 1_000,
                distanceToMario: 499,
                marioForwardVelocity: 0
            )
        )
        let attackClamp = SM64MadPianoBehavior.update(
            .init(
                action: SM64MadPianoBehavior.attackAction,
                timer: 40,
                position: .init(x: 500, y: 7, z: 0),
                homePosition: .zero,
                moveYaw: 0,
                angleToMario: 1_000,
                distanceToMario: 900
            )
        )
        let finish = SM64MadPianoBehavior.update(
            .init(
                action: SM64MadPianoBehavior.attackAction,
                timer: 81,
                distanceToMario: 900,
                animationNearEnd: true
            )
        )

        precondition(idleReset.action == SM64MadPianoBehavior.waitAction)
        precondition(idleReset.timer == 0)
        precondition(trigger.action == SM64MadPianoBehavior.attackAction)
        precondition(trigger.tangible)
        precondition(attackNear.timer == 0 && attackNear.forwardVelocity == 5)
        precondition(attackClamp.position.x == 400 && attackClamp.effects.contains(.clampedToHome))
        precondition(finish.action == SM64MadPianoBehavior.waitAction)
        precondition(!finish.tangible && finish.effects.contains(.intangible))

        var fingerprint = offset
        for output in [idleReset, trigger, attackNear, attackClamp, finish] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "madPianoFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mad Piano smoke passed")
    }
}
