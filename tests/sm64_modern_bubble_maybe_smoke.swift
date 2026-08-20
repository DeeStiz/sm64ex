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
struct SM64BubbleMaybeSmoke {
    static func main() {
        let output = SM64BubbleMaybeBehavior.update(
            SM64BubbleMaybeInput(
                position: SM64ObjectVector3(x: 10, y: 20, z: -4),
                randomOffsetX: 2,
                randomOffsetY: 3,
                randomOffsetZ: -1,
                randomStepX: 0.5,
                randomStepY: 6.25,
                randomStepZ: -0.5,
                angleF4: 0x400,
                angleF8: 0x800,
                expansionRateX: 0x100,
                expansionRateY: 0x200,
                timer: 0,
                animationState: -1
            )
        )
        precondition(
            output.position == SM64ObjectVector3(x: 12.5, y: 29.25, z: -5.5)
                && output.angleF4 == 0x500
                && output.angleF8 == 0xA00
                && output.animationState == 0
                && !output.shouldDelete
        )
        var fingerprint = fnvOffset
        for value in [
            UInt64(output.position.x.bitPattern),
            UInt64(output.position.y.bitPattern),
            UInt64(output.position.z.bitPattern),
            UInt64(output.scaleX.bitPattern),
            UInt64(output.scaleY.bitPattern),
            UInt64(bitPattern: Int64(output.angleF4)),
            UInt64(bitPattern: Int64(output.angleF8)),
            UInt64(bitPattern: Int64(output.animationState)),
            output.shouldDelete ? 1 : 0
        ] {
            fingerprint = hash(fingerprint, value)
        }
        print(String(format: "bubbleMaybeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern bubble-maybe smoke passed")
    }
}
