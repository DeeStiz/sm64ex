import Foundation

struct SM64CannonBaseUnusedInput: Equatable, Sendable { let position: SM64ObjectVector3; let velocityY: Float; let timer: Int32; let animationState: Int32 }
struct SM64CannonBaseUnusedOutput: Equatable, Sendable { let position: SM64ObjectVector3; let animationState: Int32; let shouldDeactivate: Bool }

enum SM64CannonBaseUnusedBehavior {
    static func update(_ input: SM64CannonBaseUnusedInput) -> SM64CannonBaseUnusedOutput {
        .init(position: .init(x: input.position.x, y: input.position.y + input.velocityY, z: input.position.z), animationState: input.animationState &+ 1, shouldDeactivate: input.timer >= 7)
    }
}
