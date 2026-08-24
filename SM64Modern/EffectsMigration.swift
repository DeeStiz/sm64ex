import Darwin
import Foundation

/// Fixed-width copy of one native owner-thread effect. The native C owner
/// remains responsible for object/audio/rumble mutation; Swift receives only
/// the exact schema-4 values that were already published at that boundary.
struct SM64EffectReceipt: Equatable, Sendable {
    let simulationTick: UInt64
    let subjectID: UInt64
    let effectID: UInt64
    let sequence: UInt32
    let flags: UInt32
    let values: [UInt64]

    init(native: SM64ModernEffectReceiptV1) throws {
        guard native.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              native.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernEffectReceiptV1>.size
              ),
              (UInt64(SM64_MODERN_EFFECT_SOUND)...UInt64(
                SM64_MODERN_EFFECT_PCM_CHECKSUM
              )).contains(native.effect_id),
              native.value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY,
              native.reserved == 0 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }

        let valueCount = Int(native.value_count)
        let copiedValues = withUnsafeBytes(of: native.values) { rawBuffer in
            Array(rawBuffer.bindMemory(to: UInt64.self).prefix(valueCount))
        }
        let record = try SM64OracleTraceRecord(
            simulationTick: native.simulation_tick,
            domain: SM64_MODERN_ORACLE_DOMAIN_EFFECT,
            recordKind: SM64_MODERN_ORACLE_RECORD_EFFECT,
            subjectID: native.subject_id,
            recordID: native.effect_id,
            sequence: native.sequence,
            flags: native.flags,
            values: copiedValues
        )
        guard record.canonicalHash == native.canonical_hash else {
            throw SM64OracleTraceCodecError.nonCanonicalHash
        }

        simulationTick = native.simulation_tick
        subjectID = native.subject_id
        effectID = native.effect_id
        sequence = native.sequence
        flags = native.flags
        values = copiedValues
    }

    var traceRecord: SM64OracleTraceRecord {
        get throws {
            try SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: SM64_MODERN_ORACLE_DOMAIN_EFFECT,
                recordKind: SM64_MODERN_ORACLE_RECORD_EFFECT,
                subjectID: subjectID,
                recordID: effectID,
                sequence: sequence,
                flags: flags,
                values: values
            )
        }
    }
}

/// Ordered owner-thread mirror. A receipt is accepted only once and only in
/// the same tick/sequence order used by schema-4's effect domain. This keeps
/// Swift from fabricating or reordering native effects.
struct SM64EffectsMirror: Equatable, Sendable {
    private(set) var receipts: [SM64EffectReceipt] = []
    private(set) var traceRecords: [SM64OracleTraceRecord] = []

    mutating func observe(native: SM64ModernEffectReceiptV1) throws {
        let receipt = try SM64EffectReceipt(native: native)
        if let previous = receipts.last {
            guard receipt.simulationTick > previous.simulationTick
                    || (receipt.simulationTick == previous.simulationTick
                        && receipt.sequence == previous.sequence &+ 1) else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        } else {
            guard receipt.sequence == 0 else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }
        let record = try receipt.traceRecord
        receipts.append(receipt)
        traceRecords.append(record)
    }
}

private func currentEffectsThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func effectsMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftEffectsMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftEffectsMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftEffectsObserve: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernEffectReceiptV1>?
) -> SM64ModernStatus = { context, receipt in
    guard let service = effectsMigrationService(from: context), let receipt else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.observe(native: receipt.pointee)
}

/// Owner-thread value-only effect receipt consumer. It never invokes the
/// existing high-level router and never runs in an AVAudio realtime callback.
final class SwiftEffectsMigrationService {
    private let ownerThreadToken: UInt64
    private let constructionThreadToken: UInt64
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK
    private(set) var mirror = SM64EffectsMirror()

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.constructionThreadToken = currentEffectsThreadIdentity()
    }

    func makeAPI() -> SM64ModernEffectsMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernEffectsMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernEffectsMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.observe_effect = swiftEffectsObserve
        return api
    }

    func observe(native: SM64ModernEffectReceiptV1) -> SM64ModernStatus {
        assertOwnerThread()
        guard lastError == SM64_MODERN_STATUS_OK else { return lastError }
        do {
            try mirror.observe(native: native)
            return SM64_MODERN_STATUS_OK
        } catch SM64OracleTraceCodecError.nonCanonicalHash {
            lastError = SM64_MODERN_STATUS_PARITY_DIVERGED
            return lastError
        } catch {
            lastError = SM64_MODERN_STATUS_INVALID_ARGUMENT
            return lastError
        }
    }

    func summary() -> (receipts: Int, records: Int, lastTick: UInt64?) {
        assertOwnerThread()
        return (
            mirror.receipts.count,
            mirror.traceRecords.count,
            mirror.receipts.last?.simulationTick
        )
    }

    private func assertOwnerThread() {
        precondition(currentEffectsThreadIdentity() == constructionThreadToken)
        precondition(currentEffectsThreadIdentity() == ownerThreadToken)
    }
}
