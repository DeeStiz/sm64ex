import Foundation
struct SM64SnowmanCheckpointOutput: Equatable, Sendable { let triggered: Bool; let shouldDeactivate: Bool; let counterIncrement: Int32 }
enum SM64SnowmanCheckpointBehavior { static func update(distanceToMario: Float, parentActive: Bool) -> SM64SnowmanCheckpointOutput { guard parentActive else { return .init(triggered:false,shouldDeactivate:true,counterIncrement:0) }; let triggered=distanceToMario < 800; return .init(triggered:triggered,shouldDeactivate:triggered,counterIncrement:triggered ? 1:0) } }
