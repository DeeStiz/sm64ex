import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 { hash ^= (value >> UInt64(byte * 8)) & 0xff; hash &*= fnvPrime }
    return hash
}

@main
struct SM64RotatingExclamationMarkSmoke {
    static func main() {
        let active = SM64RotatingExclamationMarkBehavior.update(
            SM64RotatingExclamationMarkInput(parentAction: 1, moveYaw: 0x7fff)
        )
        let deleted = SM64RotatingExclamationMarkBehavior.update(
            SM64RotatingExclamationMarkInput(parentAction: 2, moveYaw: -0x100)
        )
        precondition(active.moveYaw == 0x87ff && !active.shouldDelete)
        precondition(deleted.moveYaw == 0x700 && deleted.shouldDelete)
        var fingerprint = fnvOffset
        for output in [active, deleted] {
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(output.moveYaw)))
            fingerprint = hashU64(fingerprint, output.shouldDelete ? 1 : 0)
        }
        print(String(format: "rotatingExclamationMarkFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern rotating exclamation mark smoke passed")
    }
}
