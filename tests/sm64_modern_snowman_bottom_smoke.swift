import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

@main
struct SM64SnowmanBottomSmoke {
    static func main() {
        let start = SM64SnowmanBottomBehavior.update(.init(
            action: 0, timer: 4, position: .zero, forwardVelocity: 0,
            moveYaw: 0, facePitch: 0, scale: 0.4, pathComplete: false,
            nearBouncePoint: false, movementFlags: 0, dialogTriggered: true
        ))
        let path = SM64SnowmanBottomBehavior.update(.init(
            action: 1, timer: 8, position: .zero, forwardVelocity: 80,
            moveYaw: 0, facePitch: 0, scale: 0.4, pathComplete: true,
            nearBouncePoint: false, movementFlags: 0, dialogTriggered: false
        ))
        let bounce = SM64SnowmanBottomBehavior.update(.init(
            action: 2, timer: 12, position: .zero, forwardVelocity: 20,
            moveYaw: 0, facePitch: 0, scale: 0.5, pathComplete: false,
            nearBouncePoint: true, movementFlags: 0, dialogTriggered: false
        ))
        let timeout = SM64SnowmanBottomBehavior.update(.init(
            action: 2, timer: 200, position: .zero, forwardVelocity: 20,
            moveYaw: 0, facePitch: 0, scale: 0.5, pathComplete: false,
            nearBouncePoint: false, movementFlags: 0, dialogTriggered: false
        ))
        let intangible = SM64SnowmanBottomBehavior.update(.init(
            action: 3, timer: 9, position: .init(x: 4, y: 5, z: 6),
            forwardVelocity: 15, moveYaw: 0, facePitch: 0, scale: 0.7,
            pathComplete: false, nearBouncePoint: false, movementFlags: 0x09,
            dialogTriggered: false
        ))
        precondition(start.action == 1 && start.forwardVelocity == 10)
        precondition(path.action == 2 && path.forwardVelocity == 70)
        precondition(bounce.action == 3 && bounce.verticalVelocity == 80 && bounce.parentBounce)
        precondition(timeout.deactivated)
        precondition(intangible.action == 4 && !intangible.tangible && intangible.pushMario)

        var fingerprint = offset
        for output in [start, path, bounce, timeout, intangible] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.action)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.facePitch)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: output.verticalVelocity.bitPattern))
            fingerprint = hash(fingerprint, output.deactivated ? 1 : 0)
        }
        print(String(format: "snowmanBottomFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern snowman bottom smoke passed")
    }
}
