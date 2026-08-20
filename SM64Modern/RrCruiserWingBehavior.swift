import Foundation

struct SM64RrCruiserWingInput: Equatable, Sendable {
    let timer: Int32
    let baseYaw: Int32
    let basePitch: Int32
    let reverse: Bool
}

struct SM64RrCruiserWingOutput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
    let facePitch: Int32
    let playRockSound: Bool
}

/// Value counterpart of `bhv_rr_cruiser_wing_loop`.
enum SM64RrCruiserWingBehavior {
    static func update(_ input: SM64RrCruiserWingInput) -> SM64RrCruiserWingOutput {
        let phase = Int16(truncatingIfNeeded: input.timer &* 0x400)
        let sign: Float = input.reverse ? -1 : 1
        let yaw = input.baseYaw + Int32(SM64CanonicalTrig.sins(phase) * 8_192 * sign)
        let pitch = input.basePitch + Int32(SM64CanonicalTrig.coss(phase) * 2_048)
        return .init(timer: input.timer == 64 ? 0 : input.timer &+ 1, faceYaw: yaw, facePitch: pitch, playRockSound: input.timer == 64)
    }
}
