import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func append(
    _ output: SM64WfSolidTowerPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, output.shouldDelete ? 1 : 0)
}

@main
enum SM64ModernWfSolidTowerPlatformSmoke {
    static func main() {
        let waiting = SM64WfSolidTowerPlatformBehavior.update(
            SM64WfSolidTowerPlatformInput(parentAction: 0)
        )
        let deleting = SM64WfSolidTowerPlatformBehavior.update(
            SM64WfSolidTowerPlatformInput(parentAction: 3)
        )
        precondition(waiting == SM64WfSolidTowerPlatformOutput(shouldDelete: false))
        precondition(deleting == SM64WfSolidTowerPlatformOutput(shouldDelete: true))
        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(deleting, to: &fingerprint)
        print(String(format: "wfSolidTowerPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern WF solid tower platform smoke passed")
    }
}
