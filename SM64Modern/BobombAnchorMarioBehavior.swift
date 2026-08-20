import Foundation

struct SM64BobombAnchorMarioInput: Equatable, Sendable {
    let parentMoveYaw: Int32
    let parentThrowState: Int32
    let parentActive: Bool
}

struct SM64BobombAnchorMarioOutput: Equatable, Sendable {
    let parentRelativePosition: SM64ObjectVector3
    let moveYaw: Int32
    let throwForwardVelocity: Float
    let throwVelocityY: Float
    let tossMario: Bool
    let throwMario: Bool
    let shouldDelete: Bool
}

enum SM64BobombAnchorMarioBehavior {
    static func update(_ input: SM64BobombAnchorMarioInput) -> SM64BobombAnchorMarioOutput {
        .init(
            parentRelativePosition: .init(x: 100, y: 0, z: 150),
            moveYaw: input.parentMoveYaw,
            throwForwardVelocity: input.parentThrowState == 2 ? 50 : input.parentThrowState == 3 ? 10 : 0,
            throwVelocityY: input.parentThrowState == 2 ? 50 : input.parentThrowState == 3 ? 10 : 0,
            tossMario: input.parentThrowState == 3,
            throwMario: input.parentThrowState == 2,
            shouldDelete: !input.parentActive
        )
    }
}
