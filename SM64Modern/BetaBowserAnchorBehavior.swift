import Foundation

struct SM64BetaBowserAnchorInput: Equatable, Sendable { let marioPosition: SM64ObjectVector3; let marioYaw: Int32; let debugRadius: Float; let debugHeight: Float }
struct SM64BetaBowserAnchorOutput: Equatable, Sendable { let position: SM64ObjectVector3; let hitboxRadius: Float; let hitboxHeight: Float; let attackCollidedObjects: Bool }
enum SM64BetaBowserAnchorBehavior {
    static func update(_ input: SM64BetaBowserAnchorInput) -> SM64BetaBowserAnchorOutput { let yaw = Int16(truncatingIfNeeded: input.marioYaw); return .init(position: .init(x: input.marioPosition.x + SM64CanonicalTrig.sins(yaw) * 300, y: input.marioPosition.y + 30, z: input.marioPosition.z + SM64CanonicalTrig.coss(yaw) * 300), hitboxRadius: input.debugRadius + 100, hitboxHeight: input.debugHeight + 300, attackCollidedObjects: true) }
}
