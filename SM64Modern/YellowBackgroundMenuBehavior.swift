import Foundation

struct SM64YellowBackgroundMenuInput: Equatable, Sendable {
    let timer: Int32
}

struct SM64YellowBackgroundMenuOutput: Equatable, Sendable {
    let timer: Int32
    let faceAngleYaw: Int32
    let scale: Float
}

/// Value counterpart of `beh_yellow_background_menu_init/loop`.
enum SM64YellowBackgroundMenuBehavior {
    static func update(_ input: SM64YellowBackgroundMenuInput) -> SM64YellowBackgroundMenuOutput {
        .init(timer: input.timer &+ 1, faceAngleYaw: -0x8000, scale: 9.0)
    }
}
