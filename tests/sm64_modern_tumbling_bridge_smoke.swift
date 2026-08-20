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

private func hashParent(_ initial: UInt64, _ output: SM64TumblingBridgeParentOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(output.action)))
    hash = hashU64(hash, output.spawnChildren ? 1 : 0)
    return hashU64(hash, output.visible ? 1 : 0)
}

private func hashPlatform(_ initial: UInt64, _ output: SM64TumblingBridgePlatformOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(output.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.angleVelocityPitch)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.angleVelocityRoll)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.facePitch)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.faceRoll)))
    hash = hashU64(hash, UInt64(output.position.y.bitPattern))
    hash = hashU64(hash, UInt64(output.velocityY.bitPattern))
    hash = hashU64(hash, output.shouldDelete ? 1 : 0)
    return hashU64(hash, output.playSound ? 1 : 0)
}

@main
struct SM64TumblingBridgeSmoke {
    static func main() {
        let parentCases = [
            SM64TumblingBridgeParentInput(action: 0, distanceToMario: 900, variant: .wf),
            SM64TumblingBridgeParentInput(action: 1, distanceToMario: 900, variant: .wf),
            SM64TumblingBridgeParentInput(action: 2, distanceToMario: 1300, variant: .wf),
            SM64TumblingBridgeParentInput(action: 2, distanceToMario: 1000, variant: .bbh),
            SM64TumblingBridgeParentInput(action: 0, distanceToMario: 5000, variant: .lll),
        ]
        let platformCases = [
            SM64TumblingBridgePlatformInput(
                action: 0, timer: 0, marioOnPlatform: true,
                angleVelocityPitch: 0, angleVelocityRoll: 0,
                facePitch: 0, faceRoll: 0,
                position: .zero, velocityY: 0, floorHeight: 0,
                parentAction: 2, rollStep: 0x80
            ),
            SM64TumblingBridgePlatformInput(
                action: 1, timer: 6, marioOnPlatform: false,
                angleVelocityPitch: 0, angleVelocityRoll: 0,
                facePitch: 0, faceRoll: 0,
                position: .zero, velocityY: 0, floorHeight: 0,
                parentAction: 2, rollStep: 0x80
            ),
            SM64TumblingBridgePlatformInput(
                action: 2, timer: 0, marioOnPlatform: false,
                angleVelocityPitch: 0, angleVelocityRoll: 0,
                facePitch: 0, faceRoll: 0,
                position: .zero, velocityY: 0, floorHeight: 0,
                parentAction: 2, rollStep: 0x80
            ),
            SM64TumblingBridgePlatformInput(
                action: 0, timer: 0, marioOnPlatform: false,
                angleVelocityPitch: 0, angleVelocityRoll: 0,
                facePitch: 0, faceRoll: 0,
                position: .zero, velocityY: 0, floorHeight: 0,
                parentAction: 3, rollStep: -0x80
            ),
        ]
        let parents = parentCases.map(SM64TumblingBridgeBehavior.updateParent)
        let platforms = platformCases.map(SM64TumblingBridgeBehavior.updatePlatform)
        precondition(parents[0] == .init(action: 1, spawnChildren: false, visible: true))
        precondition(parents[1] == .init(action: 2, spawnChildren: true, visible: true))
        precondition(parents[2] == .init(action: 3, spawnChildren: false, visible: true))
        precondition(parents[3] == .init(action: 2, spawnChildren: false, visible: false))
        precondition(parents[4] == .init(action: 1, spawnChildren: false, visible: true))
        precondition(platforms[0].action == 1)
        precondition(platforms[1].action == 2 && platforms[1].playSound)
        precondition(platforms[2].angleVelocityPitch == 0x80
            && platforms[2].angleVelocityRoll == 0x80
            && platforms[2].position.y == -3
            && platforms[2].velocityY == -3)
        precondition(platforms[3].shouldDelete)

        var fingerprint = fnvOffset
        for output in parents { fingerprint = hashParent(fingerprint, output) }
        for output in platforms { fingerprint = hashPlatform(fingerprint, output) }
        print(String(format: "tumblingBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern tumbling bridge smoke passed")
    }
}
