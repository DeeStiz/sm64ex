import Foundation

struct SM64PyramidTopFragmentInput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
    let facePitch: Int32
    let scale: Float
}

struct SM64PyramidTopFragmentOutput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
    let facePitch: Int32
    let scale: Float
    let friction: Float
    let buoyancy: Float
    let animationState: Int32
    let deactivated: Bool
}

enum SM64PyramidTopFragmentBehavior {
    static func update(_ input: SM64PyramidTopFragmentInput) -> SM64PyramidTopFragmentOutput {
        .init(timer: input.timer &+ 1, faceYaw: input.faceYaw &+ 0x1000, facePitch: input.facePitch &+ 0x1000, scale: input.scale, friction: 0.999, buoyancy: 2, animationState: 3, deactivated: input.timer == 60)
    }
}
