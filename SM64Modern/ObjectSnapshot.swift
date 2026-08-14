import Foundation

/// The object portion of the schema-4 differential contract. The first 20
/// values preserve the retained C actor snapshot order; the relation values
/// are a separate fixed tail so pointer identity is always represented as a
/// one-based C slot subject (or zero for nil).
struct SM64ObjectSnapshotV4: Equatable, Sendable {
    static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    static let fnvPrime: UInt64 = 1_099_511_628_211

    let subject: UInt32
    let actorValues: [UInt64]
    let relationValues: [UInt64]

    init(record: SM64ObjectRecord) {
        self.subject = record.id.traceSubject
        self.actorValues = [
            record.behaviorIdentity,
            UInt64(record.activeFlags),
            UInt64(bitPattern: Int64(record.action)),
            UInt64(bitPattern: Int64(record.subAction)),
            UInt64(bitPattern: Int64(record.timer)),
            UInt64(record.position.x.bitPattern),
            UInt64(record.position.y.bitPattern),
            UInt64(record.position.z.bitPattern),
            UInt64(record.velocity.x.bitPattern),
            UInt64(record.velocity.y.bitPattern),
            UInt64(record.velocity.z.bitPattern),
            UInt64(UInt32(bitPattern: record.moveAngles.pitch)),
            UInt64(UInt32(bitPattern: record.moveAngles.yaw)),
            UInt64(UInt32(bitPattern: record.moveAngles.roll)),
            UInt64(record.moveFlags),
            UInt64(bitPattern: Int64(record.interactionStatus)),
            UInt64(record.heldState),
            UInt64(record.objectFlags),
            UInt64(record.forwardVelocity.bitPattern),
            UInt64(record.graphFlags),
        ]
        self.relationValues = [
            Self.subject(for: record.parent),
            Self.subject(for: record.previousObject),
            Self.subject(for: record.platform),
            Self.subject(for: record.collidedObjects[0]),
            Self.subject(for: record.collidedObjects[1]),
            Self.subject(for: record.collidedObjects[2]),
            Self.subject(for: record.collidedObjects[3]),
        ]
    }

    var actorFingerprint: UInt64 {
        Self.fingerprint(actorValues)
    }

    var relationFingerprint: UInt64 {
        Self.fingerprint(relationValues)
    }

    var combinedFingerprint: UInt64 {
        Self.fingerprint([UInt64(subject)] + actorValues + relationValues)
    }

    private static func subject(for id: SM64ObjectID?) -> UInt64 {
        id.map { UInt64($0.traceSubject) } ?? 0
    }

    private static func fingerprint(_ values: [UInt64]) -> UInt64 {
        values.reduce(Self.fnvOffset) { partial, value in
            var hash = partial
            for byte in 0..<8 {
                hash ^= (value >> UInt64(byte * 8)) & 0xff
                hash &*= Self.fnvPrime
            }
            return hash
        }
    }
}

extension SM64ObjectPool {
    func schema4Snapshots() -> [SM64ObjectSnapshotV4] {
        updateIDs().compactMap(record(for:)).map(SM64ObjectSnapshotV4.init(record:))
    }
}
