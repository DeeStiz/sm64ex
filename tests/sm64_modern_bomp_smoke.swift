import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= prime
    }
    return result
}

private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }

private func hash(_ seed: UInt64, _ output: SM64BompOutput) -> UInt64 {
    var result = hash(seed, UInt64(output.variant.rawValue))
    result = hash(result, UInt64(output.action.rawValue))
    result = hash(result, output.timer)
    result = hash(result, output.position.x)
    result = hash(result, output.position.y)
    result = hash(result, output.position.z)
    result = hash(result, output.forwardVelocity)
    result = hash(result, output.moveYaw)
    result = hash(result, UInt64(output.sound ? 1 : 0))
    return hash(result, UInt64(output.clamped ? 1 : 0))
}

@main
struct SM64BompSmoke {
    static func main() {
        let rows = [
            SM64BompBehavior.update(.init(variant: .small, action: .wait, timer: 100, position: .init(x: 3400, y: 0, z: 0), forwardVelocity: 0, moveYaw: 0)),
            SM64BompBehavior.update(.init(variant: .small, action: .pokeOut, timer: 15, position: .init(x: 3400, y: 0, z: 0), forwardVelocity: 30, moveYaw: 0)),
            SM64BompBehavior.update(.init(variant: .large, action: .extend, timer: 60, position: .init(x: 3900, y: 0, z: 0), forwardVelocity: 0, moveYaw: 0)),
            SM64BompBehavior.update(.init(variant: .large, action: .retract, timer: 90, position: .init(x: 3200, y: 0, z: 0), forwardVelocity: 0, moveYaw: 0)),
        ]
        precondition(rows[0].action == .wait && rows[0].timer == 101)
        precondition(rows[1].action == .extend && rows[1].forwardVelocity == 40 && rows[1].sound && rows[1].timer == 0)
        precondition(rows[2].action == .retract && rows[2].moveYaw == -0x8000 && rows[2].sound && rows[2].clamped)
        precondition(rows[3].action == .pokeOut && rows[3].forwardVelocity == 25 && rows[3].timer == 0 && rows[3].clamped)
        var fingerprint = offset
        for row in rows { fingerprint = hash(fingerprint, row) }
        print(String(format: "bompFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bomp smoke passed")
    }
}
