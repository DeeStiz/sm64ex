import Foundation

@main
struct SM64ModernMarioFaceTextureResidencySmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceTextureResidencySmoke", code: 1)
        }
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let traceURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let routeID: SM64MarioFaceGoddardRouteID = .marioNormal
        guard let route = SM64MarioFaceRouteResourceCatalog.route(routeID),
              let binding = SM64MarioFaceMetalBindingPacketBuilder.make(routeID: routeID) else {
            throw NSError(domain: "MarioFaceTextureResidencySmoke", code: 2)
        }
        let payloads = try SM64MarioFaceTextureProvider.load(route: route, rootURL: rootURL)
        let plan = try SM64MarioFaceTextureUploadPlanBuilder.make(
            ownerToken: 0x5eed,
            expectedOwnerToken: 0x5eed,
            routeID: routeID,
            binding: binding,
            payloads: payloads
        )
        let receipt = try SM64MarioFaceTextureResidencyReceiptBuilder.make(
            plan: plan,
            residentTextureIDs: [1, 2, 0x300],
            residentGenerations: [1, 2, 3],
            sceneResidencyCommitted: true,
            sceneResidencyRequested: true
        )
        precondition(receipt.privateTextureCount == 3)
        precondition(receipt.uploadOrder == [1, 2, 0x300])
        precondition(receipt.uploadGenerations == [1, 2, 3])
        precondition(receipt.producerAfterStages == 1)
        precondition(receipt.producerBeforeQueueStages == 2)
        precondition(receipt.consumerAfterQueueStages == 1)
        precondition(receipt.consumerBeforeStages == 2)
        precondition(receipt.producerVisibility == 1 && receipt.consumerVisibility == 1)
        do {
            _ = try SM64MarioFaceTextureResidencyReceiptBuilder.make(
                plan: plan,
                residentTextureIDs: [1, 0x300, 2],
                residentGenerations: [1, 2, 3],
                sceneResidencyCommitted: true,
                sceneResidencyRequested: true
            )
            preconditionFailure("residency order must be rejected")
        } catch let error as SM64MarioFaceTextureResidencyError {
            precondition(error == .orderMismatch(index: 1, expected: 2, actual: 0x300))
        }

        let records = try SM64MarioFaceTextureResidencyOracle.records(
            receipt: receipt, simulationTick: 1
        )
        precondition(records.count == 4)
        precondition(records.map(\.recordID) == [
            0x4d46_6102, 0x4d46_7001, 0x4d46_7002, 0x4d46_7300,
        ])
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)

        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1301,
            contentFingerprint: 0x4d30_1302,
            timebaseFingerprint: 0x4d30_1303,
            configurationFingerprint: 0x4d30_1304,
            initialSaveFingerprint: 0x4d30_1305,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: traceURL)

        print("marioFaceTextureResidencyRoute=\(receipt.route.rawValue)")
        print("marioFaceTextureResidencyPrivateTextures=\(receipt.privateTextureCount)")
        print("marioFaceTextureResidencyCommitted=\(receipt.sceneResidencyCommitted ? 1 : 0)")
        print("marioFaceTextureResidencyRequested=\(receipt.sceneResidencyRequested ? 1 : 0)")
        print(String(format: "marioFaceTextureResidencyPlanFingerprint=0x%016llx", receipt.planFingerprint))
        print(String(format: "marioFaceTextureResidencyReceiptFingerprint=0x%016llx", receipt.fingerprint))
        print(String(format: "marioFaceTextureResidencyTraceFingerprint=0x%016llx", SM64MarioFaceTextureResidencyOracle.fingerprint(records)))
        print("SM64 Modern Mario-face texture residency Swift trace passed path=\(traceURL.path)")
    }
}
