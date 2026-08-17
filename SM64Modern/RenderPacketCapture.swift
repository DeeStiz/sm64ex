import Foundation

struct SM64RenderCaptureRect: Equatable, Sendable {
    let x: Int32
    let y: Int32
    let width: Int32
    let height: Int32
}

struct SM64RenderPacketEvent: Equatable, Sendable {
    let kind: UInt32
    let values: [UInt64]
}

struct SM64RenderFramePacket: Equatable, Sendable {
    let sequence: UInt64
    let recordSequenceStart: UInt32
    let events: [SM64RenderPacketEvent]
    let fingerprint: UInt64
}

struct SM64RenderPacketCaptureSummary: Equatable, Sendable {
    let frames: UInt64
    let draws: UInt64
    let latestFingerprint: UInt64
    let finishFingerprint: UInt64
}

struct SM64RenderPacketTraceComparison: Equatable, Sendable {
    let matched: Bool
    let firstDivergence: Int?
    let expectedCount: Int
    let actualCount: Int
}

enum SM64RenderPacketFileError: Error, Equatable {
    case invalidMagic
    case unsupportedVersion(UInt32)
    case truncated
    case invalidEventCount(UInt32)
    case invalidValueCount(UInt32)
    case fingerprintMismatch
}

/// A small pointer-free sidecar used by the M29 file-backed comparison gate.
/// The file contains the most recently closed frame only; the C schema-4 trace
/// remains the authoritative sequence/tick stream. The write is opt-in and
/// bounded to one immutable frame, with no C or Metal pointer escaping.
enum SM64RenderPacketFile {
    private static let magic: UInt32 = 0x534D_5250 // "SMRP"
    private static let version: UInt32 = 1
    private static let maxEvents: UInt32 = 4_096

    static func write(packet: SM64RenderFramePacket, to url: URL) throws {
        guard packet.events.count <= Int(maxEvents) else {
            throw SM64RenderPacketFileError.invalidEventCount(UInt32(packet.events.count))
        }
        var data = Data(capacity: 28 + packet.events.count * 72)
        data.appendRenderLE(magic)
        data.appendRenderLE(version)
        data.appendRenderLE(packet.sequence)
        data.appendRenderLE(UInt32(packet.events.count))
        data.appendRenderLE(packet.recordSequenceStart)
        for event in packet.events {
            guard event.values.count <= 8 else {
                throw SM64RenderPacketFileError.invalidValueCount(UInt32(event.values.count))
            }
            data.appendRenderLE(event.kind)
            data.appendRenderLE(UInt32(event.values.count))
            for index in 0..<8 {
                data.appendRenderLE(index < event.values.count ? event.values[index] : 0)
            }
        }
        data.appendRenderLE(packet.fingerprint)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> SM64RenderFramePacket {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        var cursor = RenderPacketCursor(data)
        guard try cursor.readUInt32() == magic else {
            throw SM64RenderPacketFileError.invalidMagic
        }
        let fileVersion = try cursor.readUInt32()
        guard fileVersion == version else {
            throw SM64RenderPacketFileError.unsupportedVersion(fileVersion)
        }
        let sequence = try cursor.readUInt64()
        let eventCount = try cursor.readUInt32()
        let recordSequenceStart = try cursor.readUInt32()
        guard eventCount <= maxEvents else {
            throw SM64RenderPacketFileError.invalidEventCount(eventCount)
        }
        var events: [SM64RenderPacketEvent] = []
        events.reserveCapacity(Int(eventCount))
        for _ in 0..<eventCount {
            let kind = try cursor.readUInt32()
            let valueCount = try cursor.readUInt32()
            guard valueCount <= 8 else {
                throw SM64RenderPacketFileError.invalidValueCount(valueCount)
            }
            let values = try (0..<8).map { _ in try cursor.readUInt64() }
            events.append(SM64RenderPacketEvent(
                kind: kind,
                values: Array(values.prefix(Int(valueCount)))
            ))
        }
        let fingerprint = try cursor.readUInt64()
        guard cursor.isAtEnd else { throw SM64RenderPacketFileError.truncated }
        let packet = SM64RenderFramePacket(
            sequence: sequence,
            recordSequenceStart: recordSequenceStart,
            events: events,
            fingerprint: SM64RenderPacketFingerprint.frame(sequence: sequence, events: events)
        )
        guard packet.fingerprint == fingerprint else {
            throw SM64RenderPacketFileError.fingerprintMismatch
        }
        return packet
    }
}

private extension Data {
    mutating func appendRenderLE(_ value: UInt32) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }

    mutating func appendRenderLE(_ value: UInt64) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}

private struct RenderPacketCursor {
    private let data: Data
    private var offset = 0

    init(_ data: Data) { self.data = data }

    var isAtEnd: Bool { offset == data.count }

    mutating func readUInt32() throws -> UInt32 {
        let bytes = try read(4)
        return bytes.enumerated().reduce(UInt32(0)) { value, element in
            value | (UInt32(element.element) << UInt32(element.offset * 8))
        }
    }

    mutating func readUInt64() throws -> UInt64 {
        let bytes = try read(8)
        return bytes.enumerated().reduce(UInt64(0)) { value, element in
            value | (UInt64(element.element) << UInt64(element.offset * 8))
        }
    }

    private mutating func read(_ count: Int) throws -> [UInt8] {
        guard offset + count <= data.count else {
            throw SM64RenderPacketFileError.truncated
        }
        let start = data.index(data.startIndex, offsetBy: offset)
        let end = data.index(start, offsetBy: count)
        offset += count
        return Array(data[start..<end])
    }
}

enum SM64RenderOracleTraceAdapter {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 7

    static func records(
        packet: SM64RenderFramePacket,
        simulationTick: UInt64
    ) throws -> [SM64OracleTraceRecord] {
        try packet.events.enumerated().map { index, event in
            try SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: domain,
                recordKind: recordKind,
                recordID: UInt64(event.kind),
                sequence: packet.recordSequenceStart &+ UInt32(index),
                values: event.values
            )
        }
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        var hash = SM64OracleTraceHash.offset
        hash = update(hash, UInt64(records.count))
        for record in records {
            hash = update(hash, record.canonicalHash)
        }
        return hash
    }

    private static func update(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xff
            result &*= SM64RenderPacketFingerprint.prime
        }
        return result
    }

    static func compare(
        expected: [SM64OracleTraceRecord],
        actual: [SM64OracleTraceRecord]
    ) -> SM64RenderPacketTraceComparison {
        let sharedCount = min(expected.count, actual.count)
        for index in 0..<sharedCount where expected[index] != actual[index] {
            return SM64RenderPacketTraceComparison(
                matched: false,
                firstDivergence: index,
                expectedCount: expected.count,
                actualCount: actual.count
            )
        }
        let matched = expected.count == actual.count
        return SM64RenderPacketTraceComparison(
            matched: matched,
            firstDivergence: matched ? nil : sharedCount,
            expectedCount: expected.count,
            actualCount: actual.count
        )
    }
}

enum SM64RenderPacketEventKind {
    static let draw: UInt32 = 1
    static let frameBegin: UInt32 = 2
    static let frameEnd: UInt32 = 3
    static let finish: UInt32 = 4
}

struct SM64RenderPacketFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 24, by: 8) {
            result ^= UInt64((value >> UInt32(shift)) & 0xff)
            result &*= prime
        }
        return result
    }

    private static func hashU64(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xff
            result &*= prime
        }
        return result
    }

    static func event(_ event: SM64RenderPacketEvent) -> UInt64 {
        var hash = hashU32(offset, event.kind)
        hash = hashU32(hash, UInt32(event.values.count))
        for value in event.values {
            hash = hashU64(hash, value)
        }
        return hash
    }

    static func frame(sequence: UInt64, events: [SM64RenderPacketEvent]) -> UInt64 {
        var hash = hashU64(offset, sequence)
        hash = hashU32(hash, UInt32(events.count))
        for event in events {
            hash = hashU64(hash, self.event(event))
        }
        return hash
    }

    static func finish(_ values: [UInt64]) -> UInt64 {
        event(SM64RenderPacketEvent(kind: SM64RenderPacketEventKind.finish, values: values))
    }

    static func vertexHash(_ vertices: UnsafePointer<Float>?, floatCount: UInt32) -> UInt64 {
        guard let vertices else {
            return hashU32(offset, 0)
        }
        var hash = offset
        for index in 0..<Int(floatCount) {
            let bits = vertices[index].bitPattern
            hash = hashU32(hash, bits)
        }
        return hash
    }

    static func rectHash(_ rect: SM64RenderCaptureRect) -> UInt64 {
        var hash = offset
        hash = hashU32(hash, UInt32(bitPattern: rect.x))
        hash = hashU32(hash, UInt32(bitPattern: rect.y))
        hash = hashU32(hash, UInt32(bitPattern: rect.width))
        return hashU32(hash, UInt32(bitPattern: rect.height))
    }
}

/// Owner-thread render-oracle mirror. The C bridge records the same fixed
/// values in `sm64_modern_parity_record_render_packet`; this class computes
/// the candidate aggregate without retaining any C or Metal pointer.
final class SM64DisplayListRenderCapture {
    private let batchInstalled: Bool
    private var shaderProgramCount: UInt32 = 0
    private var nextTextureID: UInt32 = 0
    private var selectedTextureIDs = [UInt32](repeating: 0, count: 2)
    private var currentTextureTile: UInt32 = 0
    private var selectedShaderID: UInt32 = UInt32.max
    private var viewport = SM64RenderCaptureRect(x: 0, y: 0, width: 1, height: 1)
    private var scissor = SM64RenderCaptureRect(x: 0, y: 0, width: 1, height: 1)
    private var frameSequence: UInt64 = 1
    private var nextRecordSequence: UInt32 = 0
    private var frameRecordSequenceStart: UInt32 = 0
    private var frameEvents: [SM64RenderPacketEvent] = []
    private var latestPacket: SM64RenderFramePacket?
    private var frameCount: UInt64 = 0
    private var drawCount: UInt64 = 0
    private var latestFinishFingerprint: UInt64 = 0

    init(batchInstalled: Bool) {
        self.batchInstalled = batchInstalled
    }

    func registerShader() {
        shaderProgramCount &+= 1
    }

    func selectShader(_ id: UInt32) {
        selectedShaderID = id
    }

    func createTexture(id: UInt32) {
        let candidate = id == UInt32.max ? UInt32.max : id &+ 1
        nextTextureID = max(nextTextureID, candidate)
    }

    func selectTexture(tile: UInt32, id: UInt32) {
        guard tile < 2 else { return }
        currentTextureTile = tile
        selectedTextureIDs[Int(tile)] = id
    }

    func setViewport(x: Int32, y: Int32, width: Int32, height: Int32) {
        viewport = SM64RenderCaptureRect(x: x, y: y, width: width, height: height)
    }

    func setScissor(x: Int32, y: Int32, width: Int32, height: Int32) {
        scissor = SM64RenderCaptureRect(x: x, y: y, width: width, height: height)
    }

    func startFrame() {
        frameEvents.removeAll(keepingCapacity: true)
        frameRecordSequenceStart = nextRecordSequence
        frameEvents.append(SM64RenderPacketEvent(
            kind: SM64RenderPacketEventKind.frameBegin,
            values: [
                UInt64(shaderProgramCount),
                UInt64(nextTextureID),
                UInt64(selectedTextureIDs[0]),
                UInt64(selectedTextureIDs[1]),
                UInt64(currentTextureTile),
            ]
        ))
        nextRecordSequence &+= 1
    }

    func draw(
        shaderID: UInt32,
        vertices: UnsafePointer<Float>?,
        floatCount: UInt32,
        triangleCount: UInt32
    ) {
        let textureState = (currentTextureTile & 0x3)
            | (selectedTextureIDs[0] &<< 2)
            ^ (selectedTextureIDs[1] &<< 5)
        let stateBits = textureState | (batchInstalled ? 0x8000_0000 : 0)
        frameEvents.append(SM64RenderPacketEvent(
            kind: SM64RenderPacketEventKind.draw,
            values: [
                UInt64(shaderID == UInt32.max ? selectedShaderID : shaderID),
                UInt64(floatCount),
                UInt64(triangleCount),
                SM64RenderPacketFingerprint.vertexHash(vertices, floatCount: floatCount),
                UInt64(selectedTextureIDs[0]),
                UInt64(selectedTextureIDs[1]),
                UInt64(stateBits),
                SM64RenderPacketFingerprint.rectHash(viewport)
                    ^ SM64RenderPacketFingerprint.rectHash(scissor),
            ]
        ))
        nextRecordSequence &+= 1
        drawCount &+= 1
    }

    func endFrame() {
        frameEvents.append(SM64RenderPacketEvent(
            kind: SM64RenderPacketEventKind.frameEnd,
            values: [
                UInt64(shaderProgramCount),
                UInt64(nextTextureID),
                UInt64(selectedTextureIDs[0]),
                UInt64(selectedTextureIDs[1]),
                UInt64(currentTextureTile),
            ]
        ))
        nextRecordSequence &+= 1
        let events = frameEvents
        latestPacket = SM64RenderFramePacket(
            sequence: frameSequence,
            recordSequenceStart: frameRecordSequenceStart,
            events: events,
            fingerprint: SM64RenderPacketFingerprint.frame(sequence: frameSequence, events: events)
        )
        frameSequence &+= 1
        frameCount &+= 1
    }

    func finish(renderStatus: UInt32, batchStatus: UInt32) {
        latestFinishFingerprint = SM64RenderPacketFingerprint.finish([
            UInt64(renderStatus),
            UInt64(batchStatus),
            UInt64(shaderProgramCount),
            UInt64(nextTextureID),
        ])
        nextRecordSequence &+= 1
    }

    func packet() -> SM64RenderFramePacket? { latestPacket }

    func summary() -> SM64RenderPacketCaptureSummary {
        SM64RenderPacketCaptureSummary(
            frames: frameCount,
            draws: drawCount,
            latestFingerprint: latestPacket?.fingerprint ?? 0,
            finishFingerprint: latestFinishFingerprint
        )
    }
}
