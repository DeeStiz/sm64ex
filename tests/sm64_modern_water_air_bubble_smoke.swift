import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 { hash ^= (value >> UInt64(byte * 8)) & 0xff; hash &*= fnvPrime }
    return hash
}
private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}
private func hashOutput(_ initial: UInt64, _ output: SM64WaterAirBubbleOutput) -> UInt64 {
    var hash = hashF32(initial, output.position.x)
    hash = hashF32(hash, output.position.y)
    hash = hashF32(hash, output.position.z)
    hash = hashF32(hash, output.scaleX)
    hash = hashF32(hash, output.scaleY)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.angleF4)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.timer)))
    hash = hashF32(hash, output.forwardVelocity)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.moveYaw)))
    hash = hashU64(hash, output.intangible ? 1 : 0)
    hash = hashU64(hash, output.shouldDelete ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.spawnBubbleCount)))
    return hashU64(hash, output.playSound ? 1 : 0)
}

@main
struct SM64WaterAirBubbleSmoke {
    static func main() {
        let outputs = [
            SM64WaterAirBubbleBehavior.update(
                SM64WaterAirBubbleInput(
                    position: .zero, angleF4: 0, timer: 0, velocityY: 0,
                    forwardVelocity: 0, moveYaw: 0, marioPosition: .zero,
                    randomJitterX: 0, randomJitterZ: 0, waterLevel: 100, interacted: false
                )
            ),
            SM64WaterAirBubbleBehavior.update(
                SM64WaterAirBubbleInput(
                    position: .init(x: 0, y: 95, z: 0), angleF4: 0, timer: 30,
                    velocityY: 0, forwardVelocity: 0, moveYaw: 0,
                    marioPosition: .init(x: 10, y: 0, z: 0),
                    randomJitterX: 0, randomJitterZ: 0, waterLevel: 100, interacted: false
                )
            ),
            SM64WaterAirBubbleBehavior.update(
                SM64WaterAirBubbleInput(
                    position: .zero, angleF4: 0x8000, timer: 201, velocityY: 0,
                    forwardVelocity: 0, moveYaw: 0, marioPosition: .zero,
                    randomJitterX: 0, randomJitterZ: 0, waterLevel: 100, interacted: true
                )
            ),
        ]
        precondition(outputs[0].position.y == 3 && outputs[0].scaleX == 4
            && outputs[0].scaleY == 4 && outputs[0].intangible && !outputs[0].shouldDelete)
        precondition(outputs[1].position.x == 10 && outputs[1].forwardVelocity == 10
            && !outputs[1].intangible && !outputs[1].shouldDelete)
        precondition(outputs[2].scaleX == 4 && outputs[2].scaleY == 4
            && outputs[2].shouldDelete && outputs[2].spawnBubbleCount == 30
            && outputs[2].playSound)
        var fingerprint = fnvOffset
        for output in outputs { fingerprint = hashOutput(fingerprint, output) }
        print(String(format: "waterAirBubbleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern water-air bubble smoke passed")
    }
}
