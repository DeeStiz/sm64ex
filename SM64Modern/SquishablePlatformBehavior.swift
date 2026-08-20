import Foundation
struct SM64SquishablePlatformInput: Equatable, Sendable { let platformTimer: Int32 }
struct SM64SquishablePlatformOutput: Equatable, Sendable { let scaleY: Float; let platformTimer: Int32 }
enum SM64SquishablePlatformBehavior { static func update(_ input: SM64SquishablePlatformInput)->SM64SquishablePlatformOutput { let sine=SM64CanonicalTrig.sins(Int16(truncatingIfNeeded:input.platformTimer));let scaleY=SM64DeterministicPrimitives.cFloatMultiply(sine+1,0.3)+0.4;return .init(scaleY:scaleY,platformTimer:input.platformTimer &+ 0x80) } }
