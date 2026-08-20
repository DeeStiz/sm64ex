import Foundation

struct SM64CelebrationStarSparkleInput: Equatable, Sendable { let position: SM64ObjectVector3; let timer: Int32; let animationState: Int32 }
struct SM64CelebrationStarSparkleOutput: Equatable, Sendable { let position: SM64ObjectVector3; let animationState: Int32; let graphYOffset: Float; let shouldDeactivate: Bool }

enum SM64CelebrationStarSparkleBehavior {
    static func update(_ input: SM64CelebrationStarSparkleInput) -> SM64CelebrationStarSparkleOutput {
        var position = input.position
        position.y -= 15
        return SM64CelebrationStarSparkleOutput(position: position, animationState: input.animationState &+ 1, graphYOffset: 25, shouldDeactivate: input.timer == 12)
    }
}
