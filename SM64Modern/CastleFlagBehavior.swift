import Foundation

struct SM64CastleFlagInput: Equatable, Sendable { let initialized: Bool; let animationFrame: Int32; let randomFrame: Int32 }
struct SM64CastleFlagOutput: Equatable, Sendable { let initialized: Bool; let animationFrame: Int32; let timer: Int32 }
enum SM64CastleFlagBehavior { static func update(_ input: SM64CastleFlagInput) -> SM64CastleFlagOutput { .init(initialized: true, animationFrame: input.initialized ? input.animationFrame : max(0, min(27, input.randomFrame)), timer: 1) } }
