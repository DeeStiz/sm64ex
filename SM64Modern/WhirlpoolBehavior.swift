import Foundation

struct SM64WhirlpoolInput: Equatable, Sendable {
    let distanceToMario: Float
    let position: SM64ObjectVector3
    let initialFacePitch: Int32
    let initialFaceRoll: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let faceYaw: Int32
    let timer: Int32
}

struct SM64WhirlpoolOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let facePitch: Int32
    let faceRoll: Int32
    let faceYaw: Int32
    let particleCount: Int32
    let visible: Bool
    let playWaterSound: Bool
    let timer: Int32
}

/// Value counterpart of `bhv_whirlpool_loop`.
enum SM64WhirlpoolBehavior {
    static func update(_ input: SM64WhirlpoolInput) -> SM64WhirlpoolOutput {
        let visible = input.distanceToMario < 5_000
        return .init(position: input.position, facePitch: input.facePitch, faceRoll: input.faceRoll, faceYaw: input.faceYaw &+ 0x1F40, particleCount: visible ? 60 : 0, visible: visible, playWaterSound: true, timer: input.timer &+ 1)
    }
}
