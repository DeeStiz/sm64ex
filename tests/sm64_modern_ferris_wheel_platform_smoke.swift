import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 { var h=initial; for b in 0..<4 { h ^= UInt64((value >> UInt32(b*8)) & 0xff); h &*= fnvPrime }; return h }
private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }
private func append(_ o: SM64FerrisWheelPlatformOutput, to h: inout UInt64) { h=hashF32(h,o.position.x);h=hashF32(h,o.position.y);h=hashF32(h,o.position.z);h=hashF32(h,o.velocity.x);h=hashF32(h,o.velocity.y);h=hashF32(h,o.velocity.z) }

@main
enum SM64ModernFerrisWheelPlatformSmoke {
    static func main() {
        let front = SM64FerrisWheelPlatformBehavior.update(SM64FerrisWheelPlatformInput(
            parentPosition: .init(x: 100, y: 200, z: 300), parentRoll: 0, parentMoveYaw: 0,
            platformIndex: 0, previousPosition: .init(x: 0, y: 0, z: 0)
        ))
        let side = SM64FerrisWheelPlatformBehavior.update(SM64FerrisWheelPlatformInput(
            parentPosition: .init(x: 100, y: 200, z: 300), parentRoll: 0, parentMoveYaw: 0,
            platformIndex: 1, previousPosition: .init(x: 0, y: 0, z: 0)
        ))
        let yawed = SM64FerrisWheelPlatformBehavior.update(SM64FerrisWheelPlatformInput(
            parentPosition: .init(x: 100, y: 200, z: 300), parentRoll: 0, parentMoveYaw: 0x4000,
            platformIndex: 0, previousPosition: .init(x: 0, y: 0, z: 0)
        ))
        precondition(front.position == .init(x: 400, y: 200, z: 700))
        precondition(side.position == .init(x: 400, y: 600, z: 300))
        precondition(yawed.position == .init(x: 500, y: 200, z: 600))
        precondition(front.velocity == front.position && side.velocity == side.position)
        var h=fnvOffset; append(front,to:&h); append(side,to:&h); append(yawed,to:&h)
        print(String(format:"ferrisWheelPlatformFingerprint=0x%016llx",h)); print("SM64 Modern Ferris wheel platform smoke passed")
    }
}
