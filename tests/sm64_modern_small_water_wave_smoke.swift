import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashOutput(_ initial: UInt64, _ output: SM64SmallWaterWaveOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(output.position.y.bitPattern))
    hash = hashU64(hash, UInt64(output.scaleX.bitPattern))
    hash = hashU64(hash, UInt64(output.scaleZ.bitPattern))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.angleX)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.angleZ)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.timer)))
    hash = hashU64(hash, output.shouldDeactivate ? 1 : 0)
    hash = hashU64(hash, output.shouldDelete ? 1 : 0)
    return hashU64(hash, output.spawnSplash ? 1 : 0)
}

@main
struct SM64SmallWaterWaveSmoke {
    static func main() {
        let outputs = [
            SM64SmallWaterWaveBehavior.update(
                SM64SmallWaterWaveInput(
                    position: .zero, waterLevel: 100,
                    angleX: 0, angleZ: 0,
                    angleVelocityX: 0x400, angleVelocityZ: 0x400,
                    timer: 0, interacted: false
                )
            ),
            SM64SmallWaterWaveBehavior.update(
                SM64SmallWaterWaveInput(
                    position: .init(x: 0, y: 100, z: 0), waterLevel: 50,
                    angleX: 0, angleZ: 0,
                    angleVelocityX: 0x400, angleVelocityZ: 0x400,
                    timer: 1, interacted: false
                )
            ),
            SM64SmallWaterWaveBehavior.update(
                SM64SmallWaterWaveInput(
                    position: .zero, waterLevel: 100,
                    angleX: 0x4000, angleZ: 0,
                    angleVelocityX: 0x400, angleVelocityZ: 0x400,
                    timer: 59, interacted: true
                )
            ),
        ]
        precondition(outputs[0].position.y == 7 && outputs[0].scaleX == 1
            && outputs[0].scaleZ == 1 && outputs[0].timer == 1
            && !outputs[0].shouldDeactivate)
        precondition(outputs[1].position.y == 112 && outputs[1].shouldDeactivate
            && outputs[1].spawnSplash)
        precondition(outputs[2].scaleX == 1.2 && outputs[2].scaleZ == 1
            && outputs[2].shouldDeactivate && outputs[2].shouldDelete
            && !outputs[2].spawnSplash)
        var fingerprint = fnvOffset
        for output in outputs { fingerprint = hashOutput(fingerprint, output) }
        print(String(format: "smallWaterWaveFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern small water wave smoke passed")
    }
}
