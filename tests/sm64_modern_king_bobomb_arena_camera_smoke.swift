import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernKingBobombArenaCameraSmoke {
    static func main() throws {
        let engine = SM64SwiftEngineState(objectCapacity: 2)
        let bridge = SM64KingBobombObjectBridge()
        let id = try bridge.spawnKingBobomb(in: engine, homeY: 100, positionY: 100)
        let tick = bridge.tick(
            state: engine,
            environments: [id: SM64KingBobombEnvironment(input: SM64KingBobombInput(
                positionY: 100,
                dialogCanActivate: true
            ))],
            presentArenaCamera: true
        )

        guard let effect = tick.effects.first,
              let delivery = tick.deliveries.first else {
            preconditionFailure("King Bob-omb arena camera owner result is missing")
        }
        require(effect.output.effects.contains(.cameraFocus), "boss intro requests arena camera focus")
        require(effect.output.effects.contains(.bossMusic), "boss intro requests boss music")
        require(delivery.rejected.isEmpty, "arena camera intents are accepted by the owner router")
        require(delivery.presented.map(\.kind) == [.music, .cameraFocus],
                "music precedes arena camera focus in presentation order")
        guard let music = delivery.presented.first,
              let camera = delivery.presented.last else {
            preconditionFailure("arena camera presentation intents are missing")
        }
        require(music.value == 1 && music.auxiliary == 0, "boss music intent payload")
        require(camera.value == SM64KingBobombObjectBridge.bossCameraModeValue,
                "boss camera mode uses CAMERA_MODE_BOSS_FIGHT")
        require(camera.auxiliary == 0, "boss camera intent has no auxiliary payload")

        var fingerprint = fnvOffset
        fingerprint = hashU32(fingerprint, effect.output.effects.rawValue)
        fingerprint = hashU32(fingerprint, UInt32(delivery.presented.count))
        for intent in delivery.presented {
            fingerprint = hashU32(fingerprint, UInt32(intent.kind.rawValue))
            fingerprint = hashU32(fingerprint, UInt32(bitPattern: intent.value))
            fingerprint = hashU32(fingerprint, UInt32(bitPattern: intent.auxiliary))
        }
        fingerprint = hashU32(fingerprint, UInt32(bitPattern: effect.output.state.action))
        fingerprint = hashU32(fingerprint, UInt32(bitPattern: effect.output.state.subAction))
        print(String(format: "kingBobombArenaCameraFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern King Bob-omb arena camera smoke passed")
    }
}
