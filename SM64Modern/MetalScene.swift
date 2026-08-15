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
    let textureID0: UInt32
    let textureID1: UInt32
    let textureBinding0: MetalTextureBinding?
    let textureBinding1: MetalTextureBinding?
    let sampler0: MetalSamplerKey
    let sampler1: MetalSamplerKey
    let depthTest: Bool
    let depthWrite: Bool
    let decal: Bool
    let viewport: MetalRect
    let scissor: MetalRect
    let vertexOffset: Int
    let floatCount: Int
    let triangleCount: UInt32
}

struct MetalSceneFrameStorage: Sendable {
    // Display lists are bounded by the legacy renderer's frame budget. Reserve
    // once per reusable storage so appending a draw does not allocate a new
    // per-draw vertex array or descriptor backing store during steady state.
    private static let initialVertexCapacity = 256 * 1024
    private static let initialDrawCapacity = 512

    var vertices: [Float]
    var draws: [MetalSceneDraw]

    init() {
        vertices = []
        vertices.reserveCapacity(Self.initialVertexCapacity)
        draws = []
        draws.reserveCapacity(Self.initialDrawCapacity)
    }

    mutating func reset() {
        vertices.removeAll(keepingCapacity: true)
        draws.removeAll(keepingCapacity: true)
    }
}

struct MetalScenePacket: Sendable {
    let sequence: UInt64
    let vertices: [Float]
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
    private var activeStorage = MetalSceneFrameStorage()
    private var reusableStorage = MetalSceneFrameStorage()
    private var nextSequence: UInt64 = 1
    private(set) var latestPacket: MetalScenePacket?

    func currentTextureID(tile: UInt32) -> UInt32 {
        guard tile < 2 else { return 0 }
        return selectedTextureIDs[Int(tile)]
    }

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
        activeStorage.reset()
        let full = MetalRect(x: 0, y: 0, width: Int32(max(width, 1)), height: Int32(max(height, 1)))
        viewport = full
        scissor = full
    }

    func append(
        vertices: UnsafePointer<Float>,
        floatCount: UInt32,
        triangleCount: UInt32,
        textureBinding0: MetalTextureBinding?,
        textureBinding1: MetalTextureBinding?
    ) -> Bool {
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
        let vertexOffset = activeStorage.vertices.count
        let floatCount = Int(floatCount)
        activeStorage.vertices.append(contentsOf: UnsafeBufferPointer(start: vertices, count: floatCount))
        activeStorage.draws.append(MetalSceneDraw(
            shader: shader,
            textureID0: selectedTextureIDs[0],
            textureID1: selectedTextureIDs[1],
            textureBinding0: textureBinding0,
            textureBinding1: textureBinding1,
            sampler0: samplerKeys[0],
            sampler1: samplerKeys[1],
            depthTest: depthTest,
            depthWrite: depthWrite,
            decal: decal,
            viewport: viewport,
            scissor: scissor,
            vertexOffset: vertexOffset,
            floatCount: floatCount,
            triangleCount: triangleCount
        ))
        return true
    }

    func endFrame() {
        let finishedStorage = activeStorage
        activeStorage = reusableStorage
        reusableStorage = finishedStorage
        // Arrays are copy-on-write. The packet keeps an immutable value
        // snapshot while the recorder mutates the alternate reusable storage
        // on the owner thread; the display-link callback therefore never reads
        // a mutable frame-storage reference.
        latestPacket = MetalScenePacket(
            sequence: nextSequence,
            vertices: finishedStorage.vertices,
            draws: finishedStorage.draws
        )
        nextSequence += 1
    }

    func reset() {
        shaders.removeAll()
        activeStorage.reset()
        reusableStorage.reset()
        latestPacket = nil
        selectedShaderID = nil
    }
}
