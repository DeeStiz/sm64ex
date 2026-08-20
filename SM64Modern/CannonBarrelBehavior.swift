import Foundation

struct SM64CannonBarrelInput: Equatable, Sendable {
    let parentPosition: SM64ObjectVector3
    let parentMoveYaw: Int32
    let parentMovePitch: Int32
    let parentActive: Bool
}

struct SM64CannonBarrelOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let facePitch: Int32
    let visible: Bool
}

enum SM64CannonBarrelBehavior {
    static func update(_ input: SM64CannonBarrelInput) -> SM64CannonBarrelOutput {
        .init(position: input.parentPosition, moveYaw: input.parentMoveYaw, facePitch: input.parentMovePitch, visible: input.parentActive)
    }
}
