import Foundation

enum SM64MarioFaceTexturePayloadOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let headerRecordBase: UInt64 = 0x4d46_5d00
    static let textureRecordBase: UInt64 = 0x4d46_5e00
    static let formatRevision: UInt64 = 1

    static func routeFingerprint(
        route: SM64MarioFaceRouteRecord,
        payloads: [SM64MarioFaceTexturePayload]
    ) -> UInt64 {
        var result = SM64OracleTraceHash.offset
        result = update(result, UInt64(route.routeID.rawValue))
        result = update(result, UInt64(payloads.count))
        result = update(result, UInt64(payloads.reduce(0) { $0 + $1.sourceByteCount }))
        result = update(result, UInt64(payloads.reduce(0) { $0 + $1.uploadByteCount }))
        for payload in payloads {
            result = update(result, UInt64(payload.textureID))
            result = update(result, UInt64(payload.sourceFormat.rawValue))
            result = update(result, UInt64(payload.sourceByteCount))
            result = update(result, UInt64(payload.uploadByteCount))
            result = update(result, UInt64(payload.width))
            result = update(result, UInt64(payload.height))
            result = update(result, payload.sourcePixelFingerprint)
            result = update(result, payload.uploadPixelFingerprint)
        }
        return result
    }

    static func records(
        route: SM64MarioFaceRouteRecord,
        payloads: [SM64MarioFaceTexturePayload],
        binding: SM64MarioFaceMetalBindingPacket,
        simulationTick: UInt64,
        sequenceStart: UInt32 = 0
    ) throws -> [SM64OracleTraceRecord] {
        let subject = UInt64(route.routeID.rawValue)
        let sourceBytes = payloads.reduce(0) { $0 + $1.sourceByteCount }
        let uploadBytes = payloads.reduce(0) { $0 + $1.uploadByteCount }
        let routeHash = routeFingerprint(route: route, payloads: payloads)
        var sequence = sequenceStart
        var records = [try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: subject, recordID: headerRecordBase | subject, sequence: sequence,
            values: [
                subject, UInt64(payloads.count), UInt64(sourceBytes), UInt64(uploadBytes),
                routeHash, binding.resourceFingerprint, binding.bindingFingerprint,
                formatRevision,
            ]
        )]
        sequence &+= 1
        for payload in payloads {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: subject,
                recordID: textureRecordBase | UInt64(payload.textureID), sequence: sequence,
                values: [
                    UInt64(payload.textureID), UInt64(payload.sourceFormat.rawValue),
                    UInt64(payload.sourceByteCount), UInt64(payload.uploadByteCount),
                    UInt64(payload.width), UInt64(payload.height),
                    payload.sourcePixelFingerprint, payload.uploadPixelFingerprint,
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
