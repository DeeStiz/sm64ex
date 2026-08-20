import Foundation

struct SM64BlueFlamesGroupInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let moveYaw: Int32
    let scale: Float
}

struct SM64BlueFlamesGroupOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let scale: Float
    let spawnCount: Int32
    let shouldDeactivate: Bool
}

enum SM64BlueFlamesGroupBehavior {
    static func update(_ input: SM64BlueFlamesGroupInput) -> SM64BlueFlamesGroupOutput {
        SM64BlueFlamesGroupOutput(
            position: input.position,
            moveYaw: input.moveYaw,
            scale: input.scale,
            spawnCount: input.timer < 16 && input.timer % 2 == 0 ? 3 : 0,
            shouldDeactivate: input.timer >= 16
        )
    }
}
