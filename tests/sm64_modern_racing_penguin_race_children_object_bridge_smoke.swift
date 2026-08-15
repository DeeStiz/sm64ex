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

private func hashID(_ initial: UInt64, _ id: SM64ObjectID) -> UInt64 {
    let hash = hashU32(initial, UInt32(id.slot))
    return hashU32(hash, id.generation)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernRacingPenguinRaceChildrenObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64RacingPenguinObjectBridge()
        let parent = try bridge.spawnPenguin(in: engineState)
        _ = bridge.tick(state: engineState)
        _ = bridge.tick(
            state: engineState,
            environments: [parent: SM64RacingPenguinEnvironment(
                marioPositionY: 100,
                canActivateInitialText: true
            )]
        )
        let accepted = bridge.tick(
            state: engineState,
            environments: [parent: SM64RacingPenguinEnvironment(initialDialogResponse: 1)]
        )
        guard let children = accepted.effects.first?.raceChildren else {
            preconditionFailure("race children were not created")
        }

        let childTick = bridge.tick(
            state: engineState,
            environments: [parent: SM64RacingPenguinEnvironment(
                finishLineDistanceToMario: 900,
                finishLineMarioDeltaZ: -1,
                shortcutDistanceToMario: 400
            )]
        )
        require(!childTick.effects.isEmpty, "owner scheduler still updates the parent")
        guard let state = bridge.state(for: parent),
              let finishLine = engineState.objects.record(for: children.finishLine),
              let shortcut = engineState.objects.record(for: children.shortcutCheck) else {
            preconditionFailure("race child state disappeared before cleanup")
        }
        require(state.marioWon, "finish child writes parent win state")
        require(state.marioCheated, "shortcut child writes parent cheat state")
        require(finishLine.parent == parent && shortcut.parent == parent, "child parent links remain generation-safe")

        var fingerprint = fnvOffset
        fingerprint = hashID(fingerprint, parent)
        fingerprint = hashID(fingerprint, children.finishLine)
        fingerprint = hashID(fingerprint, children.shortcutCheck)
        fingerprint = hashID(fingerprint, finishLine.parent)
        fingerprint = hashID(fingerprint, shortcut.parent)
        fingerprint = hashU32(fingerprint, state.marioWon ? 1 : 0)
        fingerprint = hashU32(fingerprint, state.marioCheated ? 1 : 0)

        require(engineState.objects.markForDeletion(parent), "parent deletion request")
        _ = bridge.tick(state: engineState)
        require(engineState.objects.record(for: children.finishLine) == nil, "finish child cleanup")
        require(engineState.objects.record(for: children.shortcutCheck) == nil, "shortcut child cleanup")

        print(String(format: "racingPenguinRaceChildrenObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin race-children object bridge smoke passed")
    }
}
