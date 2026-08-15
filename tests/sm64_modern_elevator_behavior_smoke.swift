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

private func append(_ output: SM64ElevatorOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, output.positionY.bitPattern)
    fingerprint = hashU32(fingerprint, output.velocityY.bitPattern)
    fingerprint = hashU32(fingerprint, UInt32(output.sound?.rawValue ?? 0))
    fingerprint = hashU32(fingerprint, output.shakeSmall ? 1 : 0)
}

@main
enum SM64ModernElevatorBehaviorSmoke {
    static func main() {
        let rising = SM64ElevatorBehavior.update(
            SM64ElevatorInput(
                action: 1, timer: 0, positionY: 18, velocityY: 8,
                bottomY: 0, topY: 20, midpointY: 10, platformKind: 0,
                marioPositionY: 4, marioOnPlatform: true, marioInAirAction: false
            )
        )
        let descending = SM64ElevatorBehavior.update(
            SM64ElevatorInput(
                action: 2, timer: 3, positionY: 4, velocityY: -8,
                bottomY: 0, topY: 20, midpointY: 10, platformKind: 0,
                marioPositionY: 18, marioOnPlatform: true, marioInAirAction: false
            )
        )
        let resting = SM64ElevatorBehavior.update(
            SM64ElevatorInput(
                action: 3, timer: 0, positionY: 20, velocityY: 4,
                bottomY: 0, topY: 20, midpointY: 10, platformKind: 0,
                marioPositionY: 20, marioOnPlatform: false, marioInAirAction: false
            )
        )
        precondition(rising.action == 2 && rising.positionY == 20 && rising.velocityY == 10)
        precondition(rising.sound == .quietPound && rising.shakeSmall)
        precondition(descending.action == 1 && descending.positionY == 0 && descending.velocityY == -10)
        precondition(resting.action == 0 && resting.sound == .metalPound && resting.shakeSmall)

        var fingerprint = fnvOffset
        append(rising, to: &fingerprint)
        append(descending, to: &fingerprint)
        append(resting, to: &fingerprint)
        print(String(format: "elevatorBehaviorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern elevator behavior smoke passed")
    }
}
