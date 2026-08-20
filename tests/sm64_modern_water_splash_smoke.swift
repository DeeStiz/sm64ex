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

private func hashOutput(_ seed: UInt64, _ output: SM64WaterSplashOutput) -> UInt64 {
    var result = hash(seed, UInt64(output.kind.rawValue))
    result = hash(result, UInt64(output.position.x.bitPattern))
    result = hash(result, UInt64(output.position.y.bitPattern))
    result = hash(result, UInt64(output.position.z.bitPattern))
    result = hash(result, UInt64(output.scale.x.bitPattern))
    result = hash(result, UInt64(output.scale.y.bitPattern))
    result = hash(result, UInt64(output.scale.z.bitPattern))
    result = hash(result, UInt64(bitPattern: Int64(output.animationState)))
    return hash(result, output.shouldDelete ? 1 : 0)
}

@main
struct SM64WaterSplashSmoke {
    static func main() {
        let bubble = SM64WaterSplashBehavior.update(
            SM64WaterSplashInput(
                kind: .bubble,
                position: SM64ObjectVector3(x: 10, y: 3, z: -3),
                waterLevel: 120,
                randomScale: 0,
                timer: 0,
                animationState: -1
            )
        )
        precondition(
            bubble.position == SM64ObjectVector3(x: 10, y: 125, z: -3)
                && bubble.scale == SM64ObjectVector3(x: 0.5, y: 1, z: 0.5)
                && bubble.animationState == 0
                && !bubble.shouldDelete
        )

        let droplet = SM64WaterSplashBehavior.update(
            SM64WaterSplashInput(
                kind: .waterDroplet,
                position: SM64ObjectVector3(x: -4, y: 0, z: 8),
                waterLevel: 0,
                randomScale: 0.25,
                timer: 0,
                animationState: -1
            )
        )
        precondition(
            droplet.position == SM64ObjectVector3(x: -4, y: 5, z: 8)
                && droplet.scale == SM64ObjectVector3(x: 1.75, y: 1.75, z: 1.75)
                && droplet.animationState == 0
                && !droplet.shouldDelete
        )

        let object = SM64WaterSplashBehavior.update(
            SM64WaterSplashInput(
                kind: .object,
                position: SM64ObjectVector3(x: 3, y: 4, z: 5),
                waterLevel: 0,
                randomScale: 0,
                timer: 0,
                animationState: -1
            )
        )
        precondition(
            object.position == SM64ObjectVector3(x: 3, y: 4, z: 5)
                && object.scale == .one
                && object.animationState == 0
                && !object.shouldDelete
        )

        var fingerprint = hashOutput(fnvOffset, bubble)
        fingerprint = hashOutput(fingerprint, droplet)
        fingerprint = hashOutput(fingerprint, object)
        print(String(format: "waterSplashFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern water splash smoke passed")
    }
}
