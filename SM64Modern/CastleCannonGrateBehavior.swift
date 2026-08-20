import Foundation

struct SM64CastleCannonGrateInput: Equatable, Sendable { let totalStarCount: Int32 }
struct SM64CastleCannonGrateOutput: Equatable, Sendable { let shouldDeactivate: Bool; let collisionDistance: Float; let shouldLoadCollisionModel: Bool }

enum SM64CastleCannonGrateBehavior {
    static func update(_ input: SM64CastleCannonGrateInput) -> SM64CastleCannonGrateOutput {
        .init(shouldDeactivate: input.totalStarCount >= 120, collisionDistance: 4_000, shouldLoadCollisionModel: true)
    }
}
