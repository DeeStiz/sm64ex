import Foundation

typealias SM64ModernStatus = Int32
typealias SM64ModernExitReason = Int32

@main
struct SM64ModernLiveRouteOracleSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 || CommandLine.arguments.count == 3 else {
            throw NSError(domain: "SM64ModernLiveRouteOracleSmoke", code: 1)
        }
        let inputOnly = CommandLine.arguments.count == 3
            && CommandLine.arguments[2] == "--input-only"
        guard CommandLine.arguments.count < 3 || inputOnly else {
            throw NSError(domain: "SM64ModernLiveRouteOracleSmoke", code: 2)
        }
        let context = SM64ModernSwiftEngineContext()
        precondition(context.initialize(levelNumber: 1, areaIndex: 0))
        _ = context.ingestInput(
            .init(buttons: 0x0001, rawStickX: 16, rawStickY: 0),
            advanceLegacyDomain: false
        )
        if !inputOnly {
            _ = context.ingestInput(
                .init(buttons: 0x0001, rawStickX: 16, rawStickY: 0),
                advanceLegacyDomain: true
            )
            _ = context.ingestInput(
                .init(buttons: 0x8000, rawStickX: 38),
                advanceLegacyDomain: true
            )
            _ = context.updateMarioInput(
                squishTimer: 0,
                faceYaw: 0x1111,
                cameraYaw: 0x0200
            )
            _ = context.resolveIdleAction()
            _ = context.applyProgression(.collectRedCoin, simulationTick: 0)
            let actor = try context.state.spawnObject(in: .generalActor, behaviorIdentity: 0x44)
            precondition(context.state.objects.contains(actor))
            _ = context.step()
        }

        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d33_c001,
            contentFingerprint: 0x4d33_c002,
            timebaseFingerprint: 0x4d33_c003,
            configurationFingerprint: 0x4d33_c004,
            initialSaveFingerprint: 0x4d33_c005,
            coverageFingerprint: 0
        )
        // EngineHost forwards each Swift receipt through one C sidecar tick.
        // Normalize the internal receipt sequence/tick to that ABI boundary
        // before asking the C oracle to replay the file.
        let sidecarRecords = try context.traceRecords.enumerated().map { index, record in
            try SM64OracleTraceRecord(
                simulationTick: UInt64(index + 1),
                domain: record.domain,
                recordKind: record.recordKind,
                subjectID: record.subjectID,
                recordID: record.recordID,
                sequence: 0,
                flags: record.flags,
                values: record.values
            )
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        try SM64OracleTraceFile.write(
            configuration: configuration,
            records: sidecarRecords,
            to: output
        )
        print("SM64 Modern live route Swift trace passed records=\(sidecarRecords.count) mode=\(inputOnly ? "input-only" : "full") path=\(output.path)")
        for record in sidecarRecords {
            let values = record.values.map { String(format: "0x%016llx", $0) }.joined(separator: ",")
            print(
                "record tick=\(record.simulationTick) domain=\(record.domain) kind=\(record.recordKind) subject=\(String(format: "0x%016llx", record.subjectID)) record=\(String(format: "0x%016llx", record.recordID)) sequence=\(record.sequence) flags=\(record.flags) values=[\(values)] hash=\(String(format: "0x%016llx", record.canonicalHash))"
            )
        }
    }
}
