import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64BowserFlameFamilySmoke {
    static func main() {
        let blue = SM64BlueBowserFlameBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, forwardVelocity: 35, velocityY: 7, gravity: 1, scale: 3, timer: 0, animationState: 0, behaviorParam: 0, phase: 0, globalTimer: 0, initialOffset: .init(x: 1, y: 2, z: 3), initialAnimationState: 3))
        precondition(blue.position == .init(x: 11, y: 30, z: 34) && blue.scale == 3.5 && blue.animationState == 4 && blue.spawnCount == 0 && !blue.shouldDelete)
        let landing = SM64FlameFloatingLandingBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), moveYaw: 0, forwardVelocity: 0, velocityY: 0, gravity: -1, timer: 0, animationState: 0, phase: 0, globalTimer: 0, behaviorParam: 0, scale: 5, landed: true, floorHazard: false))
        precondition(landing.spawnBurningOut && landing.shouldDelete && landing.graphYOffset == 70)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(blue.position.x.bitPattern)); fingerprint=hash(fingerprint,UInt64(blue.position.y.bitPattern)); fingerprint=hash(fingerprint,UInt64(blue.position.z.bitPattern)); fingerprint=hash(fingerprint,UInt64(blue.scale.bitPattern)); fingerprint=hash(fingerprint,UInt64(blue.animationState)); fingerprint=hash(fingerprint,blue.spawnCount == 0 ? 1:0); fingerprint=hash(fingerprint,landing.spawnBurningOut ? 1:0)
        print(String(format:"bowserFlameFamilyFingerprint=0x%016llx",fingerprint)); print("SM64 Modern Bowser flame family smoke passed")
    }
}
