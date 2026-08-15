import Foundation

// The production binding owns Metal objects and is intentionally covered by
// the native build. This isolated packet smoke supplies the narrow type needed
// to compile the value-semantic scene recorder under strict Swift 6 checking.
final class MetalTextureBinding: @unchecked Sendable {}

@main
struct SM64ModernMetalScenePacketSmoke {
    static func main() {
        let recorder = MetalSceneRecorder()
        recorder.registerShader(id: 7, filteringMode: 0, inputCount: 2, textureMask: 0)
        recorder.selectShader(7)

        let firstVertices: [Float] = [0, 0, 0, 1, 1, 0]
        recorder.startFrame(width: 32, height: 32)
        firstVertices.withUnsafeBufferPointer { buffer in
            precondition(recorder.append(
                vertices: buffer.baseAddress!,
                floatCount: UInt32(buffer.count),
                triangleCount: 1,
                textureBinding0: nil,
                textureBinding1: nil
            ))
        }
        recorder.endFrame()
        guard let firstPacket = recorder.latestPacket else {
            preconditionFailure("first packet missing")
        }
        precondition(firstPacket.sequence == 1)
        precondition(firstPacket.vertices == firstVertices)
        precondition(firstPacket.draws.count == 1)

        let secondVertices: [Float] = [2, 2, 2, 3, 3, 2]
        recorder.startFrame(width: 64, height: 48)
        secondVertices.withUnsafeBufferPointer { buffer in
            precondition(recorder.append(
                vertices: buffer.baseAddress!,
                floatCount: UInt32(buffer.count),
                triangleCount: 1,
                textureBinding0: nil,
                textureBinding1: nil
            ))
        }
        recorder.endFrame()
        guard let secondPacket = recorder.latestPacket else {
            preconditionFailure("second packet missing")
        }
        precondition(secondPacket.sequence == 2)
        precondition(secondPacket.vertices == secondVertices)
        precondition(secondPacket.draws.count == 1)

        // The first immutable packet must remain unchanged after the recorder
        // reuses and mutates its alternate storage for the second frame.
        precondition(firstPacket.vertices == firstVertices)
        precondition(firstPacket.draws[0].viewport == MetalRect(x: 0, y: 0, width: 32, height: 32))
        precondition(secondPacket.draws[0].viewport == MetalRect(x: 0, y: 0, width: 64, height: 48))

        recorder.reset()
        precondition(recorder.latestPacket == nil)
        print("SM64 Modern Metal scene packet smoke passed")
    }
}
