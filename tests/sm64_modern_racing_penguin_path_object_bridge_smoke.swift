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

private func hashPath(_ initial: UInt64, action: Int32, path: SM64RacingPenguinPathOutput) -> UInt64 {
    var hash = hashI32(initial, action)
    hash = hashI32(hash, path.status)
    hash = hashI32(hash, Int32(path.previousIndex))
    hash = hashI32(hash, path.previousFlags)
    hash = hashI16(hash, path.targetYaw)
    return hashI16(hash, path.targetPitch)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private let path: [SM64RacingPenguinWaypoint] = [
    SM64RacingPenguinWaypoint(flags: 0, x: 0, y: 0, z: 0),
    SM64RacingPenguinWaypoint(flags: 7, x: 10, y: 5, z: 0),
    SM64RacingPenguinWaypoint(flags: 35, x: 20, y: 0, z: 10),
    SM64RacingPenguinWaypoint(flags: -1, x: 0, y: 0, z: 0),
]

@main
enum SM64ModernRacingPenguinPathObjectBridgeSmoke {
    static func main() throws {
        let engineState = SM64SwiftEngineState(objectCapacity: 4)
        let bridge = SM64RacingPenguinObjectBridge()
        let id = try bridge.spawnPenguin(in: engineState)
        _ = bridge.tick(state: engineState)
        _ = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(canActivateInitialText: true)]
        )
        _ = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(
                initialDialogResponse: 1,
                pathWaypoints: path
            )]
        )

        let started = bridge.tick(
            state: engineState,
            environments: [id: SM64RacingPenguinEnvironment(raceBeginComplete: true)]
        )
        guard let startedEffect = started.effects.first,
              let startedPath = startedEffect.path else {
            preconditionFailure("initial path result missing")
        }
        require(startedEffect.output.action == SM64RacingPenguinBehavior.race, "path route starts race")
        require(startedPath.status == SM64RacingPenguinPath.pathNone, "initial path remains in segment")

        require(engineState.objects.mutate(id) { record in
            record.position = SM64ObjectVector3(x: 11, y: 6, z: 0)
        }, "move parent across first waypoint")
        let waypointTick = bridge.tick(state: engineState)
        guard let waypointEffect = waypointTick.effects.first,
              let waypointPath = waypointEffect.path else {
            preconditionFailure("waypoint path result missing")
        }
        require(waypointPath.status == SM64RacingPenguinPath.pathReachedWaypoint, "bridge advances waypoint")
        require(waypointPath.previousIndex == 1, "bridge retains waypoint index")

        require(engineState.objects.mutate(id) { record in
            record.position = SM64ObjectVector3(x: 21, y: -1, z: 11)
        }, "move parent across final waypoint")
        let endTick = bridge.tick(state: engineState)
        guard let endEffect = endTick.effects.first,
              let endPath = endEffect.path else {
            preconditionFailure("end path result missing")
        }
        require(endEffect.output.action == SM64RacingPenguinBehavior.finishRace, "path end enters finish")
        require(endPath.status == SM64RacingPenguinPath.pathReachedEnd, "bridge reports path end")

        var fingerprint = fnvOffset
        fingerprint = hashPath(fingerprint, action: startedEffect.output.action, path: startedPath)
        fingerprint = hashPath(fingerprint, action: waypointEffect.output.action, path: waypointPath)
        fingerprint = hashPath(fingerprint, action: endEffect.output.action, path: endPath)
        require(engineState.objects.markForDeletion(id), "parent deletion request")
        _ = bridge.tick(state: engineState)

        print(String(format: "racingPenguinPathObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin path object bridge smoke passed")
    }
}
