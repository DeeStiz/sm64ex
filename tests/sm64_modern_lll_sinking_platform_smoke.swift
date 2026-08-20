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
    _ output: SM64LLLSinkingPlatformOutput,
    to fingerprint: inout UInt64
) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.oscillationTimer))
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.facePitch))
}

@main
enum SM64ModernLLLSinkingPlatformSmoke {
    static func main() {
        let rectangularInit = SM64LLLSinkingPlatformBehavior.update(
            SM64LLLSinkingPlatformInput(
                rectangularMode: true, action: 0, oscillationTimer: 0,
                positionY: 100, facePitch: 0
            )
        )
        let rectangularMove = SM64LLLSinkingPlatformBehavior.update(
            SM64LLLSinkingPlatformInput(
                rectangularMode: true, action: 1, oscillationTimer: 0x4000,
                positionY: 100, facePitch: 0
            )
        )
        let squareMove = SM64LLLSinkingPlatformBehavior.update(
            SM64LLLSinkingPlatformInput(
                rectangularMode: false, action: 0, oscillationTimer: 0x4000,
                positionY: 100, facePitch: 100
            )
        )
        let held = SM64LLLSinkingPlatformBehavior.update(
            SM64LLLSinkingPlatformInput(
                rectangularMode: true, action: 2, oscillationTimer: 0x5000,
                positionY: 90, facePitch: 12
            )
        )
        precondition(rectangularInit == SM64LLLSinkingPlatformOutput(
            action: 1, oscillationTimer: 0, positionY: 100, facePitch: 0
        ))
        precondition(rectangularMove == SM64LLLSinkingPlatformOutput(
            action: 1, oscillationTimer: 0x4100, positionY: 99.6, facePitch: 0
        ))
        precondition(squareMove == SM64LLLSinkingPlatformOutput(
            action: 0, oscillationTimer: 0x4100, positionY: 100, facePitch: 512
        ))
        precondition(held == SM64LLLSinkingPlatformOutput(
            action: 2, oscillationTimer: 0x5000, positionY: 90, facePitch: 12
        ))
        var fingerprint = fnvOffset
        append(rectangularInit, to: &fingerprint)
        append(rectangularMove, to: &fingerprint)
        append(squareMove, to: &fingerprint)
        append(held, to: &fingerprint)
        print(String(format: "lllSinkingPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern LLL sinking platform smoke passed")
    }
}
