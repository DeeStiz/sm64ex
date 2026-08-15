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

private func hashI16(_ initial: UInt64, _ value: Int16) -> UInt64 {
    hashU32(initial, UInt32(UInt16(bitPattern: value)))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

@main
enum SM64ModernRacingPenguinTrajectorySmoke {
    static func main() {
        let waypoints = SM64RacingPenguinPath.ccmPenguinRace
        precondition(waypoints.count == 53, "CCM race path retains 52 waypoints and sentinel")
        precondition(waypoints[26].flags == 26 && waypoints[27].flags == 28, "source missing ID 27 retained")
        precondition(waypoints.last?.flags == -1, "trajectory sentinel retained")

        var fingerprint = hashU32(fnvOffset, UInt32(waypoints.count))
        for waypoint in waypoints {
            fingerprint = hashI16(fingerprint, waypoint.flags)
            fingerprint = hashFloat(fingerprint, waypoint.position.x)
            fingerprint = hashFloat(fingerprint, waypoint.position.y)
            fingerprint = hashFloat(fingerprint, waypoint.position.z)
        }

        print(String(format: "racingPenguinTrajectoryFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin trajectory smoke passed")
    }
}
