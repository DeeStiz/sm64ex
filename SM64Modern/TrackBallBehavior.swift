import Foundation

struct SM64TrackBallInput: Equatable, Sendable {
    let behaviorByte: Int32
    let parentBaseBallIndex: Int32
}

struct SM64TrackBallOutput: Equatable, Sendable {
    let relativeIndex: Int32
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_track_ball_update`.
enum SM64TrackBallBehavior {
    static func update(_ input: SM64TrackBallInput) -> SM64TrackBallOutput {
        let behaviorByte = Int32(Int16(truncatingIfNeeded: input.behaviorByte))
        let baseIndex = Int32(Int16(truncatingIfNeeded: input.parentBaseBallIndex))
        let relativeIndex = behaviorByte &- baseIndex &- 1
        return .init(relativeIndex: relativeIndex, shouldDelete: relativeIndex < 1 || relativeIndex > 5)
    }
}
