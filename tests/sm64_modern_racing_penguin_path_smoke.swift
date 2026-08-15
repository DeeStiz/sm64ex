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

private func hashOutput(_ initial: UInt64, _ output: SM64RacingPenguinPathOutput) -> UInt64 {
    var hash = hashI32(initial, output.status)
    hash = hashI32(hash, Int32(output.previousIndex))
    hash = hashI32(hash, output.previousFlags)
    hash = hashI16(hash, output.targetYaw)
    return hashI16(hash, output.targetPitch)
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
enum SM64ModernRacingPenguinPathSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let first = SM64RacingPenguinPath.update(
            SM64RacingPenguinPathInput(
                waypoints: path,
                startIndex: 0,
                previousIndex: 0,
                previousFlags: 0,
                position: SM64ObjectVector3(x: 0, y: 0, z: 0)
            )
        )
        require(first.status == SM64RacingPenguinPath.pathNone, "first path sample remains in segment")
        require(first.previousIndex == 0 && first.previousFlags == 0x8000, "initial path state")
        fingerprint = hashOutput(fingerprint, first)

        let waypoint = SM64RacingPenguinPath.update(
            SM64RacingPenguinPathInput(
                waypoints: path,
                startIndex: 0,
                previousIndex: first.previousIndex,
                previousFlags: first.previousFlags,
                position: SM64ObjectVector3(x: 11, y: 6, z: 0)
            )
        )
        require(waypoint.status == SM64RacingPenguinPath.pathReachedWaypoint, "crossing advances to the next waypoint")
        require(waypoint.previousIndex == 1 && waypoint.previousFlags == 0x8000, "waypoint flag state")
        fingerprint = hashOutput(fingerprint, waypoint)

        let end = SM64RacingPenguinPath.update(
            SM64RacingPenguinPathInput(
                waypoints: path,
                startIndex: 0,
                previousIndex: waypoint.previousIndex,
                previousFlags: waypoint.previousFlags,
                position: SM64ObjectVector3(x: 21, y: -1, z: 11)
            )
        )
        require(end.status == SM64RacingPenguinPath.pathReachedEnd, "crossing the last segment reaches the end")
        require(end.previousIndex == 2 && end.previousFlags == 0x8007, "last waypoint flags preserve source ID")
        fingerprint = hashOutput(fingerprint, end)

        let restart = SM64RacingPenguinPath.update(
            SM64RacingPenguinPathInput(
                waypoints: path,
                startIndex: 1,
                previousIndex: 99,
                previousFlags: 0,
                position: SM64ObjectVector3(x: 10, y: 5, z: 0)
            )
        )
        require(restart.previousIndex == 1 && restart.previousFlags == 0x8007, "zero flags reset to the requested start")
        fingerprint = hashOutput(fingerprint, restart)

        print(String(format: "racingPenguinPathFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin path smoke passed")
    }
}
