import Foundation

struct SM64RacingPenguinWaypoint: Equatable, Sendable {
    let flags: Int16
    let position: SM64ObjectVector3

    init(flags: Int16, x: Float, y: Float, z: Float) {
        self.flags = flags
        self.position = SM64ObjectVector3(x: x, y: y, z: z)
    }
}

struct SM64RacingPenguinPathInput: Equatable, Sendable {
    let waypoints: [SM64RacingPenguinWaypoint]
    let startIndex: Int
    let previousIndex: Int
    let previousFlags: Int32
    let position: SM64ObjectVector3
}

struct SM64RacingPenguinPathOutput: Equatable, Sendable {
    let status: Int32
    let previousIndex: Int
    let previousFlags: Int32
    let targetYaw: Int16
    let targetPitch: Int16
}

/// Value counterpart of `cur_obj_follow_path(0)`.
///
/// Waypoint arrays are copied value data, including the source flags and
/// missing-ID gaps. No pointer arithmetic or segmented address crosses the
/// Swift owner boundary.
enum SM64RacingPenguinPath {
    static let pathNone: Int32 = 0
    static let pathReachedWaypoint: Int32 = 1
    static let pathReachedEnd: Int32 = -1
    static let waypointFlagsEnd: Int16 = -1
    static let waypointFlagsInitialized: Int32 = 0x8000

    static func update(_ input: SM64RacingPenguinPathInput) -> SM64RacingPenguinPathOutput {
        guard !input.waypoints.isEmpty,
              input.startIndex >= 0,
              input.startIndex < input.waypoints.count else {
            return SM64RacingPenguinPathOutput(
                status: pathNone,
                previousIndex: input.previousIndex,
                previousFlags: input.previousFlags,
                targetYaw: 0,
                targetPitch: 0
            )
        }

        var lastIndex = input.previousIndex
        var previousFlags = input.previousFlags
        if previousFlags == 0 {
            lastIndex = input.startIndex
            previousFlags = waypointFlagsInitialized
        }
        guard lastIndex >= 0, lastIndex < input.waypoints.count else {
            return SM64RacingPenguinPathOutput(
                status: pathNone,
                previousIndex: lastIndex,
                previousFlags: previousFlags,
                targetYaw: 0,
                targetPitch: 0
            )
        }

        let last = input.waypoints[lastIndex]
        let targetIndex: Int
        if lastIndex + 1 < input.waypoints.count,
           input.waypoints[lastIndex + 1].flags != waypointFlagsEnd {
            targetIndex = lastIndex + 1
        } else {
            targetIndex = input.startIndex
        }
        let target = input.waypoints[targetIndex]
        previousFlags = Int32(last.flags) | waypointFlagsInitialized

        let prevToNextX = target.position.x - last.position.x
        let prevToNextY = target.position.y - last.position.y
        let prevToNextZ = target.position.z - last.position.z
        let objectToNextX = target.position.x - input.position.x
        let objectToNextY = target.position.y - input.position.y
        let objectToNextZ = target.position.z - input.position.z
        let objectToNextXZ = (objectToNextX * objectToNextX + objectToNextZ * objectToNextZ).squareRoot()
        let targetYaw = SM64CanonicalTrig.atan2s(y: objectToNextZ, x: objectToNextX)
        let targetPitch = SM64CanonicalTrig.atan2s(y: objectToNextXZ, x: -objectToNextY)

        let dot = prevToNextX * objectToNextX
            + prevToNextY * objectToNextY
            + prevToNextZ * objectToNextZ
        guard dot <= 0 else {
            return SM64RacingPenguinPathOutput(
                status: pathNone,
                previousIndex: lastIndex,
                previousFlags: previousFlags,
                targetYaw: targetYaw,
                targetPitch: targetPitch
            )
        }

        let nextFlags = targetIndex + 1 < input.waypoints.count
            ? input.waypoints[targetIndex + 1].flags
            : waypointFlagsEnd
        return SM64RacingPenguinPathOutput(
            status: nextFlags == waypointFlagsEnd ? pathReachedEnd : pathReachedWaypoint,
            previousIndex: targetIndex,
            previousFlags: previousFlags,
            targetYaw: targetYaw,
            targetPitch: targetPitch
        )
    }
}
