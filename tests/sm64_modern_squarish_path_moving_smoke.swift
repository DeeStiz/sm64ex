import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt32) -> UInt64 {
    var result = seed
    for byte in 0..<4 {
        result ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        result &*= prime
    }
    return result
}

private func append(_ output: SM64SquarishPathMovingOutput, to fingerprint: inout UInt64) {
    fingerprint = hash(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hash(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hash(fingerprint, output.position.x.bitPattern)
    fingerprint = hash(fingerprint, output.position.y.bitPattern)
    fingerprint = hash(fingerprint, output.position.z.bitPattern)
    fingerprint = hash(fingerprint, UInt32(bitPattern: output.moveYaw))
    fingerprint = hash(fingerprint, output.forwardVelocity.bitPattern)
    fingerprint = hash(fingerprint, output.velocityY.bitPattern)
}

@main
enum SM64ModernSquarishPathMovingSmoke {
    static func main() {
        let initial = SM64SquarishPathMovingBehavior.update(.init(
            action: 0, timer: 0, behaviorByte: 2,
            position: .init(x: 0, y: 100, z: 0), moveYaw: 0,
            velocityY: 0, gravity: 0
        ))
        let turn = SM64SquarishPathMovingBehavior.update(.init(
            action: 1, timer: 60, behaviorByte: 0,
            position: .init(x: 0, y: 100, z: 0), moveYaw: 0,
            velocityY: 0, gravity: 0
        ))
        let hold = SM64SquarishPathMovingBehavior.update(.init(
            action: 2, timer: 12, behaviorByte: 0,
            position: .init(x: 0, y: 100, z: 0), moveYaw: 0x4000,
            velocityY: 1, gravity: -1
        ))
        let wrap = SM64SquarishPathMovingBehavior.update(.init(
            action: 4, timer: 61, behaviorByte: 0,
            position: .init(x: 0, y: 100, z: 0), moveYaw: 0,
            velocityY: 0, gravity: 0
        ))
        precondition(initial.action == 3 && initial.moveYaw == 0 && initial.position.z == 10)
        precondition(turn.action == 1 && turn.timer == 61)
        precondition(hold.action == 2 && hold.position.x == 10)
        precondition(wrap.action == 1 && UInt32(bitPattern: wrap.moveYaw) == 0xC000)
        var fingerprint = offset
        append(initial, to: &fingerprint)
        append(turn, to: &fingerprint)
        append(hold, to: &fingerprint)
        append(wrap, to: &fingerprint)
        print(String(format: "squarishPathMovingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern squarish path moving smoke passed")
    }
}
