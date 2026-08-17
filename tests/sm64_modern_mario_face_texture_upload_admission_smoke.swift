import Foundation

@main
struct SM64ModernMarioFaceTextureUploadAdmissionSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceTextureUploadAdmissionSmoke", code: 1)
        }
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let traceURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let routeID: SM64MarioFaceGoddardRouteID = .marioNormal
        guard let route = SM64MarioFaceRouteResourceCatalog.route(routeID),
              let binding = SM64MarioFaceMetalBindingPacketBuilder.make(routeID: routeID) else {
            throw NSError(domain: "MarioFaceTextureUploadAdmissionSmoke", code: 2)
        }
        let payloads = try SM64MarioFaceTextureProvider.load(route: route, rootURL: rootURL)
        let ownerToken: UInt64 = 0x5eed
        let plan = try SM64MarioFaceTextureUploadPlanBuilder.make(
            ownerToken: ownerToken,
            expectedOwnerToken: ownerToken,
            routeID: routeID,
            binding: binding,
            payloads: payloads
        )
        let receipt = plan.receipt()
        precondition(plan.entries.map(\.textureID) == [1, 2, 0x300])
        precondition(receipt.admittedEntries == 3)
        precondition(receipt.sourceByteCount == 5120)
        precondition(receipt.uploadByteCount == 12288)
        precondition(receipt.firstGeneration == 1 && receipt.lastGeneration == 3)
        precondition(receipt.pendingResidencyCount == 3 && receipt.residencyPending)
        do {
            _ = try SM64MarioFaceTextureUploadPlanBuilder.make(
                ownerToken: ownerToken + 1,
                expectedOwnerToken: ownerToken,
                routeID: routeID,
                binding: binding,
                payloads: payloads
            )
            preconditionFailure("owner mismatch must be rejected")
        } catch let error as SM64MarioFaceTextureUploadAdmissionError {
            precondition(error == .ownerMismatch(expected: ownerToken, actual: ownerToken + 1))
        }

        let records = try SM64MarioFaceTextureUploadOracle.records(
            plan: plan, receipt: receipt, simulationTick: 1
        )
        precondition(records.count == 4)
        precondition(records.map(\.recordID) == [
            0x4d46_5f02, 0x4d46_6001, 0x4d46_6002, 0x4d46_6300,
        ])
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)

        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1201,
            contentFingerprint: 0x4d30_1202,
            timebaseFingerprint: 0x4d30_1203,
            configurationFingerprint: 0x4d30_1204,
            initialSaveFingerprint: 0x4d30_1205,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: traceURL)

        print("marioFaceTextureUploadAdmissionRoute=\(routeID.rawValue)")
        print("marioFaceTextureUploadAdmissionEntries=\(receipt.admittedEntries)")
        print("marioFaceTextureUploadAdmissionSourceBytes=\(receipt.sourceByteCount)")
        print("marioFaceTextureUploadAdmissionUploadBytes=\(receipt.uploadByteCount)")
        print("marioFaceTextureUploadAdmissionPendingResidency=\(receipt.pendingResidencyCount)")
        print(String(format: "marioFaceTextureUploadAdmissionPlanFingerprint=0x%016llx", plan.fingerprint))
        print(String(format: "marioFaceTextureUploadAdmissionTraceFingerprint=0x%016llx", SM64MarioFaceTextureUploadOracle.fingerprint(records)))
        print("SM64 Modern Mario-face texture upload admission Swift trace passed path=\(traceURL.path)")
    }
}
