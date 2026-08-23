import Foundation

private let shardID: UInt64 = 0x6e6c_6a0f_c1b9_2a45
private let sourceID: UInt64 = 0x7377_6902_d632_09e9
private let ownerID: UInt64 = 0x4490_d0bf_72a4_dab6
private let staticSourceID: UInt64 = 0xd50f_8158_124e_9dd6
private let staticOwnerID: UInt64 = 0x57ee_a3c3_9811_e29f
private let routeFlags: UInt32 = 1 | 2 | 4
private let routeDomain: UInt32 = 6
private let routeKind: UInt32 = 3

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw SM64OracleTraceCodecError.invalidHeader }
    _ = message
}

private struct RouteReceipt {
    let record: SM64OracleTraceRecord
    let sourceSubject: UInt32
    let level: UInt32
    let area: UInt32
    let actionBefore: Int32
    let actionAfter: Int32
    let timer: UInt32
    let marioOnPlatform: Bool
    let soundPlayed: Bool
    let positionBefore: Float
    let positionAfter: Float
    let home: Float
    let velocityBefore: Float
    let velocityAfter: Float

    init(record: SM64OracleTraceRecord) throws {
        guard record.domain == routeDomain,
              record.recordKind == routeKind,
              record.subjectID == ownerID,
              record.recordID == sourceID,
              record.flags == routeFlags,
              record.values.count == 8 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let values = record.values
        sourceSubject = UInt32(truncatingIfNeeded: values[0])
        level = UInt32(truncatingIfNeeded: values[1])
        area = UInt32(truncatingIfNeeded: values[1] >> 32)
        actionBefore = Int32(bitPattern: UInt32(truncatingIfNeeded: values[2]))
        actionAfter = Int32(bitPattern: UInt32(truncatingIfNeeded: values[2] >> 32))
        timer = UInt32(truncatingIfNeeded: values[3])
        marioOnPlatform = ((values[3] >> 32) & 1) != 0
        soundPlayed = ((values[3] >> 33) & 1) != 0
        positionBefore = Float(bitPattern: UInt32(truncatingIfNeeded: values[4]))
        positionAfter = Float(bitPattern: UInt32(truncatingIfNeeded: values[5]))
        home = Float(bitPattern: UInt32(truncatingIfNeeded: values[6]))
        velocityBefore = Float(bitPattern: UInt32(truncatingIfNeeded: values[7]))
        velocityAfter = Float(bitPattern: UInt32(truncatingIfNeeded: values[7] >> 32))
        self.record = record
    }

    func normalizedRecord() throws -> SM64OracleTraceRecord {
        try SM64OracleTraceRecord(
            simulationTick: record.simulationTick,
            domain: record.domain,
            recordKind: record.recordKind,
            subjectID: record.subjectID,
            recordID: record.recordID,
            sequence: record.sequence,
            flags: record.flags,
            values: [
                UInt64(sourceSubject),
                UInt64(level) | (UInt64(area) << 32),
                UInt64(bitPattern: Int64(UInt32(bitPattern: actionBefore)))
                    | (UInt64(UInt32(bitPattern: actionAfter)) << 32),
                UInt64(timer)
                    | (marioOnPlatform ? UInt64(1) << 32 : 0)
                    | (soundPlayed ? UInt64(1) << 33 : 0),
                UInt64(positionBefore.bitPattern),
                UInt64(positionAfter.bitPattern),
                UInt64(home.bitPattern),
                UInt64(velocityBefore.bitPattern)
                    | (UInt64(velocityAfter.bitPattern) << 32),
            ]
        )
    }
}

private struct ReducerOutput {
    let action: Int32
    let position: Float
    let velocity: Float
    let sound: Bool
}

/* Independent value mirror of bhv_wdw_express_elevator_loop.  This copy does
 * not import the object bridge, spawn objects, inspect a pointer, or call a C
 * helper. */
private func reduce(
    action: Int32,
    timer: UInt32,
    position: Float,
    home: Float,
    marioOnPlatform: Bool
) -> ReducerOutput {
    var nextAction = action
    var nextPosition = position
    var nextVelocity: Float = 0
    var sound = false
    switch action {
    case 0:
        if marioOnPlatform { nextAction = 1 }
    case 1:
        nextVelocity = -20
        nextPosition += nextVelocity
        sound = true
        if timer > 132 { nextAction = 2 }
    case 2:
        if timer > 110 { nextAction = 3 }
    case 3:
        nextVelocity = 10
        nextPosition += nextVelocity
        sound = true
        if nextPosition >= home {
            nextPosition = home
            nextAction += 1
        }
    default:
        if !marioOnPlatform { nextAction = 0 }
    }
    return ReducerOutput(
        action: nextAction,
        position: nextPosition,
        velocity: nextVelocity,
        sound: sound
    )
}

private func selectedRecords(from records: [SM64OracleTraceRecord]) throws -> [RouteReceipt] {
    let selected = records.filter {
        $0.domain == routeDomain && $0.recordKind == routeKind
    }
    return try selected.map(RouteReceipt.init(record:))
}

private func validate(_ receipts: [RouteReceipt]) throws {
    try require(!receipts.isEmpty, "real source receipt required")
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for receipt in receipts {
        try require(receipt.level == 11 && receipt.area == 1, "WDW area-1 lifecycle")
        try require(receipt.sourceSubject != 0, "source object subject")
        try require(receipt.positionBefore.isFinite && receipt.positionAfter.isFinite, "finite position")
        try require(receipt.home.isFinite && receipt.velocityAfter.isFinite, "finite velocity")
        let output = reduce(
            action: receipt.actionBefore,
            timer: receipt.timer,
            position: receipt.positionBefore,
            home: receipt.home,
            marioOnPlatform: receipt.marioOnPlatform
        )
        try require(output.action == receipt.actionAfter, "action reducer")
        try require(output.position.bitPattern == receipt.positionAfter.bitPattern, "position reducer")
        try require(output.velocity.bitPattern == receipt.velocityAfter.bitPattern, "velocity reducer")
        try require(output.sound == receipt.soundPlayed, "source sound intent")
        if let lastTick {
            if receipt.record.simulationTick == lastTick {
                try require(receipt.record.sequence > lastSequence, "same-tick sequence")
            } else {
                try require(receipt.record.simulationTick > lastTick, "tick ordering")
            }
        }
        lastTick = receipt.record.simulationTick
        lastSequence = receipt.record.sequence
    }
}

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    let native = try SM64OracleTraceFile.read(from: cURL)
    let receipts = try selectedRecords(from: native.records)
    try validate(receipts)
    let records = try receipts.map { try $0.normalizedRecord() }
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: swiftURL
    )
    print(
        "swift_wdw_express_elevator_route_recorded shard=0x\(String(shardID, radix: 16)) "
            + "records=\(records.count) ticks=\(records.first?.simulationTick ?? 0),\(records.last?.simulationTick ?? 0) "
            + "source=0x\(String(sourceID, radix: 16)) owner=0x\(String(ownerID, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("wdw_express_elevator_single_artifact_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let cReceipts = try selectedRecords(from: cTrace.records)
    let swiftReceipts = try selectedRecords(from: swiftTrace.records)
    try validate(cReceipts)
    try validate(swiftReceipts)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if cReceipts.count != swiftReceipts.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "wdw_express_elevator_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) first_divergence=\(firstDivergence)"
    )
    try require(blockers.isEmpty, "exact C/Swift route pair")
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("wdw_express_elevator_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("wdw_express_elevator_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    let partialCount = 72 + SM64OracleTraceRecord.encodedSize
    try data.prefix(partialCount).write(to: output, options: .atomic)
    print("wdw_express_elevator_partial_written=1")
}

private func wrongSibling(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let receipts = try selectedRecords(from: native.records)
    try validate(receipts)
    guard let first = receipts.first else { throw SM64OracleTraceCodecError.truncated }
    let sibling = try SM64OracleTraceRecord(
        simulationTick: first.record.simulationTick,
        domain: first.record.domain,
        recordKind: first.record.recordKind,
        subjectID: staticOwnerID,
        recordID: staticSourceID,
        sequence: first.record.sequence,
        flags: first.record.flags & ~4,
        values: first.record.values
    )
    var records = native.records
    guard let index = records.firstIndex(of: first.record) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    records[index] = sibling
    try SM64OracleTraceFile.write(configuration: native.configuration, records: records, to: output)
    do {
        _ = try RouteReceipt(record: sibling)
        print("wdw_express_elevator_wrong_sibling_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.invalidHeader {
        print("wdw_express_elevator_wrong_sibling_rejected=1")
    }
}

@main
struct SM64ModernWdwElevatorRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
        switch mode {
        case "write":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "audit":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "tamper":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "partial":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try partial(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "wrong-sibling":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try wrongSibling(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
