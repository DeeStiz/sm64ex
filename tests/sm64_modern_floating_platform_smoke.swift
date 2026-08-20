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

private func hashOutput(_ initial: UInt64, _ output: SM64FloatingPlatformOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(output.action)))
    hash = hashU64(hash, output.usingFloor ? 1 : 0)
    hash = hashU64(hash, UInt64(output.homeY.bitPattern))
    hash = hashU64(hash, UInt64(output.positionY.bitPattern))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.facePitch)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.faceRoll)))
    hash = hashU64(hash, UInt64(output.floatY.bitPattern))
    hash = hashU64(hash, UInt64(output.velocityY.bitPattern))
    return hashU64(hash, UInt64(bitPattern: Int64(output.oscillationTimer)))
}

@main
struct SM64FloatingPlatformSmoke {
    static func main() {
        let cases = [
            SM64FloatingPlatformInput(
                marioOnPlatform: false,
                objectPosition: .init(x: 0, y: 100, z: 0),
                marioPosition: .init(x: 100, y: 0, z: 100),
                moveYaw: 0,
                floorHeight: 0,
                waterLevel: 200,
                platformOffset: 64,
                floatY: 0,
                velocityY: 0,
                oscillationTimer: 0,
                facePitch: 0,
                faceRoll: 0
            ),
            SM64FloatingPlatformInput(
                marioOnPlatform: true,
                objectPosition: .zero,
                marioPosition: .init(x: 10, y: 0, z: 20),
                moveYaw: 0,
                floorHeight: 0,
                waterLevel: 200,
                platformOffset: 64,
                floatY: 10,
                velocityY: 5,
                oscillationTimer: 0,
                facePitch: 4,
                faceRoll: -6
            ),
            SM64FloatingPlatformInput(
                marioOnPlatform: true,
                objectPosition: .zero,
                marioPosition: .zero,
                moveYaw: 0,
                floorHeight: 100,
                waterLevel: 0,
                platformOffset: 64,
                floatY: 40,
                velocityY: 8,
                oscillationTimer: 12,
                facePitch: 10,
                faceRoll: -10
            ),
        ]
        let outputs = cases.map(SM64FloatingPlatformBehavior.update)
        precondition(outputs[0].action == 0 && !outputs[0].usingFloor
            && outputs[0].homeY == 264 && outputs[0].positionY == 200
            && outputs[0].velocityY == 10 && outputs[0].oscillationTimer == 1)
        precondition(outputs[1].action == 0 && outputs[1].facePitch == 40
            && outputs[1].faceRoll == -20 && outputs[1].velocityY == 4
            && outputs[1].floatY == 14 && outputs[1].positionY == 186
            && outputs[1].oscillationTimer == 1)
        precondition(outputs[2].action == 1 && outputs[2].usingFloor
            && outputs[2].homeY == 164 && outputs[2].positionY == 164)

        var fingerprint = fnvOffset
        for output in outputs { fingerprint = hashOutput(fingerprint, output) }
        print(String(format: "floatingPlatformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern floating platform smoke passed")
    }
}
