import Foundation

/// Receipt-only bridge for the native RNG boundary. The C engine remains the
/// authority for seed mutation and draw timing; Swift validates copied schema-4
/// receipts against an independent value-only PRNG initialized from the
/// canonical route seed. No process-global RNG is exposed to Swift.
struct SM64RNGDrawMigration: Sendable {
    private(set) var random: SM64Random16
    private(set) var observed: [SM64OracleTraceRecord] = []
    private var lastTick: UInt64?
    private var lastSequence: UInt32 = 0
    private var lastRaw: UInt16?

    init(seed: UInt16) {
        self.random = SM64Random16(seed: seed)
    }

    mutating func observe(native record: SM64OracleTraceRecord) throws {
        guard record.domain == 8,
              record.recordKind == 3,
              (1...3).contains(record.recordID),
              record.values.count == 2,
              (2...3).contains(record.simulationTick)
        else {
            throw SM64OracleTraceCodecError.invalidHeader
        }

        if let lastTick {
            if record.simulationTick == lastTick {
                guard record.sequence == lastSequence &+ 1 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
            } else {
                guard record.simulationTick == lastTick + 1,
                      record.sequence == 0 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
            }
        } else {
            guard record.simulationTick == 2, record.sequence == 0 else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }

        var expectedValue: UInt64
        var expectedSeed: UInt64
        switch record.recordID {
        case 1:
            // The native 60/30 paired timebase advances the legacy RNG only
            // on the first (tick 2) half of this two-tick window. Tick 3 is a
            // redraw and must retain the C-owned seed while still emitting
            // the observed hook receipt.
            let raw = record.simulationTick == 2 ? random.next() : random.seed
            lastRaw = raw
            expectedValue = UInt64(raw)
            expectedSeed = UInt64(raw)
        case 2:
            guard let raw = lastRaw else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            expectedValue = UInt64(Float(Double(raw) / 65_536.0).bitPattern)
            expectedSeed = UInt64(raw)
        case 3:
            guard let raw = lastRaw else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            let sign: Int64 = raw >= 0x7fff ? 1 : -1
            expectedValue = UInt64(bitPattern: sign)
            expectedSeed = UInt64(raw)
        default:
            throw SM64OracleTraceCodecError.invalidHeader
        }
        guard record.values == [expectedValue, expectedSeed] else {
            throw SM64OracleTraceCodecError.nonCanonicalHash
        }

        observed.append(record)
        lastTick = record.simulationTick
        lastSequence = record.sequence
    }
}
