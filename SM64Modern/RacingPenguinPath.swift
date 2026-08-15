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

    /// The US Snowman Land penguin race trajectory copied from
    /// `ccm_seg7_trajectory_penguin_race`.  The source intentionally omits
    /// waypoint ID 27; the pointer-style C path therefore retains the same
    /// 52 operational entries followed by the `-1` sentinel.
    static let ccmPenguinRace: [SM64RacingPenguinWaypoint] = [
        .init(flags: 0, x: -4762, y: 6660, z: -6143),
        .init(flags: 1, x: -4133, y: 6455, z: -6100),
        .init(flags: 2, x: -2000, y: 6100, z: -5944),
        .init(flags: 3, x: -1200, y: 6033, z: -5833),
        .init(flags: 4, x: 1022, y: 5611, z: -6033),
        .init(flags: 5, x: 3833, y: 5033, z: -6233),
        .init(flags: 6, x: 6055, y: 4598, z: -5766),
        .init(flags: 7, x: 6677, y: 4462, z: -4877),
        .init(flags: 8, x: 6277, y: 4417, z: -3344),
        .init(flags: 9, x: 4788, y: 4280, z: -1844),
        .init(flags: 10, x: 2211, y: 4086, z: -555),
        .init(flags: 11, x: 522, y: 3687, z: -222),
        .init(flags: 12, x: -724, y: 3443, z: -466),
        .init(flags: 13, x: -1350, y: 3302, z: -1288),
        .init(flags: 14, x: -1255, y: 3039, z: -3000),
        .init(flags: 15, x: -2233, y: 2785, z: -4533),
        .init(flags: 16, x: -3288, y: 2622, z: -4820),
        .init(flags: 17, x: -4266, y: 2480, z: -4555),
        .init(flags: 18, x: -4900, y: 2333, z: -3944),
        .init(flags: 19, x: -5066, y: 2175, z: -2977),
        .init(flags: 20, x: -4833, y: 2018, z: -1999),
        .init(flags: 21, x: -4122, y: 1866, z: -1366),
        .init(flags: 22, x: -3200, y: 1736, z: -1088),
        .init(flags: 23, x: -222, y: 1027, z: -1200),
        .init(flags: 24, x: 1333, y: 761, z: -1733),
        .init(flags: 25, x: 2488, y: 562, z: -2944),
        .init(flags: 26, x: 2977, y: 361, z: -4988),
        .init(flags: 28, x: 3754, y: 329, z: -5689),
        .init(flags: 29, x: 5805, y: 86, z: -5980),
        .init(flags: 30, x: 6566, y: -449, z: -4133),
        .init(flags: 31, x: 6689, y: -1119, z: -888),
        .init(flags: 32, x: 6688, y: -2127, z: 1200),
        .init(flags: 33, x: 6666, y: -2573, z: 3555),
        .init(flags: 34, x: 6600, y: -2667, z: 4333),
        .init(flags: 35, x: 6366, y: -2832, z: 5722),
        .init(flags: 36, x: 5844, y: -3021, z: 6355),
        .init(flags: 37, x: 2955, y: -3394, z: 6255),
        .init(flags: 38, x: 1788, y: -3512, z: 5988),
        .init(flags: 39, x: -89, y: -3720, z: 5188),
        .init(flags: 40, x: -732, y: -3910, z: 4144),
        .init(flags: 41, x: -722, y: -4095, z: 2688),
        .init(flags: 42, x: -1333, y: -4198, z: 1255),
        .init(flags: 43, x: -2377, y: -4302, z: 788),
        .init(flags: 44, x: -4500, y: -4684, z: 277),
        .init(flags: 45, x: -5466, y: -4790, z: 11),
        .init(flags: 46, x: -6044, y: -4860, z: -333),
        .init(flags: 47, x: -6388, y: -5079, z: -1155),
        .init(flags: 48, x: -6510, y: -5389, z: -2666),
        .init(flags: 49, x: -6476, y: -5555, z: -3622),
        .init(flags: 50, x: -6488, y: -5684, z: -4777),
        .init(flags: 51, x: -6488, y: -5829, z: -6088),
        .init(flags: 52, x: -6507, y: -5841, z: -6400),
        .init(flags: -1, x: 0, y: 0, z: 0),
    ]

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
