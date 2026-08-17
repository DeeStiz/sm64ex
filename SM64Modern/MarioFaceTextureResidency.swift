import Foundation

enum SM64MarioFaceTextureResidencyError: Error, Equatable, LocalizedError {
    case countMismatch(expected: Int, actual: Int)
    case orderMismatch(index: Int, expected: UInt32, actual: UInt32)
    case generationMismatch(textureID: UInt32, expected: UInt64, actual: UInt64)
    case residencyNotCommitted
    case residencyNotRequested

    var errorDescription: String? {
        switch self {
        case let .countMismatch(expected, actual):
            return "Mario-face residency count mismatch expected=\(expected) actual=\(actual)"
        case let .orderMismatch(index, expected, actual):
            return "Mario-face residency order mismatch index=\(index) expected=\(expected) actual=\(actual)"
        case let .generationMismatch(textureID, expected, actual):
            return "Mario-face residency generation mismatch texture=\(textureID) expected=\(expected) actual=\(actual)"
        case .residencyNotCommitted:
            return "Mario-face private textures were not committed to scene residency"
        case .residencyNotRequested:
            return "Mario-face scene residency was not requested before submission"
        }
    }
}

/// The explicit MTL4 synchronization contract used by the texture upload
/// preparation pass. Values describe the stage transitions, not SDK handles.
enum SM64MarioFaceTextureResidencyStages {
    static let blit: UInt32 = 1
    static let fragment: UInt32 = 2
    static let deviceVisibility: UInt32 = 1
}

struct SM64MarioFaceTextureResidencyReceipt: Equatable, Sendable {
    let route: SM64MarioFaceGoddardRouteID
    let ownerToken: UInt64
    let planFingerprint: UInt64
    let privateTextureCount: UInt32
    let firstGeneration: UInt64
    let lastGeneration: UInt64
    let sceneResidencyCommitted: Bool
    let sceneResidencyRequested: Bool
    let uploadOrder: [UInt32]
    let uploadGenerations: [UInt64]
    let producerAfterStages: UInt32
    let producerBeforeQueueStages: UInt32
    let producerVisibility: UInt32
    let consumerAfterQueueStages: UInt32
    let consumerBeforeStages: UInt32
    let consumerVisibility: UInt32
    let fingerprint: UInt64
}

enum SM64MarioFaceTextureResidencyReceiptBuilder {
    static func make(
        plan: SM64MarioFaceTextureUploadPlan,
        residentTextureIDs: [UInt32],
        residentGenerations: [UInt64],
        sceneResidencyCommitted: Bool,
        sceneResidencyRequested: Bool
    ) throws -> SM64MarioFaceTextureResidencyReceipt {
        guard sceneResidencyCommitted else {
            throw SM64MarioFaceTextureResidencyError.residencyNotCommitted
        }
        guard sceneResidencyRequested else {
            throw SM64MarioFaceTextureResidencyError.residencyNotRequested
        }
        guard residentTextureIDs.count == plan.entries.count,
              residentGenerations.count == plan.entries.count else {
            throw SM64MarioFaceTextureResidencyError.countMismatch(
                expected: plan.entries.count,
                actual: min(residentTextureIDs.count, residentGenerations.count)
            )
        }
        for index in plan.entries.indices {
            let expected = plan.entries[index]
            guard residentTextureIDs[index] == expected.textureID else {
                throw SM64MarioFaceTextureResidencyError.orderMismatch(
                    index: index, expected: expected.textureID, actual: residentTextureIDs[index]
                )
            }
            guard residentGenerations[index] == expected.generation else {
                throw SM64MarioFaceTextureResidencyError.generationMismatch(
                    textureID: expected.textureID,
                    expected: expected.generation,
                    actual: residentGenerations[index]
                )
            }
        }

        let producerAfter = SM64MarioFaceTextureResidencyStages.blit
        let producerBeforeQueue = SM64MarioFaceTextureResidencyStages.fragment
        let producerVisibility = SM64MarioFaceTextureResidencyStages.deviceVisibility
        let consumerAfterQueue = SM64MarioFaceTextureResidencyStages.blit
        let consumerBefore = SM64MarioFaceTextureResidencyStages.fragment
        let consumerVisibility = SM64MarioFaceTextureResidencyStages.deviceVisibility
        let fingerprint = SM64MarioFaceTextureResidencyFingerprint.receipt(
            plan: plan,
            residentTextureIDs: residentTextureIDs,
            residentGenerations: residentGenerations,
            sceneResidencyCommitted: sceneResidencyCommitted,
            sceneResidencyRequested: sceneResidencyRequested,
            producerAfterStages: producerAfter,
            producerBeforeQueueStages: producerBeforeQueue,
            producerVisibility: producerVisibility,
            consumerAfterQueueStages: consumerAfterQueue,
            consumerBeforeStages: consumerBefore,
            consumerVisibility: consumerVisibility
        )
        return SM64MarioFaceTextureResidencyReceipt(
            route: plan.route.routeID,
            ownerToken: plan.ownerToken,
            planFingerprint: plan.fingerprint,
            privateTextureCount: UInt32(plan.entries.count),
            firstGeneration: plan.firstGeneration,
            lastGeneration: plan.lastGeneration,
            sceneResidencyCommitted: sceneResidencyCommitted,
            sceneResidencyRequested: sceneResidencyRequested,
            uploadOrder: residentTextureIDs,
            uploadGenerations: residentGenerations,
            producerAfterStages: producerAfter,
            producerBeforeQueueStages: producerBeforeQueue,
            producerVisibility: producerVisibility,
            consumerAfterQueueStages: consumerAfterQueue,
            consumerBeforeStages: consumerBefore,
            consumerVisibility: consumerVisibility,
            fingerprint: fingerprint
        )
    }
}

enum SM64MarioFaceTextureResidencyFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func receipt(
        plan: SM64MarioFaceTextureUploadPlan,
        residentTextureIDs: [UInt32],
        residentGenerations: [UInt64],
        sceneResidencyCommitted: Bool,
        sceneResidencyRequested: Bool,
        producerAfterStages: UInt32,
        producerBeforeQueueStages: UInt32,
        producerVisibility: UInt32,
        consumerAfterQueueStages: UInt32,
        consumerBeforeStages: UInt32,
        consumerVisibility: UInt32
    ) -> UInt64 {
        var result = offset
        result = update(result, UInt64(plan.route.routeID.rawValue))
        result = update(result, plan.ownerToken)
        result = update(result, plan.fingerprint)
        result = update(result, UInt64(residentTextureIDs.count))
        result = update(result, plan.firstGeneration)
        result = update(result, plan.lastGeneration)
        result = update(result, sceneResidencyCommitted ? 1 : 0)
        result = update(result, sceneResidencyRequested ? 1 : 0)
        result = update(result, UInt64(producerAfterStages))
        result = update(result, UInt64(producerBeforeQueueStages))
        result = update(result, UInt64(producerVisibility))
        result = update(result, UInt64(consumerAfterQueueStages))
        result = update(result, UInt64(consumerBeforeStages))
        result = update(result, UInt64(consumerVisibility))
        for index in residentTextureIDs.indices {
            result = update(result, UInt64(residentTextureIDs[index]))
            result = update(result, residentGenerations[index])
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

/// Schema-4 records for private-residency and upload/fragment barrier order.
enum SM64MarioFaceTextureResidencyOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let headerRecordBase: UInt64 = 0x4d46_6100
    static let textureRecordBase: UInt64 = 0x4d46_7000

    static func records(
        receipt: SM64MarioFaceTextureResidencyReceipt,
        simulationTick: UInt64,
        sequenceStart: UInt32 = 0
    ) throws -> [SM64OracleTraceRecord] {
        let subject = UInt64(receipt.route.rawValue)
        var sequence = sequenceStart
        var records = [try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: subject, recordID: headerRecordBase | subject, sequence: sequence,
            values: [
                subject, UInt64(receipt.privateTextureCount), receipt.firstGeneration,
                receipt.lastGeneration, receipt.sceneResidencyCommitted ? 1 : 0,
                receipt.sceneResidencyRequested ? 1 : 0, receipt.planFingerprint,
                receipt.fingerprint,
            ]
        )]
        sequence &+= 1
        for index in receipt.uploadOrder.indices {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: subject,
                recordID: textureRecordBase | UInt64(receipt.uploadOrder[index]), sequence: sequence,
                values: [
                    UInt64(receipt.uploadOrder[index]), receipt.uploadGenerations[index],
                    UInt64(receipt.producerAfterStages), UInt64(receipt.producerBeforeQueueStages),
                    UInt64(receipt.producerVisibility), UInt64(receipt.consumerAfterQueueStages),
                    UInt64(receipt.consumerBeforeStages), UInt64(receipt.consumerVisibility),
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
