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

private func hashOutput(_ initial: UInt64, _ output: SM64TuxiesMotherEyesOutput) -> UInt64 {
    var hash = hashU32(initial, UInt32(bitPattern: output.selectedCase))
    hash = hashU32(hash, UInt32(bitPattern: output.blinkingCase))
    return hashU32(hash, output.angryOverride ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernTuxiesMotherEyesSmoke {
    static func main() {
        let motherIdentity: UInt64 = 0x6268_765F_74786D
        let otherIdentity: UInt64 = 0x6268_765F_6F7468
        var fingerprint = fnvOffset

        let notRun = SM64TuxiesMotherEyes.update(
            SM64TuxiesMotherEyesInput(run: false, previousSelectedCase: 4)
        )
        require(notRun.selectedCase == 4, "geo callback preserves switch case when not running")
        fingerprint = hashOutput(fingerprint, notRun)

        let expected: [Int: Int32] = [
            0: 0, 42: 0, 43: 1, 44: 1, 45: 2, 46: 2, 47: 1, 49: 1
        ]
        for timer in [0, 42, 43, 44, 45, 46, 47, 49] {
            let output = SM64TuxiesMotherEyes.update(
                SM64TuxiesMotherEyesInput(globalTimer: UInt64(timer))
            )
            require(output.selectedCase == expected[timer], "50-frame blink cadence")
            require(!output.angryOverride, "stationary mother keeps blink case")
            fingerprint = hashOutput(fingerprint, output)
        }

        let angry = SM64TuxiesMotherEyes.update(
            SM64TuxiesMotherEyesInput(
                globalTimer: 45,
                objectBehaviorIdentity: motherIdentity,
                motherBehaviorIdentity: motherIdentity,
                forwardVelocity: 5.01
            )
        )
        require(angry.blinkingCase == SM64TuxiesMotherEyes.closedCase, "angry override retains blink source")
        require(angry.selectedCase == SM64TuxiesMotherEyes.angryCase && angry.angryOverride, "moving mother angry eyes")
        fingerprint = hashOutput(fingerprint, angry)

        let mismatched = SM64TuxiesMotherEyes.update(
            SM64TuxiesMotherEyesInput(
                globalTimer: 45,
                objectBehaviorIdentity: otherIdentity,
                motherBehaviorIdentity: motherIdentity,
                forwardVelocity: 50
            )
        )
        require(mismatched.selectedCase == SM64TuxiesMotherEyes.closedCase, "identity gates angry override")
        fingerprint = hashOutput(fingerprint, mismatched)

        let threshold = SM64TuxiesMotherEyes.update(
            SM64TuxiesMotherEyesInput(
                globalTimer: 0,
                objectBehaviorIdentity: motherIdentity,
                motherBehaviorIdentity: motherIdentity,
                forwardVelocity: 5
            )
        )
        require(threshold.selectedCase == SM64TuxiesMotherEyes.openCase, "strict forward-velocity threshold")
        fingerprint = hashOutput(fingerprint, threshold)

        print(String(format: "tuxiesMotherEyesFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Tuxie's mother eyes smoke passed")
    }
}
