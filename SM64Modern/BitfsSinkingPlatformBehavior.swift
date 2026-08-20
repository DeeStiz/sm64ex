import Foundation

enum SM64BitfsSinkingPlatformKind: UInt8, Equatable, Sendable { case platform = 0; case cage = 1 }
struct SM64BitfsSinkingPlatformInput: Equatable, Sendable { let kind: SM64BitfsSinkingPlatformKind; let timer: Int32; let positionY: Float; let platformTimer: Int32; let cageParameter: UInt8 }
struct SM64BitfsSinkingPlatformOutput: Equatable, Sendable { let positionY: Float; let platformTimer: Int32 }

/// Value counterpart of the BITFS sinking platform/cage loops.
enum SM64BitfsSinkingPlatformBehavior {
    static func update(_ input: SM64BitfsSinkingPlatformInput) -> SM64BitfsSinkingPlatformOutput {
        var positionY = input.positionY
        if input.kind == .platform {
            positionY -= SM64DeterministicPrimitives.cFloatMultiply(
                SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.platformTimer)), 0.58
            )
        } else if input.cageParameter != 0 {
            if input.timer == 0 { positionY -= 300 }
            positionY += SM64DeterministicPrimitives.cFloatMultiply(
                SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.platformTimer)), 7
            )
        } else {
            positionY -= SM64DeterministicPrimitives.cFloatMultiply(
                SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.platformTimer)), 3
            )
        }
        return SM64BitfsSinkingPlatformOutput(positionY: positionY, platformTimer: input.platformTimer &+ 0x100)
    }
}
