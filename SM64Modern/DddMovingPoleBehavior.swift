import Foundation

struct SM64DddMovingPoleInput: Equatable, Sendable {
    let parentPosition: SM64ObjectVector3
    let parentFaceAngles: SM64ObjectAngles
    let parentMoveAngles: SM64ObjectAngles
}

struct SM64DddMovingPoleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let faceAngles: SM64ObjectAngles
    let moveAngles: SM64ObjectAngles
}

/// Value counterpart of `bhv_ddd_moving_pole_loop`.
enum SM64DddMovingPoleBehavior {
    static func update(_ input: SM64DddMovingPoleInput) -> SM64DddMovingPoleOutput {
        SM64DddMovingPoleOutput(
            position: input.parentPosition,
            faceAngles: input.parentFaceAngles,
            moveAngles: input.parentMoveAngles
        )
    }
}
