import Foundation

struct SM64CoinFormationOutput: Equatable, Sendable {
    let count: Int
    let spawnChildCoins: Bool
    let deactivateParent: Bool
}

struct SM64CoinFormationChild: Equatable, Sendable {
    let offsetX: Float
    let offsetY: Float
    let offsetZ: Float
    let aboveFloor: Bool
}

struct SM64CoinFormationPatternOutput: Equatable, Sendable {
    let pattern: Int32
    let children: [SM64CoinFormationChild]
}

enum SM64CoinFormationBehavior {
    static func update(count: Int) -> SM64CoinFormationOutput {
        let valid = count == 3 || count == 10
        return .init(count: valid ? count : 0, spawnChildCoins: valid, deactivateParent: valid)
    }

    /// Source counterpart of `spawn_coin_in_formation`. The five authored
    /// patterns use fixed integer offsets; pattern bit 0x10 disables the
    /// above-floor (+300 Y) child placement.
    static func updatePattern(pattern: Int32, respawnMask: UInt8 = 0) -> SM64CoinFormationPatternOutput {
        var children: [SM64CoinFormationChild] = []
        for index in 0..<8 where respawnMask & (1 << UInt8(index)) == 0 {
            var x: Float = 0
            var y: Float = 0
            var z: Float = 0
            var aboveFloor = true
            switch pattern & 7 {
            case 0:
                z = Float(160 * (index - 2))
                if index > 4 { continue }
            case 1:
                aboveFloor = false
                y = Float(128 * index)
                if index > 4 { continue }
            case 2:
                let angle = Int16(truncatingIfNeeded: index << 13)
                x = SM64CanonicalTrig.sins(angle) * 300
                z = SM64CanonicalTrig.coss(angle) * 300
            case 3:
                aboveFloor = false
                let angle = Int16(truncatingIfNeeded: index << 13)
                x = SM64CanonicalTrig.coss(angle) * 200
                y = SM64CanonicalTrig.sins(angle) * 200 + 200
            case 4:
                let table: [(Int, Int)] = [(0, -150), (0, -50), (0, 50), (0, 150), (-50, 100), (-100, 50), (50, 100), (100, 50)]
                x = Float(table[index].0)
                z = Float(table[index].1)
            default:
                continue
            }
            if pattern & 0x10 != 0 { aboveFloor = false }
            children.append(.init(offsetX: x, offsetY: y, offsetZ: z, aboveFloor: aboveFloor))
        }
        return .init(pattern: pattern, children: children)
    }
}
