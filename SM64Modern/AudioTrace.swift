import Foundation

enum SM64AudioTraceSource: UInt8, Equatable, Sendable {
    case sequence = 1
    case pool = 2
    case residency = 3
    case stream = 4
}

/// Owner-thread admission and schema-4 projection for the pre-synthesis audio
/// value models. The session owns no audio pointers and never calls AVAudio.
struct SM64AudioPreSynthesisTraceSession: Equatable, Sendable {
    static let traceDomain: UInt32 = 9
    static let traceRecordKind: UInt32 = 1

    let ownerToken: UInt64
    private(set) var records: [SM64OracleTraceRecord] = []
    private(set) var nextSequence: UInt32 = 0
    private(set) var admissionFailed = false

    init(ownerToken: UInt64) {
        self.ownerToken = ownerToken
    }

    mutating func reset() {
        records.removeAll(keepingCapacity: true)
        nextSequence = 0
        admissionFailed = false
    }

    @discardableResult
    mutating func append(
        ownerToken candidateToken: UInt64,
        simulationTick: UInt64,
        source: SM64AudioTraceSource,
        eventCode: UInt32,
        subjectID: UInt64,
        flags: UInt32 = 0,
        values: [UInt64]
    ) -> Bool {
        guard candidateToken == ownerToken, !admissionFailed else {
            admissionFailed = true
            return false
        }
        let recordID = (UInt64(0xA700_0000) | (UInt64(source.rawValue) << 16))
            | UInt64(eventCode & 0xFFFF)
        do {
            let record = try SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: Self.traceDomain,
                recordKind: Self.traceRecordKind,
                subjectID: subjectID,
                recordID: recordID,
                sequence: nextSequence,
                flags: flags,
                values: Array(values.prefix(8))
            )
            records.append(record)
            nextSequence &+= 1
            return true
        } catch {
            admissionFailed = true
            return false
        }
    }

    @discardableResult
    mutating func append(
        ownerToken candidateToken: UInt64,
        simulationTick: UInt64,
        player: Int,
        event: SM64AudioSequenceEvent
    ) -> Bool {
        append(
            ownerToken: candidateToken,
            simulationTick: simulationTick,
            source: .sequence,
            eventCode: UInt32(event.kind.rawValue),
            subjectID: UInt64(max(player, 0)),
            values: [
                UInt64(event.opcode),
                UInt64(UInt32(bitPattern: event.value0)),
                UInt64(UInt32(bitPattern: event.value1))
            ]
        )
    }

    @discardableResult
    mutating func append(
        ownerToken candidateToken: UInt64,
        simulationTick: UInt64,
        channel: Int,
        event: SM64AudioPoolEvent
    ) -> Bool {
        append(
            ownerToken: candidateToken,
            simulationTick: simulationTick,
            source: .pool,
            eventCode: UInt32(event.kind.rawValue),
            subjectID: UInt64(max(channel, 0)),
            values: [
                UInt64(UInt32(bitPattern: Int32(event.scope))),
                UInt64(UInt32(bitPattern: Int32(event.index))),
                UInt64(UInt32(bitPattern: Int32(event.noteID))),
                UInt64(UInt32(bitPattern: Int32(event.value)))
            ]
        )
    }

    @discardableResult
    mutating func append(
        ownerToken candidateToken: UInt64,
        simulationTick: UInt64,
        subjectID: Int,
        event: SM64AudioResidencyEvent,
        source: SM64AudioTraceSource = .residency
    ) -> Bool {
        append(
            ownerToken: candidateToken,
            simulationTick: simulationTick,
            source: source,
            eventCode: UInt32(event.kind.rawValue),
            subjectID: UInt64(max(subjectID, 0)),
            values: [
                UInt64(event.resource.rawValue),
                UInt64(UInt32(bitPattern: Int32(event.id))),
                UInt64(UInt32(bitPattern: Int32(event.index))),
                UInt64(UInt32(bitPattern: Int32(event.value)))
            ]
        )
    }

    @discardableResult
    mutating func append(
        ownerToken candidateToken: UInt64,
        simulationTick: UInt64,
        player: Int,
        packet: SM64AudioSequenceEventPacket
    ) -> Bool {
        for event in packet.events {
            guard append(ownerToken: candidateToken, simulationTick: simulationTick, player: player, event: event) else {
                return false
            }
        }
        return true
    }
}
