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

private func row(_ output: SM64FallingBowserPlatformOutput) -> [UInt64] {
    [
        UInt64(bitPattern: Int64(output.action)),
        UInt64(bitPattern: Int64(output.subAction)),
        UInt64(bitPattern: Int64(output.timer)),
        UInt64(bitPattern: Int64(output.collisionVariant)),
        UInt64(bitPattern: Int64(output.shakeCounter)),
        output.cameraShake ? 1 : 0,
        output.shouldDelete ? 1 : 0,
    ]
}

@main
struct SM64FallingBowserPlatformSmoke {
    static func main() {
        let waiting = SM64FallingBowserPlatformBehavior.update(.init(
            action: 0, subAction: 0, timer: 0, position: .zero, velocityY: 0,
            gravity: 0, variant: 1, bowserPresent: false, bowserOnPlatform: false,
            bowserAction: 0, bowserFireFlag: false, bowserHealth: 3, bowserHeld: false,
            debugValue: 0, shakeCounter: 0
        ))
        let activated = SM64FallingBowserPlatformBehavior.update(.init(
            action: 0, subAction: 0, timer: 0, position: .zero, velocityY: 0,
            gravity: 0, variant: 2, bowserPresent: true, bowserOnPlatform: false,
            bowserAction: 0, bowserFireFlag: false, bowserHealth: 3, bowserHeld: false,
            debugValue: 0, shakeCounter: 0
        ))
        let fireTrigger = SM64FallingBowserPlatformBehavior.update(.init(
            action: 1, subAction: 0, timer: 5, position: .zero, velocityY: 0,
            gravity: 0, variant: 2, bowserPresent: true, bowserOnPlatform: true,
            bowserAction: 13, bowserFireFlag: true, bowserHealth: 3, bowserHeld: false,
            debugValue: 0, shakeCounter: 0
        ))
        let fall = SM64FallingBowserPlatformBehavior.update(.init(
            action: 2, subAction: 0, timer: 0, position: .zero, velocityY: 0,
            gravity: 0, variant: 2, bowserPresent: true, bowserOnPlatform: false,
            bowserAction: 0, bowserFireFlag: false, bowserHealth: 3, bowserHeld: false,
            debugValue: 0, shakeCounter: 0
        ))
        let retired = SM64FallingBowserPlatformBehavior.update(.init(
            action: 2, subAction: 0, timer: 301, position: .zero, velocityY: 0,
            gravity: -4, variant: 2, bowserPresent: true, bowserOnPlatform: false,
            bowserAction: 0, bowserFireFlag: false, bowserHealth: 3, bowserHeld: false,
            debugValue: 0, shakeCounter: 0
        ))
        precondition(waiting.action == 0 && waiting.timer == 1 && waiting.collisionVariant == 1)
        precondition(activated.action == 1 && activated.timer == 0 && activated.collisionVariant == 2)
        precondition(fireTrigger.action == 2 && fireTrigger.timer == 0)
        precondition(fall.velocityY == 8 && fall.gravity == 0 && fall.cameraShake)
        precondition(retired.shouldDelete)
        var fingerprint = offset
        for output in [waiting, activated, fireTrigger, fall, retired] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "fallingBowserPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern falling Bowser platform smoke passed")
    }
}
