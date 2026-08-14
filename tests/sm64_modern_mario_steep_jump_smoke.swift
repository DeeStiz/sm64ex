import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}
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
private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }
private func hashResult(_ initial: UInt64, _ result: SM64MarioSteepJumpResult) -> UInt64 {
    var hash = hashU32(initial, result.action)
    hash = hashU16(hash, UInt16(bitPattern: result.steepJumpYaw))
    hash = hashFloat(hash, result.forwardVelocity)
    hash = hashU16(hash, UInt16(bitPattern: result.faceYaw))
    return hashU8(hash, result.shouldDropHeldObject ? 1 : 0)
}

private func input(faceYaw: Int16 = 0, floorAngle: Int16 = Int16(bitPattern: 0x8000), forward: Float = 12) -> SM64MarioSteepJumpInput {
    SM64MarioSteepJumpInput(faceYaw: faceYaw, floorAngle: floorAngle, forwardVelocity: forward)
}

@main
enum SM64ModernMarioSteepJumpSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let projected = SM64MarioSteepJump.update(input())!
        precondition(projected.action == SM64MarioActionID.steepJump)
        precondition(projected.steepJumpYaw == 0 && projected.faceYaw == 0,
                     "steep=\(projected.steepJumpYaw) face=\(projected.faceYaw) fwd=\(projected.forwardVelocity)")
        precondition(abs(projected.forwardVelocity - 9) < 0.0001)
        precondition(projected.shouldDropHeldObject)
        fingerprint = hashResult(fingerprint, projected)

        let stopped = SM64MarioSteepJump.update(input(forward: 0))!
        precondition(stopped.forwardVelocity == 0 && stopped.faceYaw == 0)
        fingerprint = hashResult(fingerprint, stopped)

        precondition(SM64MarioSteepJump.update(input(forward: .infinity)) == nil)
        print(String(format: "marioSteepJumpFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario steep-jump smoke passed")
    }
}
