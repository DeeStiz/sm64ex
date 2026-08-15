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

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func append(_ output: SM64ArrowLiftOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.moveYaw)))
    fingerprint = hashF32(fingerprint, output.velocityY)
    fingerprint = hashF32(fingerprint, output.forwardVelocity)
    fingerprint = hashF32(fingerprint, output.displacement)
    fingerprint = hashF32(fingerprint, output.deltaX)
    fingerprint = hashF32(fingerprint, output.deltaZ)
}

@main
enum SM64ModernArrowLiftSmoke {
    static func main() {
        let waiting = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(action: 0, timer: 60, faceYaw: 0, displacement: 0, marioIsOnPlatform: true)
        )
        let starts = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(action: 0, timer: 61, faceYaw: 0, displacement: 0, marioIsOnPlatform: true)
        )
        let away = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(action: 1, timer: 0, faceYaw: 0, displacement: 100, marioIsOnPlatform: false)
        )
        let awayDone = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(action: 1, timer: 0, faceYaw: 0, displacement: 378, marioIsOnPlatform: false)
        )
        let backWaiting = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(action: 2, timer: 60, faceYaw: 0, displacement: 200, marioIsOnPlatform: false)
        )
        let backDone = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(action: 2, timer: 61, faceYaw: 0, displacement: 4, marioIsOnPlatform: false)
        )

        precondition(waiting.action == 0 && waiting.forwardVelocity == 0)
        precondition(starts.action == 1)
        precondition(away.action == 1 && away.displacement == 112 && away.deltaX == -12 && away.deltaZ == 0)
        precondition(awayDone.action == 2 && awayDone.displacement == 384 && awayDone.forwardVelocity == 0)
        precondition(backWaiting.action == 2 && backWaiting.displacement == 200)
        precondition(backDone.action == 0 && backDone.displacement == 0 && backDone.forwardVelocity == 0)

        var fingerprint = fnvOffset
        append(waiting, to: &fingerprint)
        append(starts, to: &fingerprint)
        append(away, to: &fingerprint)
        append(awayDone, to: &fingerprint)
        append(backWaiting, to: &fingerprint)
        append(backDone, to: &fingerprint)
        print(String(format: "arrowLiftFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern arrow lift smoke passed")
    }
}
