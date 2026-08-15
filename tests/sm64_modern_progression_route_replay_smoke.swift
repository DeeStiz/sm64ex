import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 {
    var next = h
    next ^= UInt64(value)
    next &*= fnvPrime
    return next
}

private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    (0..<4).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt32($1 * 8)))
    }
}

private func h64(_ h: UInt64, _ value: UInt64) -> UInt64 {
    (0..<8).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt64($1 * 8)))
    }
}

@main
enum SM64ModernProgressionRouteReplaySmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-route-replay-\(UUID().uuidString)")
        let token: UInt64 = 0xA1B2_C3D4_E5F6_0718
        let adapter = try SM64OwnerThreadEEPROMAdapter(
            rootURL: root, ownerThreadToken: token
        )
        var replay = SM64ProgressionRouteReplay(
            adapter: adapter, ownerThreadToken: token
        )
        let records = try replay.run()
        precondition(records.count == 9)
        precondition(records.map(\.routeID) == Array(1...9))
        precondition(records.allSatisfy(\.accepted))
        precondition(records[0].generation == 0 && records[1].generation == 0)
        precondition(records[8].generation == 1)

        var fingerprint = fnvOffset
        for record in records {
            fingerprint = h8(fingerprint, record.routeID)
            fingerprint = h32(fingerprint, record.generation)
            fingerprint = h8(fingerprint, record.accepted ? 1 : 0)
            fingerprint = h64(fingerprint, record.saveHash)
            fingerprint = h64(fingerprint, record.menuHash)
        }
        print(String(format: "progressionRouteReplayFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression-route replay smoke passed")
    }
}
