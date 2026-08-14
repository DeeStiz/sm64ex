import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashResult(_ initial: UInt64, _ result: SM64MarioGroundSpeedResult) -> UInt64 {
    let hash = hashU32(initial, result.forwardVelocity.bitPattern)
    return hashU16(hash, UInt16(bitPattern: result.faceYaw))
}

@main
enum SM64ModernMarioGroundSpeedSmoke {
    static func main() {
        let inputs = [
            SM64MarioGroundSpeedInput(
                intendedMagnitude: 32, forwardVelocity: 0, quicksandDepth: 0,
                floorNormalY: 1, intendedYaw: 0x3000, faceYaw: 0,
                floorIsSlow: false, responsiveCheat: false, cheatsEnabled: false
            ),
            SM64MarioGroundSpeedInput(
                intendedMagnitude: 4, forwardVelocity: 10, quicksandDepth: 0,
                floorNormalY: 0.9, intendedYaw: -0x3000, faceYaw: 0x3000,
                floorIsSlow: true, responsiveCheat: false, cheatsEnabled: false
            ),
            SM64MarioGroundSpeedInput(
                intendedMagnitude: 32, forwardVelocity: 2, quicksandDepth: 20,
                floorNormalY: 0.8, intendedYaw: 0x7000, faceYaw: -0x7000,
                floorIsSlow: false, responsiveCheat: false, cheatsEnabled: false
            ),
            SM64MarioGroundSpeedInput(
                intendedMagnitude: 8, forwardVelocity: 50, quicksandDepth: 0,
                floorNormalY: 1, intendedYaw: -0x7FFF, faceYaw: 0x7FFF,
                floorIsSlow: false, responsiveCheat: true, cheatsEnabled: true
            )
        ]
        var fingerprint = fnvOffset
        for input in inputs {
            guard let result = SM64MarioGroundSpeed.update(input) else {
                preconditionFailure("finite ground-speed input rejected")
            }
            fingerprint = hashResult(fingerprint, result)
        }
        precondition(SM64MarioGroundSpeed.update(
            SM64MarioGroundSpeedInput(
                intendedMagnitude: .infinity, forwardVelocity: 0, quicksandDepth: 0,
                floorNormalY: 1, intendedYaw: 0, faceYaw: 0,
                floorIsSlow: false, responsiveCheat: false, cheatsEnabled: false
            )
        ) == nil)
        print(String(format: "marioGroundSpeedFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario ground-speed smoke passed")
    }
}
