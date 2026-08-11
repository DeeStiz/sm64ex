import CoreGraphics
import Foundation

struct MetalSamplerKey: Hashable, Sendable {
    let linear: Bool
    let wrapS: UInt32
    let wrapT: UInt32
}

struct MetalShaderKey: Hashable, Sendable {
    let shaderID: UInt32
    let filteringMode: UInt32
    let inputCount: UInt32
    let textureMask: UInt32
    let alphaBlend: Bool
}

struct MetalRect: Hashable, Sendable {
    let x: Int32
    let y: Int32
    let width: Int32
    let height: Int32
}

struct MetalSceneDraw: Sendable {
    let shader: MetalShaderKey
    let textureIDs: [UInt32]
    let samplers: [MetalSamplerKey]
    let depthTest: Bool
    let depthWrite: Bool
    let decal: Bool
    let viewport: MetalRect
    let scissor: MetalRect
    let vertices: [Float]
    let triangleCount: UInt32
}

struct MetalScenePacket: Sendable {
    let sequence: UInt64
    let draws: [MetalSceneDraw]
}

final class MetalSceneRecorder {
    private var shaders: [UInt32: MetalShaderKey] = [:]
    private var selectedShaderID: UInt32?
    private var selectedTextureIDs = [UInt32](repeating: 0, count: 2)
    private var samplerKeys = [
        MetalSamplerKey(linear: false, wrapS: 0, wrapT: 0),
        MetalSamplerKey(linear: false, wrapS: 0, wrapT: 0),
    ]
    private var depthTest = false
    private var depthWrite = true
    private var decal = false
    private var alphaBlend = false
    private var viewport = MetalRect(x: 0, y: 0, width: 1, height: 1)
    private var scissor = MetalRect(x: 0, y: 0, width: 1, height: 1)
    private var draws: [MetalSceneDraw] = []
    private var nextSequence: UInt64 = 1
    private(set) var latestPacket: MetalScenePacket?

    func registerShader(
        id: UInt32,
        filteringMode: UInt32,
        inputCount: UInt32,
        textureMask: UInt32
    ) {
        shaders[id] = MetalShaderKey(
            shaderID: id,
            filteringMode: filteringMode,
            inputCount: inputCount,
            textureMask: textureMask,
            alphaBlend: false
        )
    }

    func selectShader(_ id: UInt32) {
        selectedShaderID = id
    }

    func selectTexture(tile: UInt32, id: UInt32) {
        guard tile < 2 else { return }
        selectedTextureIDs[Int(tile)] = id
    }

    func setSampler(tile: UInt32, linear: Bool, wrapS: UInt32, wrapT: UInt32) {
        guard tile < 2 else { return }
        samplerKeys[Int(tile)] = MetalSamplerKey(linear: linear, wrapS: wrapS, wrapT: wrapT)
    }

    func setDepthTest(_ enabled: Bool) { depthTest = enabled }
    func setDepthWrite(_ enabled: Bool) { depthWrite = enabled }
    func setDecal(_ enabled: Bool) { decal = enabled }
    func setAlphaBlend(_ enabled: Bool) { alphaBlend = enabled }
    func setViewport(_ rect: MetalRect) { viewport = rect }
    func setScissor(_ rect: MetalRect) { scissor = rect }

    func startFrame(width: Int, height: Int) {
        draws.removeAll(keepingCapacity: true)
        let full = MetalRect(x: 0, y: 0, width: Int32(max(width, 1)), height: Int32(max(height, 1)))
        viewport = full
        scissor = full
    }

    func append(vertices: UnsafePointer<Float>, floatCount: UInt32, triangleCount: UInt32) -> Bool {
        guard let selectedShaderID, let registered = shaders[selectedShaderID], floatCount > 0 else {
            return false
        }
        var shader = registered
        shader = MetalShaderKey(
            shaderID: shader.shaderID,
            filteringMode: shader.filteringMode,
            inputCount: shader.inputCount,
            textureMask: shader.textureMask,
            alphaBlend: alphaBlend
        )
        let draw = MetalSceneDraw(
            shader: shader,
            textureIDs: selectedTextureIDs,
            samplers: samplerKeys,
            depthTest: depthTest,
            depthWrite: depthWrite,
            decal: decal,
            viewport: viewport,
            scissor: scissor,
            vertices: Array(UnsafeBufferPointer(start: vertices, count: Int(floatCount))),
            triangleCount: triangleCount
        )
        draws.append(draw)
        return true
    }

    func endFrame() {
        latestPacket = MetalScenePacket(sequence: nextSequence, draws: draws)
        nextSequence += 1
    }

    func reset() {
        shaders.removeAll()
        draws.removeAll()
        latestPacket = nil
        selectedShaderID = nil
    }
}
