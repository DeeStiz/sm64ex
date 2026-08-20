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

private func append(
    _ initialization: SM64TTCPitBlockInitialization,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(initialization.collisionModelIndex))
    fingerprint = hashF32(fingerprint, initialization.peakY)
    fingerprint = hashF32(fingerprint, initialization.initialPositionY)
}

private func append(
    _ output: SM64TTCPitBlockOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.direction))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.waitTime))
    fingerprint = hashF32(fingerprint, output.velocityY)
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashU32(fingerprint, output.clampedAtEndpoint ? 1 : 0)
}

@main
enum SM64ModernTTCPitBlockSmoke {
    static func main() {
        let slowInit = SM64TTCPitBlockBehavior.initialize(
            positionY: 100, behaviorByte: 0, speedSetting: 0
        )
        let stoppedInit = SM64TTCPitBlockBehavior.initialize(
            positionY: 100, behaviorByte: 1, speedSetting: 3
        )
        precondition(slowInit.peakY == 430 && slowInit.initialPositionY == 100)
        precondition(stoppedInit.peakY == 430 && stoppedInit.initialPositionY == 430)

        let waiting = SM64TTCPitBlockBehavior.update(SM64TTCPitBlockInput(
            speedSetting: 0, timer: 0, direction: 0, waitTime: 20,
            velocityY: 11, positionY: 100, homeY: 100, peakY: 430,
            randomWaitTime: 70
        ))
        let rising = SM64TTCPitBlockBehavior.update(SM64TTCPitBlockInput(
            speedSetting: 0, timer: 21, direction: 0, waitTime: 20,
            velocityY: 11, positionY: 100, homeY: 100, peakY: 430,
            randomWaitTime: 70
        ))
        let top = SM64TTCPitBlockBehavior.update(SM64TTCPitBlockInput(
            speedSetting: 0, timer: 21, direction: 0, waitTime: 20,
            velocityY: 11, positionY: 425, homeY: 100, peakY: 430,
            randomWaitTime: 70
        ))
        let randomTop = SM64TTCPitBlockBehavior.update(SM64TTCPitBlockInput(
            speedSetting: 2, timer: 21, direction: 0, waitTime: 20,
            velocityY: 11, positionY: 425, homeY: 100, peakY: 430,
            randomWaitTime: 70
        ))
        let bottom = SM64TTCPitBlockBehavior.update(SM64TTCPitBlockInput(
            speedSetting: 2, timer: 31, direction: 1, waitTime: 30,
            velocityY: -9, positionY: 105, homeY: 100, peakY: 430,
            randomWaitTime: 70
        ))
        let stopped = SM64TTCPitBlockBehavior.update(SM64TTCPitBlockInput(
            speedSetting: 3, timer: 1, direction: 1, waitTime: 0,
            velocityY: 0, positionY: 430, homeY: 100, peakY: 430,
            randomWaitTime: 70
        ))
        precondition(waiting == SM64TTCPitBlockOutput(
            timer: 0, direction: 0, waitTime: 20, velocityY: 11,
            positionY: 100, clampedAtEndpoint: false
        ))
        precondition(rising.positionY == 111 && !rising.clampedAtEndpoint)
        precondition(top == SM64TTCPitBlockOutput(
            timer: 0, direction: 1, waitTime: 30, velocityY: -9,
            positionY: 430, clampedAtEndpoint: true
        ))
        precondition(randomTop == SM64TTCPitBlockOutput(
            timer: 0, direction: 1, waitTime: 70, velocityY: -9,
            positionY: 430, clampedAtEndpoint: true
        ))
        precondition(bottom == SM64TTCPitBlockOutput(
            timer: 0, direction: 0, waitTime: 20, velocityY: 11,
            positionY: 100, clampedAtEndpoint: true
        ))
        precondition(stopped == SM64TTCPitBlockOutput(
            timer: 0, direction: 0, waitTime: 0, velocityY: 0,
            positionY: 430, clampedAtEndpoint: true
        ))

        var fingerprint = fnvOffset
        append(slowInit, to: &fingerprint)
        append(stoppedInit, to: &fingerprint)
        append(waiting, to: &fingerprint)
        append(rising, to: &fingerprint)
        append(top, to: &fingerprint)
        append(randomTop, to: &fingerprint)
        append(bottom, to: &fingerprint)
        append(stopped, to: &fingerprint)
        print(String(format: "ttcPitBlockFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC pit block smoke passed")
    }
}
