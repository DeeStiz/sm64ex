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

private func hashI32(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU32(initial, UInt32(bitPattern: value))
}

private func hashI16(_ initial: UInt64, _ value: Int16) -> UInt64 {
    hashU32(initial, UInt32(UInt16(bitPattern: value)))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashOutput(_ initial: UInt64, _ output: SM64RacingPenguinOutput, record: SM64ObjectRecord) -> UInt64 {
    var hash = initial
    hash = hashI32(hash, output.action)
    hash = hashI32(hash, output.initTextCooldown)
    hash = hashFloat(hash, output.forwardVelocity)
    hash = hashFloat(hash, output.weightedTargetSpeed)
    hash = hashI16(hash, output.moveYaw)
    hash = hashI16(hash, output.angleVelocityYaw)
    hash = hashI32(hash, output.animation)
    hash = hashI32(hash, record.action)
    hash = hashI32(hash, record.previousAction)
    hash = hashI32(hash, record.timer)
    hash = hashFloat(hash, record.forwardVelocity)
    hash = hashI32(hash, record.moveAngles.yaw)
    hash = hashFloat(hash, record.velocity.y)
    hash = hashI32(hash, output.finalTextbox)
    hash = hashU32(hash, output.marioWon ? 1 : 0)
    hash = hashU32(hash, output.marioCheated ? 1 : 0)
    hash = hashU32(hash, output.reachedBottom ? 1 : 0)
    return hashU32(hash, output.resetTimer ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernRacingPenguinObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64RacingPenguinObjectBridge()
        let id = try bridge.spawnPenguin(
            in: engineState,
            position: SM64ObjectVector3(x: -100, y: 0, z: 25)
        )
        var fingerprint = fnvOffset

        // The native object timer advances once before the first activation
        // check; this warm-up mirrors the scheduler's first owner tick.
        _ = bridge.tick(state: engineState)
        let initialTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                marioPositionY: 100,
                canActivateInitialText: true
            )]
        )
        guard let initialEffect = initialTick.effects.first,
              let initialRecord = engineState.objects.record(for: id) else {
            preconditionFailure("initial racing penguin effect missing")
        }
        require(initialEffect.output.action == SM64RacingPenguinBehavior.showInitText, "bridge enters init text")
        require(initialRecord.action == SM64RacingPenguinBehavior.showInitText, "record action mirrors kernel")
        require(initialRecord.timer == 0, "action transition resets owner timer")
        fingerprint = hashOutput(fingerprint, initialEffect.output, record: initialRecord)

        let acceptedTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(initialDialogResponse: 1)]
        )
        guard let acceptedEffect = acceptedTick.effects.first,
              let acceptedRecord = engineState.objects.record(for: id) else {
            preconditionFailure("accepted racing penguin effect missing")
        }
        require(acceptedEffect.output.attachRaceObjects, "bridge exposes race child attachment intent")
        require(acceptedRecord.action == SM64RacingPenguinBehavior.prepareForRace, "prepare action synchronized")
        require(acceptedRecord.velocity.y == 60, "start velocity synchronized")
        fingerprint = hashOutput(fingerprint, acceptedEffect.output, record: acceptedRecord)

        let startedTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(raceBeginComplete: true)]
        )
        guard let startedEffect = startedTick.effects.first,
              let startedRecord = engineState.objects.record(for: id) else {
            preconditionFailure("started racing penguin effect missing")
        }
        require(startedRecord.action == SM64RacingPenguinBehavior.race, "race action synchronized")
        require(startedRecord.forwardVelocity == 20, "race start speed synchronized")
        fingerprint = hashOutput(fingerprint, startedEffect.output, record: startedRecord)

        let racingTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                marioPositionY: -200,
                pathWaypointFlags: 0x20,
                pathTargetYaw: 6_000,
                marioInAirAction: true
            )]
        )
        guard let racingEffect = racingTick.effects.first,
              let racingRecord = engineState.objects.record(for: id) else {
            preconditionFailure("racing penguin speed effect missing")
        }
        require(racingEffect.output.playRoughSlideSound, "race sound intent reaches effect")
        require(racingRecord.forwardVelocity == 20.4, "race speed reaches object record")
        require(racingRecord.timer == 1, "owner timer advances in stable action")
        fingerprint = hashOutput(fingerprint, racingEffect.output, record: racingRecord)

        let endTick = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(pathStatus: SM64RacingPenguinBehavior.pathReachedEnd)]
        )
        guard let endEffect = endTick.effects.first,
              let endRecord = engineState.objects.record(for: id) else {
            preconditionFailure("race end effect missing")
        }
        require(endEffect.output.reachedBottom && endRecord.action == SM64RacingPenguinBehavior.finishRace, "path end synchronized")
        fingerprint = hashOutput(fingerprint, endEffect.output, record: endRecord)

        require(engineState.objects.markForDeletion(id), "mark racing penguin for deletion")
        let deletionTick = bridge.tick(state: engineState)
        require(deletionTick.scheduler.unloaded == [id], "scheduler unload ordering")
        require(bridge.state(for: id) == nil && bridge.registeredIDs.isEmpty, "bridge removes stale generation")

        print(String(format: "racingPenguinObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin object bridge smoke passed")
    }
}
