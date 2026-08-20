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
struct SM64WindSmoke {
    static func main() {
        let output = SM64WindBehavior.update(
            SM64WindInput(
                position: SM64ObjectVector3(x: 100, y: 200, z: -50),
                moveYaw: 0x4000,
                movePitch: 0,
                forwardVelocity: 0,
                velocityY: 0,
                facePitch: 0,
                faceYaw: 0,
                timer: 0,
                initialRandomX: 10,
                initialRandomY: 15,
                initialRandomZ: -20,
                initialYawJitter: 0,
                initialForwardVelocity: 10,
                initialVelocityY: 50,
                initialRandomYaw: 0,
                facePitchJitter: 0,
                faceYawJitter: 0
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: -390, y: 295, z: -60)
                && output.moveYaw == 0x4000
                && output.forwardVelocity == 10
                && output.velocityY == 0
                && output.facePitch == 4000
                && output.faceYaw == 4000
                && output.opacity == 100
                && output.scale == 1
                && !output.shouldDelete
        )
        var fingerprint = fnvOffset
        for value in [
            UInt64(output.position.x.bitPattern),
            UInt64(output.position.y.bitPattern),
            UInt64(output.position.z.bitPattern),
            UInt64(bitPattern: Int64(output.moveYaw)),
            UInt64(output.forwardVelocity.bitPattern),
            UInt64(output.velocityY.bitPattern),
            UInt64(bitPattern: Int64(output.facePitch)),
            UInt64(bitPattern: Int64(output.faceYaw)),
            UInt64(bitPattern: Int64(output.opacity)),
            UInt64(output.scale.bitPattern),
            output.shouldDelete ? 1 : 0
        ] { fingerprint = hash(fingerprint, value) }
        print(String(format: "windFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern wind smoke passed")
    }
}
