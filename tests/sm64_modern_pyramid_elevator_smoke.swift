import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}
private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }

private func append(_ output: SM64PyramidElevatorOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashF32(fingerprint, output.velocityY)
    fingerprint = hashU32(fingerprint, output.markerShouldBeActive ? 1 : 0)
}

@main
enum SM64ModernPyramidElevatorSmoke {
    static func main() {
        let idle = SM64PyramidElevatorBehavior.update(
            SM64PyramidElevatorInput(action: 0, timer: 0, positionY: 4600, homeY: 4600,
                                     velocityY: 0, marioOnPlatform: true)
        )
        let start = SM64PyramidElevatorBehavior.update(
            SM64PyramidElevatorInput(action: 1, timer: 8, positionY: 4600, homeY: 4600,
                                     velocityY: 0, marioOnPlatform: false)
        )
        let constant = SM64PyramidElevatorBehavior.update(
            SM64PyramidElevatorInput(action: 2, timer: 0, positionY: 130, homeY: 4600,
                                     velocityY: 0, marioOnPlatform: false)
        )
        let bottom = SM64PyramidElevatorBehavior.update(
            SM64PyramidElevatorInput(action: 3, timer: 8, positionY: 128, homeY: 4600,
                                     velocityY: -10, marioOnPlatform: false)
        )
        precondition(idle.action == 1 && !idle.markerShouldBeActive)
        precondition(start.action == 2 && start.positionY == 4600)
        precondition(constant.action == 3 && constant.positionY == 128 && constant.velocityY == -10)
        precondition(bottom.action == 3 && bottom.positionY == 128 && bottom.velocityY == 0)
        var fingerprint = fnvOffset
        append(idle, to: &fingerprint); append(start, to: &fingerprint)
        append(constant, to: &fingerprint); append(bottom, to: &fingerprint)
        print(String(format: "pyramidElevatorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern pyramid elevator smoke passed")
    }
}
