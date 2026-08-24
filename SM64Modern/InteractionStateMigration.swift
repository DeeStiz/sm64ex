import Foundation

/// The schema-4 interaction snapshot is the value-only portion of Mario's
/// source state.  C remains authoritative for collision preparation,
/// `mario_process_interactions`, object ownership, and all side effects.  This
/// type only serializes the already-owned Swift state; it never invents an
/// interaction or answers a collision query.
struct SM64InteractionStateMigration: Sendable {
    static let domain: UInt32 = 4
    static let recordKind: UInt32 = 1
    static let firstRecord: UInt64 = 200
    static let lastRecord: UInt64 = 206

    let interactionTypes: UInt64
    let interactObject: UInt64
    let heldObject: UInt64
    let usedObject: UInt64
    let riddenObject: UInt64
    let hurtCounter: UInt64
    let healCounter: UInt64

    /// Copies only the fixed-width state fields.  Optional object references
    /// use the canonical one-based slot identity and preserve nil as zero.
    init(state: SM64MarioState) {
        interactionTypes = UInt64(state.collidedObjectInteractionTypes)
        interactObject = state.interactObjectID.map { UInt64($0.traceSubject) } ?? 0
        heldObject = state.heldObjectID.map { UInt64($0.traceSubject) } ?? 0
        usedObject = state.usedObjectID.map { UInt64($0.traceSubject) } ?? 0
        riddenObject = state.riddenObjectID.map { UInt64($0.traceSubject) } ?? 0
        hurtCounter = UInt64(state.hurtCounter)
        healCounter = UInt64(state.healCounter)
    }

    var values: [UInt64] {
        [
            interactionTypes,
            interactObject,
            heldObject,
            usedObject,
            riddenObject,
            hurtCounter,
            healCounter,
        ]
    }

    func records(simulationTick: UInt64) throws -> [SM64OracleTraceRecord] {
        try values.enumerated().map { offset, value in
            try SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: Self.domain,
                recordKind: Self.recordKind,
                recordID: Self.firstRecord + UInt64(offset),
                sequence: UInt32(offset),
                values: [value]
            )
        }
    }
}
