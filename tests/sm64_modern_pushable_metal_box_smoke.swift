import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt32) -> UInt64 {
    var result = seed
    for byte in 0..<4 { result ^= UInt64((value >> UInt32(byte * 8)) & 0xff); result &*= prime }
    return result
}
private func append(_ output: SM64PushableMetalBoxOutput, to fingerprint: inout UInt64) {
    fingerprint = hash(fingerprint, output.position.x.bitPattern)
    fingerprint = hash(fingerprint, output.position.y.bitPattern)
    fingerprint = hash(fingerprint, output.position.z.bitPattern)
    fingerprint = hash(fingerprint, output.velocityY.bitPattern)
    fingerprint = hash(fingerprint, output.forwardVelocity.bitPattern)
    fingerprint = hash(fingerprint, UInt32(bitPattern: output.moveYaw))
    fingerprint = hash(fingerprint, output.pushed ? 1 : 0)
}
@main
enum SM64ModernPushableMetalBoxSmoke {
    static func main() {
        let idle = SM64PushableMetalBoxBehavior.update(.init(
            position: .init(x: 0, y: 10, z: 0), moveYaw: 0,
            forwardVelocity: 3, velocityY: -2, gravity: -3,
            marioCollided: false, marioFlags: 0, boxToMarioYaw: 0,
            marioMoveYaw: 0, floorDeltaAhead: 0
        ))
        let push = SM64PushableMetalBoxBehavior.update(.init(
            position: .init(x: 0, y: 10, z: 0), moveYaw: 0, forwardVelocity: 0, velocityY: 0, gravity: 0,
            marioCollided: true, marioFlags: 0x8000_0000, boxToMarioYaw: 0x8000,
            marioMoveYaw: 0, floorDeltaAhead: 0
        ))
        let blocked = SM64PushableMetalBoxBehavior.update(.init(
            position: .init(x: 0, y: 10, z: 0), moveYaw: 0, forwardVelocity: 0, velocityY: 0, gravity: 0,
            marioCollided: true, marioFlags: 0x8000_0000, boxToMarioYaw: 0x8000,
            marioMoveYaw: 0, floorDeltaAhead: 10
        ))
        precondition(idle.position.y == 5 && idle.forwardVelocity == 0)
        precondition(push.forwardVelocity == 4 && push.position.z == 4 && push.pushed)
        precondition(blocked.forwardVelocity == 0 && !blocked.pushed)
        var fingerprint = offset
        append(idle, to: &fingerprint); append(push, to: &fingerprint); append(blocked, to: &fingerprint)
        fingerprint = hash(fingerprint, Float(220).bitPattern)
        fingerprint = hash(fingerprint, Float(300).bitPattern)
        print(String(format: "pushableMetalBoxFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern pushable metal box smoke passed")
    }
}
