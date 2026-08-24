import Foundation

/// Independent value-only mirror for the source-bound JRB break-particle RNG
/// route.  C remains the owner of the live object and seed; this migration
/// replays only the copied u16 receipts and reconstructs fresh schema-4
/// records.  The first receipt is the lifecycle's source-bound seed anchor;
/// later move/pitch values are checked against the canonical PRNG with the
/// two authored random calls between triangles.
struct SM64RNGBreakParticlesMigration: Sendable {
    static let shardID: UInt64 = 0x0057_6356_a427_dbc2
    static let inputSeed: UInt64 = 0x7f28_9fd4_1270_636e
    static let saveSeed: UInt64 = 0x3e05_c8a6_a9f4_1727
    static let sourceIdentity: UInt64 = 0xcb90_922e_394c_3a9b
    static let moveYawCallSite: UInt32 = 0xf2f9_30d7
    static let facePitchCallSite: UInt32 = 0x4648_c6c9
    static let routeTick: UInt64 = 2_084
    static let recordCount = 40
    static let firstSequence: UInt32 = 71
    static let sequenceStride: UInt32 = 8
    static let faceSequenceOffset: UInt32 = 2

    static let buildFingerprintText = "sm64-modern-rng-break-particles-route-build-v1"
    static let contentFingerprintText = "src/game/behaviors/break_particles.inc.c|random_u16|rng"
    static let configurationFingerprintText =
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        + "route=0x00576356a427dbc2;source=0xcb90922e394c3a9b;tick=2084;records=40"
    static let saveFingerprintText = "save=empty-us-slot-0;seed=0x3e05c8a6a9f41727"

    private var random: SM64Random16?

    init() {}

    static func hashString(_ text: String) -> UInt64 {
        text.utf8.reduce(SM64OracleTraceHash.offset) { partial, byte in
            (partial ^ UInt64(byte)) &* SM64OracleTraceHash.prime
        }
    }

    static func hashU64(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xff
            result &*= SM64OracleTraceHash.prime
        }
        return result
    }

    static var coverageFingerprint: UInt64 {
        var hash = hashString("rng_break_particles|coverage-v1")
        hash = hashU64(hash, 8) // SM64_MODERN_ORACLE_DOMAIN_RNG
        hash = hashU64(hash, 3) // SM64_MODERN_ORACLE_RECORD_EVENT
        hash = hashU64(hash, sourceIdentity)
        hash = hashU64(hash, UInt64(moveYawCallSite))
        hash = hashU64(hash, UInt64(facePitchCallSite))
        return hashU64(hash, UInt64(recordCount))
    }

    static var expectedConfiguration: SM64OracleTraceConfiguration {
        SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: hashString(buildFingerprintText),
            contentFingerprint: hashString(contentFingerprintText),
            // The 60/30 paired timebase fingerprint is stable across the
            // native build configurations and is checked by admission.
            timebaseFingerprint: 0xccc1_9787_cd09_f0c2,
            configurationFingerprint: hashString(configurationFingerprintText),
            initialSaveFingerprint: hashString(saveFingerprintText),
            coverageFingerprint: coverageFingerprint
        )
    }

    private static func sequence(for index: Int) -> UInt32 {
        firstSequence + sequenceStride * UInt32(index / 2)
            + (index.isMultiple(of: 2) ? 0 : faceSequenceOffset)
    }

    private static func callSite(for index: Int) -> UInt32 {
        index.isMultiple(of: 2) ? moveYawCallSite : facePitchCallSite
    }

    private mutating func expectedValue(for index: Int, firstValue: UInt16) -> UInt16 {
        if random == nil {
            random = SM64Random16(seed: firstValue)
            return firstValue
        }
        if index.isMultiple(of: 2) {
            // Two source-authored random_float calls occur between the
            // previous face-pitch receipt and the next triangle's move yaw.
            _ = random!.next()
            _ = random!.next()
        }
        return random!.next()
    }

    mutating func mirror(
        native records: [SM64OracleTraceRecord],
        configuration: SM64OracleTraceConfiguration
    ) throws -> (
        configuration: SM64OracleTraceConfiguration,
        records: [SM64OracleTraceRecord]
    ) {
        guard records.count == Self.recordCount,
              configuration == Self.expectedConfiguration else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        var mirrored: [SM64OracleTraceRecord] = []
        mirrored.reserveCapacity(records.count)
        for (index, native) in records.enumerated() {
            guard native.simulationTick == Self.routeTick,
                  native.domain == 8,
                  native.recordKind == 3,
                  native.subjectID == Self.sourceIdentity,
                  native.recordID == 1,
                  native.sequence == Self.sequence(for: index),
                  native.flags == Self.callSite(for: index),
                  native.values.count == 2,
                  native.values[0] == native.values[1],
                  native.values[0] <= UInt64(UInt16.max) else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            let firstValue = UInt16(truncatingIfNeeded: records[0].values[0])
            let expected = expectedValue(
                for: index,
                firstValue: firstValue
            )
            guard native.values[0] == UInt64(expected) else {
                throw SM64OracleTraceCodecError.nonCanonicalHash
            }
            mirrored.append(try SM64OracleTraceRecord(
                simulationTick: native.simulationTick,
                domain: native.domain,
                recordKind: native.recordKind,
                subjectID: native.subjectID,
                recordID: native.recordID,
                sequence: native.sequence,
                flags: native.flags,
                values: [UInt64(expected), UInt64(expected)]
            ))
        }
        return (Self.expectedConfiguration, mirrored)
    }
}
