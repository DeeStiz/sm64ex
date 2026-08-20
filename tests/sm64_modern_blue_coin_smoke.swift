import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
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
struct SM64BlueCoinSmoke {
    static func main() {
        let idle = SM64BlueCoinSwitchBehavior.update(.init(
            action: .idle, timer: 0, positionY: 10, velocityY: 0,
            marioPositionY: 10, marioGroundPoundOnPlatform: false, hiddenCoinCount: 3
        ))
        let pound = SM64BlueCoinSwitchBehavior.update(.init(
            action: .idle, timer: 7, positionY: 10, velocityY: 0,
            marioPositionY: 100, marioGroundPoundOnPlatform: true, hiddenCoinCount: 3
        ))
        let recede = SM64BlueCoinSwitchBehavior.update(.init(
            action: .receding, timer: 5, positionY: 100, velocityY: -20,
            marioPositionY: 100, marioGroundPoundOnPlatform: false, hiddenCoinCount: 3
        ))
        let hide = SM64BlueCoinSwitchBehavior.update(.init(
            action: .receding, timer: 6, positionY: 0, velocityY: -20,
            marioPositionY: 200, marioGroundPoundOnPlatform: false, hiddenCoinCount: 3
        ))
        let fast = SM64BlueCoinSwitchBehavior.update(.init(
            action: .ticking, timer: 0, positionY: 160, velocityY: -20,
            marioPositionY: 200, marioGroundPoundOnPlatform: false, hiddenCoinCount: 2
        ))
        let slow = SM64BlueCoinSwitchBehavior.update(.init(
            action: .ticking, timer: 200, positionY: 160, velocityY: -20,
            marioPositionY: 200, marioGroundPoundOnPlatform: false, hiddenCoinCount: 2
        ))
        let expire = SM64BlueCoinSwitchBehavior.update(.init(
            action: .ticking, timer: 241, positionY: 160, velocityY: -20,
            marioPositionY: 200, marioGroundPoundOnPlatform: false, hiddenCoinCount: 2
        ))
        precondition(
            idle.action == .idle && idle.timer == 1 && idle.positionY == 10 && idle.velocityY == 0
                && idle.scale == 3 && idle.visible && idle.collisionEnabled && idle.loadCollisionModel
                && idle.sound == .none && !idle.shouldDelete,
            "blue-coin switch idle route"
        )
        precondition(
            pound.action == .receding && pound.timer == 0 && pound.velocityY == -20
                && pound.sound == .open && pound.visible && pound.collisionEnabled && pound.loadCollisionModel,
            "blue-coin switch ground-pound route"
        )
        precondition(
            recede.action == .receding && recede.timer == 6 && recede.positionY == 80
                && recede.collisionEnabled,
            "blue-coin switch receding route"
        )
        precondition(
            hide.action == .ticking && hide.timer == 0 && hide.positionY == 160
                && !hide.visible && hide.spawnMist,
            "blue-coin switch hide/tick transition"
        )
        precondition(fast.sound == .tickFast && slow.sound == .tickSlow && expire.shouldDelete, "blue-coin switch cadence")

        let inactive = SM64HiddenBlueCoinBehavior.update(.init(action: .inactive, timer: 0, switchAction: nil, interacted: false))
        let found = SM64HiddenBlueCoinBehavior.update(.init(action: .inactive, timer: 3, switchAction: .idle, interacted: false))
        let active = SM64HiddenBlueCoinBehavior.update(.init(action: .waiting, timer: 9, switchAction: .ticking, interacted: false))
        let blinkVisible = SM64HiddenBlueCoinBehavior.update(.init(action: .active, timer: 200, switchAction: .ticking, interacted: false))
        let blinkHidden = SM64HiddenBlueCoinBehavior.update(.init(action: .active, timer: 201, switchAction: .ticking, interacted: false))
        let timeout = SM64HiddenBlueCoinBehavior.update(.init(action: .active, timer: 243, switchAction: .ticking, interacted: false))
        let collected = SM64HiddenBlueCoinBehavior.update(.init(action: .active, timer: 20, switchAction: .ticking, interacted: true))
        precondition(!inactive.visible && !inactive.tangible && inactive.action == .inactive && inactive.timer == 1, "hidden blue coin inactive route")
        precondition(found.action == .waiting && found.timer == 0 && !found.visible, "hidden blue coin switch binding route")
        precondition(active.action == .active && active.timer == 0 && !active.visible, "hidden blue coin activation edge")
        precondition(blinkVisible.visible && !blinkVisible.shouldDelete && !blinkHidden.visible, "hidden blue coin blink cadence")
        precondition(timeout.shouldDelete && collected.spawnGoldenSparkles && collected.shouldDelete, "hidden blue coin retirement routes")

        var fingerprint = fnvOffset
        for output in [idle, pound, recede, hide, fast, slow, expire] {
            fingerprint = hash(fingerprint, output.action.rawValue)
            fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, output.positionY)
            fingerprint = hash(fingerprint, output.velocityY)
            fingerprint = hash(fingerprint, output.scale)
            fingerprint = hash(fingerprint, UInt64(output.visible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.collisionEnabled ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.loadCollisionModel ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.sound.rawValue))
            fingerprint = hash(fingerprint, UInt64(output.spawnMist ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
        }
        for output in [inactive, found, active, blinkVisible, blinkHidden, timeout, collected] {
            fingerprint = hash(fingerprint, output.action.rawValue)
            fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, UInt64(output.visible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.tangible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.spawnGoldenSparkles ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
        }
        print(String(format: "blueCoinFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern blue-coin switch/hidden-coin smoke passed")
    }
}
