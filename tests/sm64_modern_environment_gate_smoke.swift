import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
@main struct SM64EnvironmentGateSmoke {
    static func main() {
        let locked = SM64EnvironmentGateBehavior.update(.init(role: .bowserSubDoor, timer: 0, submarineUnlocked: false, moatDrained: false))
        let unlocked = SM64EnvironmentGateBehavior.update(.init(role: .bowsersSub, timer: 0, submarineUnlocked: true, moatDrained: false))
        let drained = SM64EnvironmentGateBehavior.update(.init(role: .moatGrills, timer: 4, submarineUnlocked: false, moatDrained: true))
        let bridge = SM64EnvironmentGateBehavior.update(.init(role: .invisibleObjectsUnderBridge, timer: 0, submarineUnlocked: false, moatDrained: true))
        precondition(locked.loadCollisionModel && !locked.shouldDelete, "submarine locked collision")
        precondition(unlocked.shouldDelete && !unlocked.loadCollisionModel, "submarine unlock delete")
        precondition(drained.modelNone && !drained.loadCollisionModel, "moat grill drain")
        precondition(bridge.shouldDelete && bridge.environmentLevel6 == -800 && bridge.environmentLevel12 == -800, "bridge moat write")
        var fingerprint = offset
        for output in [locked, unlocked, drained, bridge] { fingerprint = hash(fingerprint, UInt64(output.role.rawValue)); fingerprint = hash(fingerprint, UInt64(output.timer)); fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.loadCollisionModel ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.modelNone ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.environmentLevel6 ?? 0))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.environmentLevel12 ?? 0))) }
        print(String(format: "environmentGateFingerprint=0x%016llx", fingerprint)); print("SM64 Modern environment-gate smoke passed")
    }
}
