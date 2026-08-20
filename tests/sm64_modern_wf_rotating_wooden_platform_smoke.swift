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
    _ output: SM64WfRotatingWoodenPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.faceYaw))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.angleVelocityYaw))
    fingerprint = hashU32(fingerprint, output.playedSound ? 1 : 0)
}

@main
enum SM64ModernWfRotatingWoodenPlatformSmoke {
    static func main() {
        let waiting = SM64WfRotatingWoodenPlatformBehavior.update(
            SM64WfRotatingWoodenPlatformInput(action: 0, timer: 60, faceYaw: 100)
        )
        let start = SM64WfRotatingWoodenPlatformBehavior.update(
            SM64WfRotatingWoodenPlatformInput(action: 0, timer: 61, faceYaw: 100)
        )
        let spinning = SM64WfRotatingWoodenPlatformBehavior.update(
            SM64WfRotatingWoodenPlatformInput(action: 1, timer: 10, faceYaw: 100)
        )
        let stop = SM64WfRotatingWoodenPlatformBehavior.update(
            SM64WfRotatingWoodenPlatformInput(action: 1, timer: 127, faceYaw: 356)
        )
        precondition(waiting == SM64WfRotatingWoodenPlatformOutput(
            action: 0, faceYaw: 100, angleVelocityYaw: 0, playedSound: false
        ))
        precondition(start == SM64WfRotatingWoodenPlatformOutput(
            action: 1, faceYaw: 100, angleVelocityYaw: 0, playedSound: false
        ))
        precondition(spinning == SM64WfRotatingWoodenPlatformOutput(
            action: 1, faceYaw: 356, angleVelocityYaw: 256, playedSound: true
        ))
        precondition(stop == SM64WfRotatingWoodenPlatformOutput(
            action: 0, faceYaw: 612, angleVelocityYaw: 256, playedSound: true
        ))
        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(start, to: &fingerprint)
        append(spinning, to: &fingerprint)
        append(stop, to: &fingerprint)
        print(String(format: "wfRotatingWoodenPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern WF rotating wooden platform smoke passed")
    }
}
