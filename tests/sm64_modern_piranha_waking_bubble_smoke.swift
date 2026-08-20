import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

@main
struct SM64PiranhaPlantWakingBubbleSmoke {
    static func main() {
        let output = SM64PiranhaPlantWakingBubbleBehavior.update(
            SM64PiranhaPlantWakingBubbleInput(
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                moveYaw: 0,
                forwardVelocity: 0,
                velocityY: 0,
                timer: 0,
                initialMoveYaw: 0x4000,
                initialForwardVelocity: 10,
                initialVelocityY: 8
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 10, y: 28, z: 6)
                && output.moveYaw == 0x4000
                && output.forwardVelocity == 10
                && output.velocityY == 8
                && output.timer == 1
                && !output.shouldDeactivate
        )
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.moveYaw)))
        fingerprint = hash(fingerprint, UInt64(output.forwardVelocity.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.velocityY.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
        fingerprint = hash(fingerprint, output.shouldDeactivate ? 1 : 0)
        print(String(format: "piranhaWakingBubbleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Piranha Plant waking bubble smoke passed")
    }
}
