import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64FlamethrowerFlameSmoke {
    static func main() {
        let output = SM64FlamethrowerFlameBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), velocityY: 0, moveYaw: 0, forwardVelocity: 20, gravity: 0, timer: 0, animationState: 0, behaviorParam: 2, parentLifetime: 30, floorHeight: 0, initialOffset: .init(x: 1, y: 2, z: 3), initialAnimationState: 3))
        precondition(output.position == .init(x: 11, y: 22, z: 19) && output.scale == 2 && output.animationState == 4 && output.interactionStatus == 0 && !output.shouldDelete)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern)); fingerprint = hash(fingerprint, UInt64(output.animationState)); fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        print(String(format: "flamethrowerFlameFingerprint=0x%016llx", fingerprint)); print("SM64 Modern flamethrower flame smoke passed")
    }
}
