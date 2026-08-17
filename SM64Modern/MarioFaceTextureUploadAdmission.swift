import Foundation

enum SM64MarioFaceTextureUploadAdmissionError: Error, Equatable, LocalizedError {
    case ownerMismatch(expected: UInt64, actual: UInt64)
    case routeMismatch(expected: SM64MarioFaceGoddardRouteID, actual: SM64MarioFaceGoddardRouteID)
    case bindingMismatch(textureID: UInt32)
    case payloadMismatch(textureID: UInt32, reason: String)
    case emptyPayload(textureID: UInt32)
    case invalidGeneration(textureID: UInt32, generation: UInt64)

    var errorDescription: String? {
        switch self {
        case let .ownerMismatch(expected, actual):
            return "Mario-face upload owner token mismatch expected=\(expected) actual=\(actual)"
        case let .routeMismatch(expected, actual):
            return "Mario-face upload route mismatch expected=\(expected.rawValue) actual=\(actual.rawValue)"
        case let .bindingMismatch(textureID):
            return "Mario-face upload binding mismatch texture=\(textureID)"
        case let .payloadMismatch(textureID, reason):
            return "Mario-face upload payload mismatch texture=\(textureID) reason=\(reason)"
        case let .emptyPayload(textureID):
            return "Mario-face upload payload is empty texture=\(textureID)"
        case let .invalidGeneration(textureID, generation):
            return "Mario-face upload generation is invalid texture=\(textureID) generation=\(generation)"
        }
    }
}

/// A value-only upload admitted by the engine owner.  The bytes are immutable
/// staging data; Metal handles and private residency are deliberately absent
/// until the display-link renderer prepares its next reusable frame slot.
struct SM64MarioFaceTextureUploadEntry: Equatable, Sendable {
    let textureID: UInt32
    let generation: UInt64
    let width: UInt32
    let height: UInt32
    let sourceFormat: SM64MarioFaceTextureFormat
    let sourceByteCount: UInt32
    let uploadByteCount: UInt32
    let sourcePixelFingerprint: UInt64
    let uploadPixelFingerprint: UInt64
    let rgba8Pixels: Data
    let samplerPacked: UInt32
    let usageFlags: UInt32
    let storageMode: SM64MarioFaceMetalStorageMode
    let residencyScope: SM64MarioFaceMetalResidencyScope
    let encoderDomains: UInt32

    var policyCode: UInt32 {
        usageFlags
            | (storageMode.rawValue << 8)
            | (residencyScope.rawValue << 12)
            | (encoderDomains << 16)
    }
}

struct SM64MarioFaceTextureUploadPlan: Equatable, Sendable {
    let route: SM64MarioFaceRouteRecord
    let ownerToken: UInt64
    let resourceFingerprint: UInt64
    let bindingFingerprint: UInt64
    let entries: [SM64MarioFaceTextureUploadEntry]
    let sourceByteCount: UInt32
    let uploadByteCount: UInt32
    let fingerprint: UInt64

    var firstGeneration: UInt64 { entries.first?.generation ?? 0 }
    var lastGeneration: UInt64 { entries.last?.generation ?? 0 }

    func receipt(residencyPending: Bool = true) -> SM64MarioFaceTextureUploadReceipt {
        SM64MarioFaceTextureUploadReceipt(
            route: route.routeID,
            ownerToken: ownerToken,
            admittedEntries: UInt32(entries.count),
            sourceByteCount: sourceByteCount,
            uploadByteCount: uploadByteCount,
            firstGeneration: firstGeneration,
            lastGeneration: lastGeneration,
            planFingerprint: fingerprint,
            residencyPending: residencyPending,
            pendingResidencyCount: residencyPending ? UInt32(entries.count) : 0
        )
    }
}

struct SM64MarioFaceTextureUploadReceipt: Equatable, Sendable {
    let route: SM64MarioFaceGoddardRouteID
    let ownerToken: UInt64
    let admittedEntries: UInt32
    let sourceByteCount: UInt32
    let uploadByteCount: UInt32
    let firstGeneration: UInt64
    let lastGeneration: UInt64
    let planFingerprint: UInt64
    let residencyPending: Bool
    let pendingResidencyCount: UInt32
}

enum SM64MarioFaceTextureUploadPlanBuilder {
    static func make(
        ownerToken: UInt64,
        expectedOwnerToken: UInt64,
        routeID: SM64MarioFaceGoddardRouteID,
        binding: SM64MarioFaceMetalBindingPacket,
        payloads: [SM64MarioFaceTexturePayload]
    ) throws -> SM64MarioFaceTextureUploadPlan {
        guard ownerToken == expectedOwnerToken else {
            throw SM64MarioFaceTextureUploadAdmissionError.ownerMismatch(
                expected: expectedOwnerToken, actual: ownerToken
            )
        }
        guard ownerToken != 0 else {
            throw SM64MarioFaceTextureUploadAdmissionError.ownerMismatch(
                expected: 1, actual: ownerToken
            )
        }
        guard binding.route.routeID == routeID else {
            throw SM64MarioFaceTextureUploadAdmissionError.routeMismatch(
                expected: routeID, actual: binding.route.routeID
            )
        }
        guard payloads.count == binding.textures.count else {
            throw SM64MarioFaceTextureUploadAdmissionError.payloadMismatch(
                textureID: 0, reason: "entry_count"
            )
        }
        if routeID == .marioNormal, payloads.count != 3 {
            throw SM64MarioFaceTextureUploadAdmissionError.payloadMismatch(
                textureID: 0, reason: "mario_normal_entry_count"
            )
        }

        var entries: [SM64MarioFaceTextureUploadEntry] = []
        entries.reserveCapacity(payloads.count)
        var sourceBytes: UInt32 = 0
        var uploadBytes: UInt32 = 0
        for (index, payload) in payloads.enumerated() {
            let textureBinding = binding.textures[index]
            guard payload.textureID == textureBinding.textureID else {
                throw SM64MarioFaceTextureUploadAdmissionError.bindingMismatch(
                    textureID: payload.textureID
                )
            }
            let generation = UInt64(index + 1)
            guard generation > 0 else {
                throw SM64MarioFaceTextureUploadAdmissionError.invalidGeneration(
                    textureID: payload.textureID, generation: generation
                )
            }
            let expectedSourceBytes = textureBinding.width * textureBinding.height
                * textureBinding.sourceBitsPerTexel / 8
            let expectedUploadBytes = textureBinding.width * textureBinding.height * 4
            guard payload.sourceFormat == textureBinding.sourceFormat,
                  payload.width == textureBinding.width,
                  payload.height == textureBinding.height,
                  payload.sourceByteCount == expectedSourceBytes,
                  payload.uploadByteCount == expectedUploadBytes else {
                throw SM64MarioFaceTextureUploadAdmissionError.payloadMismatch(
                    textureID: payload.textureID, reason: "format_or_dimensions"
                )
            }
            guard payload.uploadByteCount == UInt32(payload.rgba8Pixels.count) else {
                throw SM64MarioFaceTextureUploadAdmissionError.payloadMismatch(
                    textureID: payload.textureID, reason: "upload_byte_count"
                )
            }
            guard !payload.rgba8Pixels.isEmpty else {
                throw SM64MarioFaceTextureUploadAdmissionError.emptyPayload(
                    textureID: payload.textureID
                )
            }
            let entry = SM64MarioFaceTextureUploadEntry(
                textureID: payload.textureID,
                generation: generation,
                width: payload.width,
                height: payload.height,
                sourceFormat: payload.sourceFormat,
                sourceByteCount: payload.sourceByteCount,
                uploadByteCount: payload.uploadByteCount,
                sourcePixelFingerprint: payload.sourcePixelFingerprint,
                uploadPixelFingerprint: payload.uploadPixelFingerprint,
                rgba8Pixels: payload.rgba8Pixels,
                samplerPacked: textureBinding.sampler.packed,
                usageFlags: textureBinding.usageFlags,
                storageMode: textureBinding.storageMode,
                residencyScope: textureBinding.residencyScope,
                encoderDomains: textureBinding.encoderDomains
            )
            entries.append(entry)
            sourceBytes += payload.sourceByteCount
            uploadBytes += payload.uploadByteCount
        }

        let fingerprint = SM64MarioFaceTextureUploadPlanFingerprint.plan(
            routeID: routeID,
            ownerToken: ownerToken,
            resourceFingerprint: binding.resourceFingerprint,
            bindingFingerprint: binding.bindingFingerprint,
            entries: entries,
            sourceByteCount: sourceBytes,
            uploadByteCount: uploadBytes
        )
        return SM64MarioFaceTextureUploadPlan(
            route: binding.route,
            ownerToken: ownerToken,
            resourceFingerprint: binding.resourceFingerprint,
            bindingFingerprint: binding.bindingFingerprint,
            entries: entries,
            sourceByteCount: sourceBytes,
            uploadByteCount: uploadBytes,
            fingerprint: fingerprint
        )
    }
}

enum SM64MarioFaceTextureUploadPlanFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func plan(
        routeID: SM64MarioFaceGoddardRouteID,
        ownerToken: UInt64,
        resourceFingerprint: UInt64,
        bindingFingerprint: UInt64,
        entries: [SM64MarioFaceTextureUploadEntry],
        sourceByteCount: UInt32,
        uploadByteCount: UInt32
    ) -> UInt64 {
        var result = offset
        result = update(result, UInt64(routeID.rawValue))
        result = update(result, ownerToken)
        result = update(result, resourceFingerprint)
        result = update(result, bindingFingerprint)
        result = update(result, UInt64(entries.count))
        result = update(result, UInt64(sourceByteCount))
        result = update(result, UInt64(uploadByteCount))
        for entry in entries {
            result = update(result, UInt64(entry.textureID))
            result = update(result, entry.generation)
            result = update(result, UInt64(entry.width))
            result = update(result, UInt64(entry.height))
            result = update(result, UInt64(entry.sourceFormat.rawValue))
            result = update(result, UInt64(entry.sourceByteCount))
            result = update(result, UInt64(entry.uploadByteCount))
            result = update(result, entry.sourcePixelFingerprint)
            result = update(result, entry.uploadPixelFingerprint)
            result = update(result, UInt64(entry.samplerPacked))
            result = update(result, UInt64(entry.policyCode))
        }
        return result
    }

    private static func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xff
            result &*= prime
        }
        return result
    }
}

/// Schema-4 records for the owner-thread upload admission.  These records
/// end at the staging/residency-pending boundary; no private Metal handle is
/// represented until a later milestone binds the face draw.
enum SM64MarioFaceTextureUploadOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let headerRecordBase: UInt64 = 0x4d46_5f00
    static let textureRecordBase: UInt64 = 0x4d46_6000

    static func records(
        plan: SM64MarioFaceTextureUploadPlan,
        receipt: SM64MarioFaceTextureUploadReceipt,
        simulationTick: UInt64,
        sequenceStart: UInt32 = 0
    ) throws -> [SM64OracleTraceRecord] {
        let subject = UInt64(plan.route.routeID.rawValue)
        var sequence = sequenceStart
        var records = [try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: subject, recordID: headerRecordBase | subject, sequence: sequence,
            values: [
                subject, UInt64(receipt.admittedEntries), UInt64(receipt.sourceByteCount),
                UInt64(receipt.uploadByteCount), receipt.firstGeneration,
                receipt.lastGeneration, plan.bindingFingerprint, receipt.planFingerprint,
            ]
        )]
        sequence &+= 1
        for entry in plan.entries {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: subject,
                recordID: textureRecordBase | UInt64(entry.textureID), sequence: sequence,
                values: [
                    UInt64(entry.textureID), entry.generation, UInt64(entry.width),
                    UInt64(entry.height), UInt64(entry.uploadByteCount),
                    entry.uploadPixelFingerprint, UInt64(entry.policyCode),
                    receipt.residencyPending ? 1 : 0,
                ]
            ))
            sequence &+= 1
        }
        return records
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        var result = SM64OracleTraceHash.offset
        result = update(result, UInt64(records.count))
        for record in records { result = update(result, record.canonicalHash) }
        return result
    }

    private static func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xff
            result &*= SM64OracleTraceHash.prime
        }
        return result
    }
}
