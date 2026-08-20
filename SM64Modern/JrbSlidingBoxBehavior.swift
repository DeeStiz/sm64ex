import Foundation

struct SM64JrbSlidingBoxInput: Equatable, Sendable {
    let parentPosition: SM64ObjectVector3
    let parentAngles: SM64ObjectAngles
    let relativePosition: SM64ObjectVector3
    let phase: Int32
    let y: Float
}

struct SM64JrbSlidingBoxOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let faceAngles: SM64ObjectAngles
    let phase: Int32
    let relativePosition: SM64ObjectVector3
    let tangible: Bool
    let playSlideSound: Bool
}

/// Value counterpart of `bhv_jrb_sliding_box_loop`.
enum SM64JrbSlidingBoxBehavior {
    static func update(_ input: SM64JrbSlidingBoxInput) -> SM64JrbSlidingBoxOutput {
        let displacement = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.phase)) * 20
        let relative = SM64ObjectVector3(x: input.relativePosition.x, y: input.relativePosition.y, z: input.relativePosition.z + displacement)
        let position = SM64ObjectVector3(x: input.parentPosition.x + relative.x, y: input.parentPosition.y + relative.y, z: input.parentPosition.z + relative.z)
        let nextPhase = input.phase &+ 0x100
        return .init(position: position, faceAngles: .init(pitch: input.parentAngles.pitch, yaw: input.parentAngles.yaw, roll: input.parentAngles.roll), phase: nextPhase, relativePosition: relative, tangible: (nextPhase & 0x7FFF) == 0, playSlideSound: abs(displacement) > 3)
    }
}
