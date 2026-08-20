import Foundation

enum SM64TextSurfaceKind: UInt8, Equatable, Sendable { case messagePanel = 0; case signOnWall = 1 }
struct SM64TextSurfaceInput: Equatable, Sendable { let kind: SM64TextSurfaceKind; let timer: Int32 }
struct SM64TextSurfaceOutput: Equatable, Sendable { let kind: SM64TextSurfaceKind; let timer: Int32; let loadCollisionModel: Bool; let interactionTypeText: Bool; let hitboxRadius: Float; let hitboxHeight: Float; let resetInteraction: Bool }
enum SM64TextSurfaceBehavior { static func update(_ input: SM64TextSurfaceInput) -> SM64TextSurfaceOutput { .init(kind: input.kind, timer: input.timer &+ 1, loadCollisionModel: input.kind == .messagePanel, interactionTypeText: true, hitboxRadius: 150, hitboxHeight: 80, resetInteraction: true) } }
