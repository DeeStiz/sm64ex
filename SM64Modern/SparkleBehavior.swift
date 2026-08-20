import Foundation

struct SM64SparkleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
}

struct SM64SparkleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhvSparkle`. The source script initializes
/// `oAnimState` to -1, runs nine `ADD_INT` commands, then deactivates.
enum SM64SparkleBehavior {
    static func update(_ input: SM64SparkleInput) -> SM64SparkleOutput {
        SM64SparkleOutput(
            position: input.position,
            animationState: input.animationState &+ 9,
            shouldDeactivate: true
        )
    }
}
