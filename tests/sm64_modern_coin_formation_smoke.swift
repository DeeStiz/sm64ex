import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
@main struct SM64CoinFormationSmoke {
    static func main() {
        let rows = [SM64CoinFormationBehavior.update(count: 3), SM64CoinFormationBehavior.update(count: 10), SM64CoinFormationBehavior.update(count: 4)]
        precondition(rows[0].spawnChildCoins && rows[0].deactivateParent && rows[0].count == 3)
        precondition(rows[1].spawnChildCoins && rows[1].deactivateParent && rows[1].count == 10)
        precondition(!rows[2].spawnChildCoins && !rows[2].deactivateParent && rows[2].count == 0)
        let patternRows = [
            SM64CoinFormationBehavior.updatePattern(pattern: 0),
            SM64CoinFormationBehavior.updatePattern(pattern: 1),
            SM64CoinFormationBehavior.updatePattern(pattern: 4),
        ]
        precondition(patternRows[0].children.count == 5 && patternRows[0].children[0].offsetZ == -320 && patternRows[0].children.allSatisfy(\.aboveFloor))
        precondition(patternRows[1].children.count == 5 && patternRows[1].children[4].offsetY == 512 && patternRows[1].children.allSatisfy { !$0.aboveFloor })
        precondition(patternRows[2].children.count == 8 && patternRows[2].children[6].offsetX == 50 && patternRows[2].children[6].offsetZ == 100)
        var fingerprint = offset
        for row in rows { fingerprint = hash(fingerprint, UInt64(row.count)); fingerprint = hash(fingerprint, UInt64(row.spawnChildCoins ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(row.deactivateParent ? 1 : 0)) }
        for row in patternRows {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(row.pattern)))
            fingerprint = hash(fingerprint, UInt64(row.children.count))
            for child in row.children {
                fingerprint = hash(fingerprint, child.offsetX)
                fingerprint = hash(fingerprint, child.offsetY)
                fingerprint = hash(fingerprint, child.offsetZ)
                fingerprint = hash(fingerprint, UInt64(child.aboveFloor ? 1 : 0))
            }
        }
        print(String(format: "coinFormationFingerprint=0x%016llx", fingerprint)); print("SM64 Modern coin formation smoke passed")
    }
}
