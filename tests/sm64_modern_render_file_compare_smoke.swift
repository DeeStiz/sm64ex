import Foundation

private func makeFixtureCapture() throws -> SM64RenderFramePacket {
    let capture = SM64DisplayListRenderCapture(batchInstalled: true)
    capture.registerShader()
    capture.registerShader()
    capture.selectShader(17)
    capture.createTexture(id: 0)
    capture.createTexture(id: 1)
    capture.selectTexture(tile: 0, id: 0)
    capture.selectTexture(tile: 1, id: 1)
    capture.setViewport(x: -2, y: 3, width: 640, height: 480)
    capture.setScissor(x: 1, y: 4, width: 632, height: 470)
    let vertices: [Float] = [1, -2, 3, 4, 5, 6]
    for _ in 0..<2 {
        capture.startFrame()
        vertices.withUnsafeBufferPointer { buffer in
            capture.draw(
                shaderID: UInt32.max,
                vertices: buffer.baseAddress,
                floatCount: UInt32(buffer.count),
                triangleCount: 1
            )
        }
        capture.endFrame()
        capture.finish(renderStatus: 0, batchStatus: 0)
    }
    guard let packet = capture.packet() else {
        throw SM64RenderPacketFileError.truncated
    }
    return packet
}

private func latestRenderFrame(
    from records: [SM64OracleTraceRecord]
) -> [SM64OracleTraceRecord] {
    var current: [SM64OracleTraceRecord] = []
    var latest: [SM64OracleTraceRecord] = []
    for record in records where record.domain == SM64RenderOracleTraceAdapter.domain
        && record.recordKind == SM64RenderOracleTraceAdapter.recordKind {
        if record.recordID == UInt64(SM64RenderPacketEventKind.frameBegin) {
            current.removeAll(keepingCapacity: true)
        }
        current.append(record)
        if record.recordID == UInt64(SM64RenderPacketEventKind.frameEnd) {
            latest = current
        }
    }
    return latest
}

@main
struct SM64ModernRenderFileCompareSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.first == "--write-packet" {
            guard arguments.count == 2 else { throw SM64RenderPacketFileError.truncated }
            let packet = try makeFixtureCapture()
            try SM64RenderPacketFile.write(
                packet: packet,
                to: URL(fileURLWithPath: arguments[1]).standardizedFileURL
            )
            print("renderPacketFileWritten=\(packet.fingerprint)")
            return
        }

        guard arguments.count == 2 else { throw SM64RenderPacketFileError.truncated }
        let trace = try SM64OracleTraceFile.read(
            from: URL(fileURLWithPath: arguments[0]).standardizedFileURL
        )
        let packet = try SM64RenderPacketFile.read(
            from: URL(fileURLWithPath: arguments[1]).standardizedFileURL
        )
        let expected = latestRenderFrame(from: trace.records)
        guard !expected.isEmpty else { throw SM64RenderPacketFileError.truncated }
        let actual = try SM64RenderOracleTraceAdapter.records(
            packet: packet,
            simulationTick: expected[0].simulationTick
        )
        let comparison = SM64RenderOracleTraceAdapter.compare(
            expected: expected,
            actual: actual
        )
        guard comparison.matched else {
            print(
                "renderFileCompareFailed expected=\(comparison.expectedCount) actual=\(comparison.actualCount) first=\(comparison.firstDivergence ?? -1)"
            )
            throw SM64RenderPacketFileError.fingerprintMismatch
        }
        let fingerprint = SM64RenderOracleTraceAdapter.fingerprint(actual)
        print("renderFileCompareTick=\(expected[0].simulationTick)")
        print("renderFileCompareRecords=\(actual.count)")
        print("renderFileCompareFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern file-backed render comparison matched")
    }
}
