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
    let events: [SM64RenderPacketEvent]
    let fingerprint: UInt64
}

struct SM64RenderPacketCaptureSummary: Equatable, Sendable {
    let frames: UInt64
    let draws: UInt64
    let latestFingerprint: UInt64
    let finishFingerprint: UInt64
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
        let events = frameEvents
        latestPacket = SM64RenderFramePacket(
            sequence: frameSequence,
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
