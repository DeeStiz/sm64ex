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
struct SM64AnimatedTextureSmoke {
    static func main() {
        let output = SM64AnimatedTextureBehavior.update(
            .init(
                position: .init(x: 1, y: 2, z: 3),
                homePosition: .init(x: 10, y: 20, z: 30),
                animationState: 5,
                globalFrame: 2
            )
        )
        precondition(
            output.position == .init(x: 10, y: 20, z: 30)
                && output.animationState == 7
        )

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.animationState))
        print(String(format: "animatedTextureFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern animated texture smoke passed")
    }
}
