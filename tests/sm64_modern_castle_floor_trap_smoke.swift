import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
@main struct SM64CastleFloorTrapSmoke {
    static func main() {
        let open = SM64CastleFloorTrapBehavior.update(.init(role: .parent, action: 0, timer: 0, roll: 0, angleVelocity: 0, interactTurn: true, marioActionExit: false, marioOnPlatform: false, marioDistance: 0, parentRoll: 0))
        let opening = SM64CastleFloorTrapBehavior.update(.init(role: .parent, action: 1, timer: 0, roll: 0, angleVelocity: 0x400, interactTurn: false, marioActionExit: false, marioOnPlatform: false, marioDistance: 0, parentRoll: 0))
        let child = SM64CastleFloorTrapBehavior.update(.init(role: .child, action: 0, timer: 0, roll: 0, angleVelocity: 0, interactTurn: false, marioActionExit: false, marioOnPlatform: true, marioDistance: 0, parentRoll: -0x4000))
        let close = SM64CastleFloorTrapBehavior.update(.init(role: .parent, action: 3, timer: 0, roll: 0, angleVelocity: 0x400, interactTurn: false, marioActionExit: false, marioOnPlatform: false, marioDistance: 0, parentRoll: 0))
        precondition(open.action == 1 && open.angleVelocity == 0x400, "castle trap open trigger")
        precondition(opening.roll == 0x300 && opening.playOpenSound, "castle trap opening")
        precondition(child.roll == -0x4000 && child.parentTurn, "castle trap child copy")
        precondition(close.action == 0 && close.clearTurn, "castle trap close")
        var fingerprint = offset
        for output in [open, opening, child, close] { fingerprint = hash(fingerprint, UInt64(output.role.rawValue)); fingerprint = hash(fingerprint, UInt64(output.action)); fingerprint = hash(fingerprint, UInt64(output.timer)); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.roll))); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.angleVelocity))); fingerprint = hash(fingerprint, UInt64(output.playOpenSound ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.parentTurn ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.clearTurn ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.loadCollisionModel ? 1 : 0)) }
        print(String(format: "castleFloorTrapFingerprint=0x%016llx", fingerprint)); print("SM64 Modern castle-floor-trap smoke passed")
    }
}
