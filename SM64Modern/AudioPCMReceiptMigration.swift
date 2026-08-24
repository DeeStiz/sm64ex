import Darwin
import Foundation
import os

private let audioPCMReceiptLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "AudioPCMReceiptMigration"
)

/// Fixed-width copy of the native pre-device audio receipt. The PCM bytes and
/// AVAudio objects never cross into Swift; C remains the synthesis and device
/// authority.
struct SM64AudioPCMReceipt: Equatable, Sendable {
    let simulationTick: UInt64
    let frameCount: UInt32
    let sampleRateHz: UInt32
    let channelCount: UInt32
    let sampleFormat: UInt32
    let sequence: UInt32
    let pcmHash: UInt64

    init(native: SM64ModernAudioPCMReceiptV1) throws {
        guard native.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              native.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernAudioPCMReceiptV1>.size
              ),
              native.frame_count > 0,
              native.sample_rate_hz == SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ,
              native.channel_count == SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT,
              native.sample_format == SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO,
              native.reserved == 0 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        simulationTick = native.simulation_tick
        frameCount = native.frame_count
        sampleRateHz = native.sample_rate_hz
        channelCount = native.channel_count
        sampleFormat = native.sample_format
        sequence = native.sequence
        pcmHash = native.pcm_hash
    }

    var values: [UInt64] {
        [
            UInt64(frameCount),
            UInt64(sampleRateHz),
            UInt64(channelCount),
            UInt64(sampleFormat),
            pcmHash,
        ]
    }

    func traceRecord() throws -> SM64OracleTraceRecord {
        try SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: SM64_MODERN_ORACLE_DOMAIN_AUDIO,
            recordKind: SM64_MODERN_ORACLE_RECORD_AUDIO_PCM,
            subjectID: 0,
            recordID: UInt64(SM64_MODERN_ORACLE_AUDIO_EVENT_PCM),
            sequence: sequence,
            values: values
        )
    }
}

/// Owner-thread mirror for the native PCM receipt seam. It stores only the
/// fixed-width receipt and its canonical schema-4 record.
struct SM64AudioPCMReceiptMirror: Equatable, Sendable {
    private(set) var receipts: [SM64AudioPCMReceipt] = []
    private(set) var traceRecords: [SM64OracleTraceRecord] = []

    mutating func observe(native: SM64ModernAudioPCMReceiptV1) throws {
        let receipt = try SM64AudioPCMReceipt(native: native)
        if let previous = receipts.last {
            guard receipt.simulationTick > previous.simulationTick
                    || (receipt.simulationTick == previous.simulationTick
                        && receipt.sequence > previous.sequence) else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }
        let record = try receipt.traceRecord()
        receipts.append(receipt)
        traceRecords.append(record)
    }
}

private func currentAudioPCMReceiptThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func audioPCMReceiptService(
    from context: UnsafeMutableRawPointer?
) -> SwiftAudioPCMReceiptService? {
    guard let context else { return nil }
    return Unmanaged<SwiftAudioPCMReceiptService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftAudioPCMReceiptObserve: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernAudioPCMReceiptV1>?
) -> SM64ModernStatus = { context, receipt in
    guard let service = audioPCMReceiptService(from: context), let receipt else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.observe(native: receipt.pointee)
}

/// Swift's owner-thread value-only PCM consumer. It is installed alongside
/// the existing sequence observer and never runs from AVAudio's realtime leaf.
final class SwiftAudioPCMReceiptService {
    private let ownerThreadToken: UInt64
    private let constructionThreadToken: UInt64
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK
    private(set) var mirror = SM64AudioPCMReceiptMirror()

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.constructionThreadToken = currentAudioPCMReceiptThreadIdentity()
    }

    func makeAPI() -> SM64ModernAudioPCMMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernAudioPCMMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernAudioPCMMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.observe_pcm_receipt = swiftAudioPCMReceiptObserve
        return api
    }

    func observe(native: SM64ModernAudioPCMReceiptV1) -> SM64ModernStatus {
        assertOwnerThread()
        guard lastError == SM64_MODERN_STATUS_OK else { return lastError }
        do {
            try mirror.observe(native: native)
            if mirror.receipts.count == 1 {
                audioPCMReceiptLogger.notice(
                    "swift_audio_pcm_receipt tick=\(native.simulation_tick, privacy: .public) frames=\(native.frame_count, privacy: .public) sequence=\(native.sequence, privacy: .public)"
                )
            }
            return SM64_MODERN_STATUS_OK
        } catch {
            lastError = SM64_MODERN_STATUS_INVALID_ARGUMENT
            return lastError
        }
    }

    func summary() -> (receipts: Int, records: Int, lastTick: UInt64?, fingerprint: UInt64) {
        assertOwnerThread()
        var fingerprint = SM64OracleTraceHash.offset
        for record in mirror.traceRecords {
            fingerprint = fingerprint.update(record.canonicalHash)
        }
        return (
            mirror.receipts.count,
            mirror.traceRecords.count,
            mirror.receipts.last?.simulationTick,
            fingerprint
        )
    }

    private func assertOwnerThread() {
        precondition(currentAudioPCMReceiptThreadIdentity() == constructionThreadToken)
        precondition(currentAudioPCMReceiptThreadIdentity() == ownerThreadToken)
    }
}

private extension UInt64 {
    func update(_ value: UInt64) -> UInt64 {
        var hash = self
        for byte in 0..<8 {
            hash ^= (value >> UInt64(byte * 8)) & 0xff
            hash &*= SM64OracleTraceHash.prime
        }
        return hash
    }
}
