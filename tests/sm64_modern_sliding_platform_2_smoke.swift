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

private func hashOutput(_ initial: UInt64, _ output: SM64SlidingPlatform2Output) -> UInt64 {
    var hash = hashU64(initial, UInt64(output.position.x.bitPattern))
    hash = hashU64(hash, UInt64(output.position.y.bitPattern))
    hash = hashU64(hash, UInt64(output.position.z.bitPattern))
    hash = hashU64(hash, UInt64(output.offset.bitPattern))
    hash = hashU64(hash, UInt64(output.speed.bitPattern))
    return hashU64(hash, UInt64(bitPattern: Int64(output.timer)))
}

@main
struct SM64SlidingPlatform2Smoke {
    static func main() {
        let horizontal = SM64SlidingPlatform2Behavior.initialize(
            behaviorParams: 0x0010_0000,
            moveYaw: 0
        )
        let reversedHorizontal = SM64SlidingPlatform2Behavior.initialize(
            behaviorParams: 0x00CF_0000,
            moveYaw: 0
        )
        let vertical = SM64SlidingPlatform2Behavior.initialize(
            behaviorParams: 0x02C5_0000,
            moveYaw: 0
        )
        precondition(horizontal.distance == 800 && horizontal.speed == 15
            && horizontal.moveYaw == 0 && horizontal.verticalSign == 0)
        precondition(reversedHorizontal.distance == 750 && reversedHorizontal.moveYaw == 0x8000)
        precondition(vertical.distance == 250 && vertical.speed == 10
            && vertical.verticalSign == -1)

        let outputs = [
            SM64SlidingPlatform2Behavior.update(
                SM64SlidingPlatform2Input(
                    timer: 0, homePosition: .init(x: 10, y: 20, z: 30),
                    moveYaw: 0, offset: 0, speed: 15, distance: 800, verticalSign: 0
                )
            ),
            SM64SlidingPlatform2Behavior.update(
                SM64SlidingPlatform2Input(
                    timer: 11, homePosition: .init(x: 10, y: 20, z: 30),
                    moveYaw: 0, offset: 0, speed: 15, distance: 10, verticalSign: 0
                )
            ),
            SM64SlidingPlatform2Behavior.update(
                SM64SlidingPlatform2Input(
                    timer: 0, homePosition: .init(x: 10, y: 20, z: 30),
                    moveYaw: 0, offset: -50, speed: 10, distance: 250, verticalSign: -1
                )
            ),
        ]
        precondition(outputs[0].position == .init(x: 10, y: 20, z: 30)
            && outputs[0].timer == 1)
        precondition(outputs[1].offset == 0 && outputs[1].speed == -15 && outputs[1].timer == 1)
        precondition(outputs[2].position.y == 70 && outputs[2].timer == 1)
        var fingerprint = fnvOffset
        for output in outputs { fingerprint = hashOutput(fingerprint, output) }
        print(String(format: "slidingPlatform2Fingerprint=0x%016llx", fingerprint))
        print("SM64 Modern sliding platform 2 smoke passed")
    }
}
