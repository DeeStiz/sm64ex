import Foundation
private let off: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
@main struct SM64CapSwitchSmoke {
    static func main() {
        let initialize = SM64CapSwitchBehavior.update(.init(action: .initialize, timer: 0, variant: 0, positionY: 100, saveFlags: 0, levelIsUnknown32: false, marioOnPlatform: false, dialogComplete: false))
        let alreadyPressed = SM64CapSwitchBehavior.update(.init(action: .initialize, timer: 0, variant: 1, positionY: 100, saveFlags: 1 << 2, levelIsUnknown32: false, marioOnPlatform: false, dialogComplete: false))
        let activate = SM64CapSwitchBehavior.update(.init(action: .waiting, timer: 4, variant: 0, positionY: 171, saveFlags: 0, levelIsUnknown32: false, marioOnPlatform: true, dialogComplete: false))
        let press0 = SM64CapSwitchBehavior.update(.init(action: .pressing, timer: 0, variant: 0, positionY: 171, saveFlags: 1 << 1, levelIsUnknown32: false, marioOnPlatform: false, dialogComplete: false))
        let press4 = SM64CapSwitchBehavior.update(.init(action: .pressing, timer: 4, variant: 0, positionY: 171, saveFlags: 1 << 1, levelIsUnknown32: false, marioOnPlatform: false, dialogComplete: false))
        let finish = SM64CapSwitchBehavior.update(.init(action: .pressing, timer: 5, variant: 0, positionY: 171, saveFlags: 1 << 1, levelIsUnknown32: false, marioOnPlatform: false, dialogComplete: true))
        precondition(initialize.action == .waiting && initialize.timer == 0 && initialize.positionY == 171 && initialize.scaleY == 0.5 && initialize.spawnBase, "cap switch initialization")
        precondition(alreadyPressed.action == .pressed && alreadyPressed.scaleY == 0.1, "cap switch saved-flag gate")
        precondition(activate.action == .pressing && activate.timer == 0 && activate.saveFlagToSet == 1 << 1 && activate.playSound, "cap switch activation")
        precondition(press0.scaleY == 0.5 && !press0.spawnMist && !press0.rumble, "cap switch press start")
        precondition(press4.scaleY == 0.1 && press4.spawnMist && press4.spawnTriangleBreak && press4.rumble, "cap switch press effects")
        precondition(finish.action == .pressed && finish.timer == 0 && finish.scaleY == 0.1, "cap switch dialog finish")
        var f = off
        for output in [initialize, alreadyPressed, activate, press0, press4, finish] {
            f = hash(f, output.action.rawValue); f = hash(f, output.timer); f = hash(f, output.variant); f = hash(f, output.positionY); f = hash(f, output.scaleX); f = hash(f, output.scaleY); f = hash(f, output.scaleZ); f = hash(f, output.animationState); f = hash(f, UInt64(output.spawnBase ? 1 : 0)); f = hash(f, UInt64(output.saveFlagToSet)); f = hash(f, UInt64(output.playSound ? 1 : 0)); f = hash(f, UInt64(output.spawnMist ? 1 : 0)); f = hash(f, UInt64(output.spawnTriangleBreak ? 1 : 0)); f = hash(f, UInt64(output.rumble ? 1 : 0)); f = hash(f, UInt64(output.shouldLoadCollisionModel ? 1 : 0))
        }
        let base = SM64CapSwitchBaseBehavior.update(.init(timer: 0)); f = hash(f, base.timer); f = hash(f, UInt64(base.shouldLoadCollisionModel ? 1 : 0))
        print(String(format: "capSwitchFingerprint=0x%016llx", f)); print("SM64 Modern cap-switch smoke passed")
    }
}
