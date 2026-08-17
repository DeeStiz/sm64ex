import Foundation

@main
struct SM64ModernRenderTraceAdapterSmoke {
    static func main() throws {
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
        capture.startFrame()
        let vertices: [Float] = [1, -2, 3, 4, 5, 6]
        vertices.withUnsafeBufferPointer { buffer in
            capture.draw(
                shaderID: UInt32.max,
                vertices: buffer.baseAddress,
                floatCount: UInt32(buffer.count),
                triangleCount: 1
            )
        }
        capture.endFrame()
        guard let packet = capture.packet() else { preconditionFailure("packet missing") }

        let records = try SM64RenderOracleTraceAdapter.records(packet: packet, simulationTick: 42)
        precondition(records.count == 3)
        precondition(records.allSatisfy { $0.domain == 11 && $0.recordKind == 7 })
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)
        precondition(SM64RenderOracleTraceAdapter.compare(expected: records, actual: roundTrip).matched)

        var mutated = records
        mutated[1].values[0] &+= 1
        let divergence = SM64RenderOracleTraceAdapter.compare(expected: records, actual: mutated)
        precondition(!divergence.matched)
        precondition(divergence.firstDivergence == 1)

        let fingerprint = SM64RenderOracleTraceAdapter.fingerprint(records)
        print("renderTraceFingerprint=0x\(String(fingerprint, radix: 16))")
        print("renderTraceDivergence=\(divergence.firstDivergence ?? -1)")
        print("SM64 Modern render trace adapter smoke passed")
    }
}
