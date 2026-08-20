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
struct SM64PiranhaPlantBubbleSmoke {
    static func main() {
        let input = SM64PiranhaPlantBubbleInput(
            parentPosition: SM64ObjectVector3(x: 10, y: 20, z: -4),
            parentYaw: 0x4000,
            parentSleeping: true,
            parentFrame: 0,
            lastAnimationFrame: 30,
            activeWithinRadius: true,
            action: .growShrink
        )
        let output = SM64PiranhaPlantBubbleBehavior.update(input)
        precondition(
            output.position == SM64ObjectVector3(x: 190, y: 92, z: -4)
                && output.action == .growShrink
                && output.scale == 5
                && !output.hidden
                && output.spawnWakingBubbleCount == 0
        )
        let idle = SM64PiranhaPlantBubbleBehavior.update(
            SM64PiranhaPlantBubbleInput(
                parentPosition: input.parentPosition,
                parentYaw: input.parentYaw,
                parentSleeping: true,
                parentFrame: 0,
                lastAnimationFrame: 30,
                activeWithinRadius: true,
                action: .idle
            )
        )
        precondition(idle.action == .growShrink && idle.hidden)
        let burst = SM64PiranhaPlantBubbleBehavior.update(
            SM64PiranhaPlantBubbleInput(
                parentPosition: input.parentPosition,
                parentYaw: input.parentYaw,
                parentSleeping: true,
                parentFrame: 0,
                lastAnimationFrame: 30,
                activeWithinRadius: true,
                action: .burst
            )
        )
        precondition(burst.action == .idle && burst.spawnWakingBubbleCount == 15 && burst.hidden)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.action.rawValue))
        fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern))
        fingerprint = hash(fingerprint, output.hidden ? 1 : 0)
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.spawnWakingBubbleCount)))
        print(String(format: "piranhaPlantBubbleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Piranha Plant bubble smoke passed")
    }
}
