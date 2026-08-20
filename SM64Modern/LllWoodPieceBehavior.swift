import Foundation

struct SM64LllWoodPieceInput: Equatable, Sendable { let timer: Int32; let positionY: Float; let homeY: Float; let oscillationTimer: Int32; let parentAction: Int32 }
struct SM64LllWoodPieceOutput: Equatable, Sendable { let positionY: Float; let oscillationTimer: Int32; let shouldDelete: Bool }
enum SM64LllWoodPieceBehavior {
    static func update(_ input: SM64LllWoodPieceInput) -> SM64LllWoodPieceOutput {
        var positionY = input.positionY
        if input.timer == 0 { positionY -= 100 }
        positionY += SM64DeterministicPrimitives.cFloatMultiply(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.oscillationTimer)), 3)
        return SM64LllWoodPieceOutput(positionY: positionY, oscillationTimer: input.oscillationTimer &+ 0x400, shouldDelete: input.parentAction == 2)
    }
}
