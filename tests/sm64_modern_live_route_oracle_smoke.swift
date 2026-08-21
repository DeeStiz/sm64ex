import Foundation

typealias SM64ModernStatus = Int32
typealias SM64ModernExitReason = Int32

private let pairingFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let pairingFNVPrime: UInt64 = 1_099_511_628_211
private let pairingRouteShardID: UInt64 = 0xd9446dfe_d10e189e
private let pairingRouteInputSeed: UInt64 = 0x2029a018_ec09ef5a
private let pairingRouteSaveSeed: UInt64 = 0x4736724b_767444c3

private func hashU64(_ startingHash: UInt64, _ value: UInt64) -> UInt64 {
    (0..<8).reduce(startingHash) { hash, byte in
        (hash ^ ((value >> UInt64(byte * 8)) & 0xff)) &* pairingFNVPrime
    }
}

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(pairingFNVOffset) { hash, byte in
        (hash ^ UInt64(byte)) &* pairingFNVPrime
    }
}

private func pairingRouteCoverageFingerprint(
    from records: [SM64OracleTraceRecord]
) -> UInt64 {
    let observedRecordIDs = Set(
        records
            .filter { $0.domain == 1 && $0.recordID == 1 }
            .map(\.recordID)
    ).sorted()
    guard !observedRecordIDs.isEmpty else { return 0 }
    var hash = pairingFNVOffset
    for recordID in observedRecordIDs {
        hash = hashU64(hash, 1)
        hash = hashU64(hash, 0)
        hash = hashU64(hash, recordID)
    }
    return hashU64(hash, UInt64(observedRecordIDs.count))
}

private func pairingRouteConfiguration(
    coverageFingerprint: UInt64
) -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashU64(pairingFNVOffset, pairingRouteShardID),
        contentFingerprint: hashU64(pairingFNVOffset, pairingRouteInputSeed),
        timebaseFingerprint: [UInt32(3), 60, 1, 30, 1, 2, 2]
            .reduce(pairingFNVOffset) { hash, value in
                (0..<4).reduce(hash) { next, byte in
                    (next ^ UInt64((value >> UInt32(byte * 8)) & 0xff)) &* pairingFNVPrime
                }
            },
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "shard=0xd9446dfed10e189e"
        ),
        initialSaveFingerprint: hashU64(pairingFNVOffset, pairingRouteSaveSeed),
        coverageFingerprint: coverageFingerprint
    )
}

private func pairingRouteRecord(
    from receipt: SM64ModernSwiftInputReceipt,
    simulationTick: UInt64
) throws -> SM64OracleTraceRecord {
    // This is the schema-4 C input receipt: raw button mask plus packed raw
    // axes. It is emitted from the real Swift input normalizer, not from the
    // one-record C/Swift contract probe.
    let controller = receipt.controller
    let packedAxes = UInt64(UInt8(truncatingIfNeeded: controller.rawStickX))
        | (UInt64(UInt8(truncatingIfNeeded: controller.rawStickY)) << 8)
        | (UInt64(UInt8(truncatingIfNeeded: controller.extStickX)) << 16)
        | (UInt64(UInt8(truncatingIfNeeded: controller.extStickY)) << 24)
    return try SM64OracleTraceRecord(
        simulationTick: simulationTick,
        domain: 1,
        recordKind: 2,
        recordID: 1,
        sequence: 0,
        values: [UInt64(controller.buttonDown), packedAxes]
    )
}

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
        let pairingRoute = ProcessInfo.processInfo.environment[
            "SM64_MODERN_PAIRING_ROUTE"
        ] == "1"
        let context = SM64ModernSwiftEngineContext()
        precondition(context.initialize(levelNumber: 1, areaIndex: 0))
        let routeSample = SM64ControllerRawSample(
            buttons: pairingRoute ? 0x8000 : 0x0001,
            rawStickX: 16,
            rawStickY: 0
        )
        guard let firstInput = context.ingestInput(
            routeSample,
            advanceLegacyDomain: false
        ) else {
            throw NSError(domain: "SM64ModernLiveRouteOracleSmoke", code: 4)
        }
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

        // EngineHost forwards each Swift receipt through one C sidecar tick.
        // Normalize the internal receipt sequence/tick to that ABI boundary
        // before asking the C oracle to replay the file.
        var sidecarRecords: [SM64OracleTraceRecord]
        if pairingRoute && inputOnly {
            sidecarRecords = [try pairingRouteRecord(from: firstInput, simulationTick: 2)]
            _ = context.step()
            guard let secondInput = context.ingestInput(
                routeSample,
                advanceLegacyDomain: false
            ) else {
                throw NSError(domain: "SM64ModernLiveRouteOracleSmoke", code: 5)
            }
            sidecarRecords.append(try pairingRouteRecord(
                from: secondInput,
                simulationTick: 3
            ))
        } else {
            sidecarRecords = try context.traceRecords.enumerated().map { index, record in
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
            if pairingRoute {
                sidecarRecords.append(try pairingRouteRecord(
                    from: firstInput,
                    simulationTick: UInt64(sidecarRecords.count + 1)
                ))
            }
        }
        if !inputOnly {
            guard let route = SM64MarioFaceRouteResourceCatalog.route(.marioNormal) else {
                throw NSError(domain: "SM64ModernLiveRouteOracleSmoke", code: 3)
            }
            sidecarRecords.append(try SM64MarioFaceRouteRenderOracle.liveCRecord(
                route: route,
                simulationTick: UInt64(sidecarRecords.count + 1),
                sequence: 0
            ))
        }
        let configuration = pairingRoute
            ? pairingRouteConfiguration(
                coverageFingerprint: pairingRouteCoverageFingerprint(from: sidecarRecords)
            )
            : SM64OracleTraceConfiguration(
                regionCode: 0x5553,
                mode: .record,
                buildFingerprint: 0x4d33_c001,
                contentFingerprint: 0x4d33_c002,
                timebaseFingerprint: 0x4d33_c003,
                configurationFingerprint: 0x4d33_c004,
                initialSaveFingerprint: 0x4d33_c005,
                coverageFingerprint: 0
            )
        if pairingRoute {
            guard configuration.coverageFingerprint != 0 else {
                throw NSError(domain: "SM64ModernLiveRouteOracleSmoke", code: 6)
            }
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
