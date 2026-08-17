import Foundation

@main
struct SM64ModernRenderPacketCaptureSmoke {
    static func main() {
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
        capture.finish(renderStatus: 0, batchStatus: 0)

        guard let packet = capture.packet() else {
            preconditionFailure("render packet missing")
        }
        precondition(packet.sequence == 1)
        precondition(packet.events.count == 3)
        precondition(packet.events[0].kind == SM64RenderPacketEventKind.frameBegin)
        precondition(packet.events[1].kind == SM64RenderPacketEventKind.draw)
        precondition(packet.events[2].kind == SM64RenderPacketEventKind.frameEnd)
        precondition(packet.events[0].values == [2, 2, 0, 1, 1])
        precondition(packet.events[1].values[0] == 17)
        precondition(packet.events[1].values[1] == 6)
        precondition(packet.events[1].values[2] == 1)
        precondition(packet.events[1].values[4] == 0)
        precondition(packet.events[1].values[5] == 1)
        precondition(packet.events[1].values[6] == 0x8000_0021)
        precondition(packet.events[2].values == [2, 2, 0, 1, 1])

        let summary = capture.summary()
        precondition(summary.frames == 1)
        precondition(summary.draws == 1)
        precondition(summary.latestFingerprint == packet.fingerprint)
        precondition(summary.finishFingerprint != 0)
        print("renderFrameFingerprint=0x\(String(packet.fingerprint, radix: 16))")
        print("renderFinishFingerprint=0x\(String(summary.finishFingerprint, radix: 16))")
        print("SM64 Modern render packet capture smoke passed")
    }
}
