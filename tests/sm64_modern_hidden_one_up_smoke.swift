import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 255
        result &*= prime
    }
    return result
}

private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 {
    hash(seed, UInt64(bitPattern: Int64(value)))
}

private func hash(_ seed: UInt64, _ value: Float) -> UInt64 {
    hash(seed, UInt64(value.bitPattern))
}

@main
struct SM64HiddenOneUpSmoke {
    static func main() {
        let hidden = SM64HiddenOneUpBehavior.update(.init(
            role: .hidden, action: 0, timer: 0, behaviorByte: 2, triggerCount: 2,
            touchedMario: false, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let rise = SM64HiddenOneUpBehavior.update(.init(
            role: .hidden, action: 3, timer: 18, behaviorByte: 2, triggerCount: 2,
            touchedMario: false, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let trigger = SM64HiddenOneUpBehavior.update(.init(
            role: .trigger, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: true, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let spawner = SM64HiddenOneUpBehavior.update(.init(
            role: .poleSpawner, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: false, marioNear: true, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let disappear = SM64HiddenOneUpBehavior.update(.init(
            role: .hidden, action: 2, timer: 30, behaviorByte: 0, triggerCount: 0,
            touchedMario: false, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let stationary = SM64HiddenOneUpBehavior.update(.init(
            role: .oneUp, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: true, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let walking = SM64HiddenOneUpBehavior.update(.init(
            role: .walking, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: false, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let running = SM64HiddenOneUpBehavior.update(.init(
            role: .runningAway, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: false, marioNear: false, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let sliding = SM64HiddenOneUpBehavior.update(.init(
            role: .sliding, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: false, marioNear: true, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))
        let jump = SM64HiddenOneUpBehavior.update(.init(
            role: .jumpOnApproach, action: 0, timer: 0, behaviorByte: 0, triggerCount: 0,
            touchedMario: false, marioNear: true, outsideRange: false,
            pitch: 0, forwardVelocity: 0
        ))

        precondition(hidden.action == 3 && hidden.playAppearSound && hidden.verticalVelocity == 40, "hidden one-up reveal")
        precondition(rise.spawnSparkle && rise.visible, "hidden one-up sparkle")
        precondition(trigger.consumeTrigger && trigger.shouldDelete, "hidden one-up trigger")
        precondition(spawner.spawnPoleChildren && spawner.shouldDelete, "pole one-up spawner")
        precondition(disappear.shouldDelete && !disappear.tangible, "hidden one-up expiry")
        precondition(stationary.shouldDelete && !stationary.tangible, "stationary one-up interaction")
        precondition(walking.playAppearSound && walking.verticalVelocity == 40, "walking one-up rise")
        precondition(running.playAppearSound && running.verticalVelocity == 40, "running one-up rise")
        precondition(sliding.action == 1 && sliding.tangible, "sliding one-up approach")
        precondition(jump.action == 1 && jump.tangible && jump.verticalVelocity == 40, "jump one-up approach")

        var fingerprint = offset
        for output in [hidden, rise, trigger, spawner, disappear, stationary, walking, running, sliding, jump] {
            fingerprint = hash(fingerprint, Int32(output.role.rawValue))
            fingerprint = hash(fingerprint, output.action)
            fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, output.triggerCount)
            fingerprint = hash(fingerprint, UInt64(output.visible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.tangible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
            fingerprint = hash(fingerprint, output.pitch)
            fingerprint = hash(fingerprint, output.forwardVelocity)
            fingerprint = hash(fingerprint, output.verticalVelocity)
            fingerprint = hash(fingerprint, UInt64(output.spawnSparkle ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.playAppearSound ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.consumeTrigger ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.spawnPoleChildren ? 1 : 0))
        }
        print(String(format: "hiddenOneUpFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern hidden-one-up smoke passed")
    }
}
