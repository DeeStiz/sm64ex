import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}
private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }
private func append(_ output: SM64LllSinkingRockBlockOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.oscillationAngle))
    fingerprint = hashF32(fingerprint, output.verticalOffset)
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashU32(fingerprint, output.reachedEndpoint ? 1 : 0)
}

@main
enum SM64ModernLllSinkingRockBlockSmoke {
    static func main() {
        let idle = SM64LllSinkingRockBlockBehavior.update(SM64LllSinkingRockBlockInput(
            oscillationAngle: 0, positionY: 100, homeY: 100, marioOnPlatform: false
        ))
        let sinking = SM64LllSinkingRockBlockBehavior.update(SM64LllSinkingRockBlockInput(
            oscillationAngle: 0x3F84, positionY: 100, homeY: 100, marioOnPlatform: true
        ))
        let top = SM64LllSinkingRockBlockBehavior.update(SM64LllSinkingRockBlockInput(
            oscillationAngle: 0x4000, positionY: 100, homeY: 100, marioOnPlatform: true
        ))
        let rising = SM64LllSinkingRockBlockBehavior.update(SM64LllSinkingRockBlockInput(
            oscillationAngle: 124, positionY: 100, homeY: 100, marioOnPlatform: false
        ))
        precondition(idle == SM64LllSinkingRockBlockOutput(oscillationAngle: 0, verticalOffset: 0, positionY: 100, reachedEndpoint: true))
        precondition(sinking.oscillationAngle == 0x4000 && sinking.verticalOffset == -110 && sinking.positionY == -10)
        precondition(top.oscillationAngle == 0x4000 && top.reachedEndpoint)
        precondition(rising == idle)
        var fingerprint = fnvOffset
        append(idle, to: &fingerprint); append(sinking, to: &fingerprint); append(top, to: &fingerprint); append(rising, to: &fingerprint)
        print(String(format: "lllSinkingRockBlockFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern LLL sinking rock block smoke passed")
    }
}
