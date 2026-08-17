import CoreGraphics
import Foundation
import Metal
import QuartzCore
import os

private let metalLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Metal")

struct MetalTextureUpload: Sendable, Equatable {
    let generation: UInt64
    let textureID: UInt32
    let width: Int
    let height: Int
    let pixels: Data

    init(generation: UInt64, textureID: UInt32, pixels: Data, width: Int, height: Int) {
        self.generation = generation
        self.textureID = textureID
        self.pixels = pixels
        self.width = width
        self.height = height
    }
}

enum MetalRendererError: LocalizedError {
    case configurationUnavailable
    case commandQueueUnavailable
    case commandAllocatorUnavailable(slot: Int)
    case commandBufferUnavailable(slot: Int)
    case argumentTableUnavailable(slot: Int)
    case transientBufferUnavailable(bytes: Int)
    case sharedEventUnavailable
    case residencySetUnavailable
    case renderEncoderUnavailable
    case uploadEncoderUnavailable
    case textureUnavailable(id: UInt32)
    case invalidDraw(shaderID: UInt32)
    case gpuDrainTimedOut(value: UInt64)

    var errorDescription: String? {
        switch self {
        case .configurationUnavailable: "Metal surface configuration was not installed before engine startup"
        case .commandQueueUnavailable: "Metal 4 command queue creation failed"
        case let .commandAllocatorUnavailable(slot): "Metal 4 command allocator creation failed for frame slot \(slot)"
        case let .commandBufferUnavailable(slot): "Metal 4 command buffer creation failed for frame slot \(slot)"
        case let .argumentTableUnavailable(slot): "Metal 4 argument table creation failed for frame slot \(slot)"
        case let .transientBufferUnavailable(bytes): "Metal transient buffer creation failed for \(bytes) bytes"
        case .sharedEventUnavailable: "Metal shared event creation failed"
        case .residencySetUnavailable: "Metal scene residency set creation failed"
        case .renderEncoderUnavailable: "Metal 4 scene render encoder creation failed"
        case .uploadEncoderUnavailable: "Metal 4 texture upload encoder creation failed"
        case let .textureUnavailable(id): "Metal texture \(id) is not ready for drawing"
        case let .invalidDraw(shaderID): "Invalid vertex packet for shader 0x\(String(shaderID, radix: 16))"
        case let .gpuDrainTimedOut(value): "Timed out waiting for Metal completion value \(value)"
        }
    }
}

/// Engine-owner-thread Metal 4 renderer. The display-link callback is admitted
/// only when the host's owner-thread predicate succeeds; mutable frame slots,
/// residency, textures, samplers, and pipeline handles never cross that guard.
final class MetalRenderer: NSObject, CAMetalDisplayLinkDelegate {
    private final class MetalTextureResidency {
        let generation: UInt64
        let textureID: UInt32
        let width: Int
        let height: Int
        let texture: any MTLTexture

        init(upload: MetalTextureUpload, texture: any MTLTexture) {
            self.generation = upload.generation
            self.textureID = upload.textureID
            self.width = upload.width
            self.height = upload.height
            self.texture = texture
        }
    }

    private final class FrameSlot {
        let index: Int
        let allocator: any MTL4CommandAllocator
        let commandBuffer: any MTL4CommandBuffer
        let argumentTable: any MTL4ArgumentTable
        var transientBuffer: any MTLBuffer
        var depthTexture: (any MTLTexture)?
        var retainedTextureResidencies: [MetalTextureResidency] = []
        var completionValue: UInt64 = 0

        init(
            index: Int,
            allocator: any MTL4CommandAllocator,
            commandBuffer: any MTL4CommandBuffer,
            argumentTable: any MTL4ArgumentTable,
            transientBuffer: any MTLBuffer
        ) {
            self.index = index
            self.allocator = allocator
            self.commandBuffer = commandBuffer
            self.argumentTable = argumentTable
            self.transientBuffer = transientBuffer
        }
    }

    private final class TextureRecord {
        let id: UInt32
        var upload: MetalTextureUpload?
        var sampler = MetalSamplerKey(linear: false, wrapS: 0, wrapT: 0)

        init(id: UInt32) { self.id = id }
    }

    private struct PreparedUpload {
        let binding: MetalTextureResidency
        let texture: any MTLTexture
        let offset: Int
        let bytesPerRow: Int
    }

    private struct PreparedDraw {
        let draw: MetalSceneDraw
        let pipeline: MetalShaderCompiler.CompiledPipeline
        let vertexOffset: Int
        let uniformOffset: Int
        let texture0: (any MTLTexture)?
        let texture1: (any MTLTexture)?
    }

    private struct DepthStateKey: Hashable {
        let test: Bool
        let write: Bool
    }

    private static let frameSlotCount = 2
    private static let gpuWaitTimeoutMilliseconds: UInt64 = 5_000
    private static let initialTransientBytes = 4 * 1024 * 1024
    private static let clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

    private let device: any MTLDevice
    private let layer: CAMetalLayer
    private let queue: any MTL4CommandQueue
    private let completionEvent: any MTLSharedEvent
    private let sceneResidency: any MTLResidencySet
    private let shaderCompiler: MetalShaderCompiler
    private let recorder = MetalSceneRecorder()
    private var renderPacketCapture: SM64DisplayListRenderCapture?
    private let isOwnerThread: () -> Bool
    private let consumeDrawableSize: () -> CGSize?
    private let displayLink: CAMetalDisplayLink
    private var frameSlots: [FrameSlot] = []
    private var textures: [UInt32: TextureRecord] = [:]
    private var residentTextureBindings: [UInt64: MetalTextureResidency] = [:]
    private var samplers: [MetalSamplerKey: any MTLSamplerState] = [:]
    private var depthStates: [DepthStateKey: any MTLDepthStencilState] = [:]
    private var nextTextureGeneration: UInt64 = 1
    private var frameIndex = 0
    private var nextCompletionValue: UInt64 = 1
    private var presentedFrameCount: UInt64 = 0
    private var lastPresentedPacket: UInt64 = 0
    private var pipelineWaitLogCount: UInt64 = 0
    private var renderFailure: Error?
    private var isRunning = false

    init(
        device: any MTLDevice,
        layer: CAMetalLayer,
        isOwnerThread: @escaping () -> Bool,
        consumeDrawableSize: @escaping () -> CGSize?
    ) throws {
        self.device = device
        self.layer = layer
        self.isOwnerThread = isOwnerThread
        self.consumeDrawableSize = consumeDrawableSize

        let queueDescriptor = MTL4CommandQueueDescriptor()
        queueDescriptor.label = "SM64 Modern Present Queue"
        guard let queue = try? device.makeMTL4CommandQueue(descriptor: queueDescriptor) else {
            throw MetalRendererError.commandQueueUnavailable
        }
        self.queue = queue
        guard let completionEvent = device.makeSharedEvent() else { throw MetalRendererError.sharedEventUnavailable }
        completionEvent.label = "SM64 Modern Frame Completion"
        self.completionEvent = completionEvent

        let residencyDescriptor = MTLResidencySetDescriptor()
        residencyDescriptor.label = "SM64 Modern Scene Residency"
        residencyDescriptor.initialCapacity = Self.frameSlotCount + 256
        guard let sceneResidency = try? device.makeResidencySet(descriptor: residencyDescriptor) else {
            throw MetalRendererError.residencySetUnavailable
        }
        self.sceneResidency = sceneResidency
        self.shaderCompiler = try MetalShaderCompiler(device: device)
        self.displayLink = CAMetalDisplayLink(metalLayer: layer)
        super.init()
        if ProcessInfo.processInfo.environment["SM64_MODERN_RENDER_PACKET_CAPTURE"] == "1" {
            renderPacketCapture = SM64DisplayListRenderCapture(batchInstalled: true)
        }

        let argumentDescriptor = MTL4ArgumentTableDescriptor()
        argumentDescriptor.maxBufferBindCount = 2
        argumentDescriptor.maxTextureBindCount = 2
        argumentDescriptor.maxSamplerStateBindCount = 2
        argumentDescriptor.initializeBindings = true
        for slotIndex in 0..<Self.frameSlotCount {
            let allocatorDescriptor = MTL4CommandAllocatorDescriptor()
            allocatorDescriptor.label = "SM64 Modern Frame Allocator \(slotIndex)"
            guard let allocator = try? device.makeCommandAllocator(descriptor: allocatorDescriptor) else {
                throw MetalRendererError.commandAllocatorUnavailable(slot: slotIndex)
            }
            guard let commandBuffer = device.makeCommandBuffer() else {
                throw MetalRendererError.commandBufferUnavailable(slot: slotIndex)
            }
            commandBuffer.label = "SM64 Modern Reusable Scene Frame \(slotIndex)"
            argumentDescriptor.label = "SM64 Modern Frame Arguments \(slotIndex)"
            guard let table = try? device.makeArgumentTable(descriptor: argumentDescriptor) else {
                throw MetalRendererError.argumentTableUnavailable(slot: slotIndex)
            }
            guard let transient = device.makeBuffer(length: Self.initialTransientBytes, options: .storageModeShared) else {
                throw MetalRendererError.transientBufferUnavailable(bytes: Self.initialTransientBytes)
            }
            transient.label = "SM64 Modern Transient Frame \(slotIndex)"
            sceneResidency.addAllocation(transient)
            frameSlots.append(FrameSlot(
                index: slotIndex,
                allocator: allocator,
                commandBuffer: commandBuffer,
                argumentTable: table,
                transientBuffer: transient
            ))
        }

        sceneResidency.commit()
        sceneResidency.requestResidency()
        queue.addResidencySet(layer.residencySet)
        queue.addResidencySet(sceneResidency)
        displayLink.delegate = self
        displayLink.preferredFrameLatency = Float(Self.frameSlotCount)
        metalLogger.notice("metal_device_ready name=\(device.name, privacy: .public) api=Metal4 format=BGRA8Unorm frame_slots=\(Self.frameSlotCount)")
    }

    func start(on runLoop: RunLoop) {
        precondition(!isRunning, "MetalRenderer.start must be called exactly once")
        isRunning = true
        displayLink.add(to: runLoop, forMode: .common)
        displayLink.isPaused = false
        metalLogger.notice("metal_display_link_started owner_main=\(Thread.isMainThread)")
    }

    func initializeScene(filteringMode: UInt32) -> SM64ModernStatus {
        metalLogger.notice("metal_scene_initialized filtering=\(filteringMode)")
        return SM64_MODERN_STATUS_OK
    }

    func registerShader(id: UInt32, filteringMode: UInt32, inputCount: UInt32, textureMask: UInt32) -> SM64ModernStatus {
        recorder.registerShader(id: id, filteringMode: filteringMode, inputCount: inputCount, textureMask: textureMask)
        renderPacketCapture?.registerShader()
        let opaqueKey = MetalShaderKey(
            shaderID: id,
            filteringMode: filteringMode,
            inputCount: inputCount,
            textureMask: textureMask,
            alphaBlend: false
        )
        let alphaKey = MetalShaderKey(
                shaderID: id,
                filteringMode: filteringMode,
                inputCount: inputCount,
                textureMask: textureMask,
                alphaBlend: true
        )
        shaderCompiler.prepare(opaqueKey)
        shaderCompiler.prepare(alphaKey)
        return SM64_MODERN_STATUS_OK
    }

    func selectShader(_ id: UInt32) {
        recorder.selectShader(id)
        renderPacketCapture?.selectShader(id)
    }
    func createTexture(_ id: UInt32) -> SM64ModernStatus {
        if textures[id] == nil { textures[id] = TextureRecord(id: id) }
        renderPacketCapture?.createTexture(id: id)
        return SM64_MODERN_STATUS_OK
    }
    func selectTexture(tile: UInt32, id: UInt32) {
        recorder.selectTexture(tile: tile, id: id)
        renderPacketCapture?.selectTexture(tile: tile, id: id)
        if let sampler = textures[id]?.sampler {
            recorder.setSampler(tile: tile, linear: sampler.linear, wrapS: sampler.wrapS, wrapT: sampler.wrapT)
        }
    }

    func uploadTexture(id: UInt32, pixels: UnsafePointer<UInt8>, width: UInt32, height: UInt32) -> SM64ModernStatus {
        guard width > 0, height > 0, let record = textures[id] else { return SM64_MODERN_STATUS_INVALID_ARGUMENT }
        let (pixelCount, pixelOverflow) = Int(width).multipliedReportingOverflow(by: Int(height))
        let (byteCount, byteOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        guard !pixelOverflow, !byteOverflow else { return SM64_MODERN_STATUS_INVALID_ARGUMENT }
        let upload = MetalTextureUpload(
            generation: nextTextureGeneration,
            textureID: id,
            pixels: Data(bytes: pixels, count: byteCount),
            width: Int(width),
            height: Int(height)
        )
        nextTextureGeneration += 1
        record.upload = upload
        return SM64_MODERN_STATUS_OK
    }

    func setSampler(tile: UInt32, id: UInt32, linear: Bool, wrapS: UInt32, wrapT: UInt32) {
        let sampler = MetalSamplerKey(linear: linear, wrapS: wrapS, wrapT: wrapT)
        textures[id]?.sampler = sampler
        recorder.setSampler(tile: tile, linear: sampler.linear, wrapS: sampler.wrapS, wrapT: sampler.wrapT)
    }
    func setDepthTest(_ enabled: Bool) { recorder.setDepthTest(enabled) }
    func setDepthWrite(_ enabled: Bool) { recorder.setDepthWrite(enabled) }
    func setDecal(_ enabled: Bool) { recorder.setDecal(enabled) }
    func setViewport(_ rect: MetalRect) {
        recorder.setViewport(rect)
        renderPacketCapture?.setViewport(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
    }
    func setScissor(_ rect: MetalRect) {
        recorder.setScissor(rect)
        renderPacketCapture?.setScissor(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
    }
    func setAlphaBlend(_ enabled: Bool) { recorder.setAlphaBlend(enabled) }

    func draw(vertices: UnsafePointer<Float>?, floatCount: UInt32, triangleCount: UInt32) -> SM64ModernStatus {
        let textureID0 = recorder.currentTextureID(tile: 0)
        let textureID1 = recorder.currentTextureID(tile: 1)
        guard let vertices, recorder.append(
            vertices: vertices,
            floatCount: floatCount,
            triangleCount: triangleCount,
            textureUpload0: textures[textureID0]?.upload,
            textureUpload1: textures[textureID1]?.upload
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        renderPacketCapture?.draw(
            shaderID: UInt32.max,
            vertices: vertices,
            floatCount: floatCount,
            triangleCount: triangleCount
        )
        return SM64_MODERN_STATUS_OK
    }

    func startSceneFrame() -> SM64ModernStatus {
        recorder.startFrame(width: Int(layer.drawableSize.width), height: Int(layer.drawableSize.height))
        renderPacketCapture?.startFrame()
        return SM64_MODERN_STATUS_OK
    }
    func endSceneFrame() -> SM64ModernStatus {
        recorder.endFrame()
        renderPacketCapture?.endFrame()
        if let packet = renderPacketCapture?.packet(), packet.sequence == 1 || packet.sequence.isMultiple(of: 300) {
            let summary = renderPacketCapture?.summary()
            metalLogger.notice(
                "swift_render_packet_capture frame=\(packet.sequence, privacy: .public) events=\(packet.events.count, privacy: .public) draws=\(summary?.draws ?? 0, privacy: .public) fingerprint=\(packet.fingerprint, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
    }
    func finishScene() -> SM64ModernStatus {
        renderPacketCapture?.finish(renderStatus: 0, batchStatus: 0)
        return SM64_MODERN_STATUS_OK
    }

    func dimensions() -> (UInt32, UInt32) {
        (UInt32(max(layer.drawableSize.width, 1)), UInt32(max(layer.drawableSize.height, 1)))
    }

    func logSceneStatus(step: UInt64) {
        let packet = recorder.latestPacket
        let pendingUploads = textureBindings(in: packet).filter {
            residentTextureBindings[$0.generation] == nil
        }.count
        metalLogger.notice(
            "metal_scene_status step=\(step) latest_packet=\(packet?.sequence ?? 0) latest_draws=\(packet?.draws.count ?? 0) presented=\(self.presentedFrameCount) gpu_completed=\(self.completionEvent.signaledValue) pending_uploads=\(pendingUploads)"
        )
    }

    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        autoreleasepool {
            guard isOwnerThread() else {
                metalLogger.error("metal_display_link_dropped reason=unexpected_callback_thread main=\(Thread.isMainThread)")
                return
            }
            guard isRunning, renderFailure == nil else { return }
            do { try renderSceneFrame(to: update.drawable) }
            catch {
                renderFailure = error
                displayLink.isPaused = true
                metalLogger.fault("metal_frame_failed error=\(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func shutdownAndDrain() throws {
        guard isRunning else { return }
        isRunning = false
        displayLink.invalidate()
        for slot in frameSlots where slot.completionValue != 0 { try waitForGPU(value: slot.completionValue) }
        for binding in residentTextureBindings.values {
            sceneResidency.removeAllocation(binding.texture)
        }
        if !residentTextureBindings.isEmpty { sceneResidency.commit() }
        residentTextureBindings.removeAll()
        textures.removeAll()
        samplers.removeAll()
        depthStates.removeAll()
        shaderCompiler.removeAll()
        queue.removeResidencySet(sceneResidency)
        queue.removeResidencySet(layer.residencySet)
        sceneResidency.endResidency()
        metalLogger.notice("metal_shutdown_drained frames=\(self.presentedFrameCount) completion=\(self.completionEvent.signaledValue)")
        if let renderFailure { throw renderFailure }
    }

    private func renderSceneFrame(to drawable: any CAMetalDrawable) throws {
        let colorTexture = drawable.texture
        let slot = frameSlots[frameIndex]
        if slot.completionValue != 0 { try waitForGPU(value: slot.completionValue) }
        slot.retainedTextureResidencies.removeAll(keepingCapacity: true)
        collectUnusedTextureBindings()

        let packet = recorder.latestPacket
        let requiredBytes = requiredTransientBytes(for: packet)
        try ensureTransientCapacity(requiredBytes, slot: slot)
        var cursor = 0
        let frameTextureBindings = textureBindings(in: packet)
        let uploads = try prepareUploads(frameTextureBindings, into: slot.transientBuffer, cursor: &cursor)
        let preparedDraws: [PreparedDraw]
        if let readyDraws = try prepareDraws(packet, into: slot.transientBuffer, cursor: &cursor) {
            preparedDraws = readyDraws
            pipelineWaitLogCount = 0
        } else {
            preparedDraws = []
            pipelineWaitLogCount += 1
            if pipelineWaitLogCount <= 3 || pipelineWaitLogCount.isMultiple(of: 120) {
                metalLogger.notice("metal_scene_waiting_for_pipelines packet=\(packet?.sequence ?? 0) draws=\(packet?.draws.count ?? 0) wait_count=\(self.pipelineWaitLogCount)")
            }
        }
        try ensureDepthTexture(for: colorTexture, slot: slot)

        slot.allocator.reset()
        let commandBuffer = slot.commandBuffer
        commandBuffer.beginCommandBuffer(allocator: slot.allocator)
        // MTL4 command buffers do not carry prior per-command-buffer
        // residency declarations across begin/end cycles. Keep the queue-level
        // residency sets as a broad safety net, but declare both the scene and
        // CAMetalLayer allocations on every reusable submission as required by
        // the Metal 4 command-buffer lifetime contract.
        commandBuffer.useResidencySet(sceneResidency)
        commandBuffer.useResidencySet(layer.residencySet)
        commandBuffer.pushDebugGroup("M4 SM64 Scene and Present")

        if !uploads.isEmpty {
            guard let uploadEncoder = commandBuffer.makeComputeCommandEncoder() else {
                commandBuffer.popDebugGroup(); commandBuffer.endCommandBuffer()
                throw MetalRendererError.uploadEncoderUnavailable
            }
            uploadEncoder.label = "SM64 Modern Texture Uploads"
            uploadEncoder.pushDebugGroup("Stage RGBA8 textures into private storage")
            for upload in uploads {
                SM64ModernCopyBufferToTexture(
                    uploadEncoder,
                    slot.transientBuffer,
                    UInt(upload.offset),
                    UInt(upload.bytesPerRow),
                    UInt(upload.bytesPerRow * upload.binding.height),
                    MTLSize(width: upload.binding.width, height: upload.binding.height, depth: 1),
                    upload.texture
                )
            }
            SM64ModernBarrierBlitToFragmentProducer(uploadEncoder)
            uploadEncoder.popDebugGroup()
            uploadEncoder.endEncoding()
        }

        let pass = MTL4RenderPassDescriptor()
        let color = pass.colorAttachments[0]
        color?.texture = colorTexture
        color?.loadAction = .clear
        color?.storeAction = .store
        color?.clearColor = Self.clearColor
        pass.depthAttachment.texture = slot.depthTexture
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.storeAction = .dontCare
        pass.depthAttachment.clearDepth = 1.0
        pass.renderTargetWidth = colorTexture.width
        pass.renderTargetHeight = colorTexture.height

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else {
            commandBuffer.popDebugGroup(); commandBuffer.endCommandBuffer()
            throw MetalRendererError.renderEncoderUnavailable
        }
        encoder.label = "SM64 Modern Scene Pass"
        encoder.pushDebugGroup("Replay immutable SM64 display list packet")
        if !uploads.isEmpty { SM64ModernBarrierBlitToFragmentConsumer(encoder) }
        encoder.setCullMode(.none)

        var boundPipeline: MetalShaderKey?
        var boundDepthState: DepthStateKey?
        var boundDecal: Bool?
        var boundViewport: MetalRect?
        var boundScissor: MetalRect?
        for prepared in preparedDraws {
            let draw = prepared.draw
            if boundPipeline != draw.shader {
                encoder.setRenderPipelineState(prepared.pipeline.state)
                boundPipeline = draw.shader
            }
            let depthKey = DepthStateKey(test: draw.depthTest, write: draw.depthWrite)
            if boundDepthState != depthKey {
                encoder.setDepthStencilState(try depthState(test: depthKey.test, write: depthKey.write))
                boundDepthState = depthKey
            }
            if boundDecal != draw.decal {
                encoder.setDepthBias(draw.decal ? -2.0 : 0.0, slopeScale: draw.decal ? -2.0 : 0.0, clamp: 0.0)
                boundDecal = draw.decal
            }
            if boundViewport != draw.viewport {
                encoder.setViewport(makeViewport(draw.viewport, drawableHeight: colorTexture.height))
                boundViewport = draw.viewport
            }
            if boundScissor != draw.scissor {
                encoder.setScissorRect(makeScissor(draw.scissor, width: colorTexture.width, height: colorTexture.height))
                boundScissor = draw.scissor
            }

            slot.argumentTable.setAddress(slot.transientBuffer.gpuAddress + UInt64(prepared.vertexOffset), index: 0)
            slot.argumentTable.setAddress(slot.transientBuffer.gpuAddress + UInt64(prepared.uniformOffset), index: 1)
            if draw.shader.textureMask & 1 != 0 {
                guard let texture = prepared.texture0 else {
                    throw MetalRendererError.textureUnavailable(id: draw.textureID0)
                }
                slot.argumentTable.setTexture(texture.gpuResourceID, index: 0)
                slot.argumentTable.setSamplerState(try sampler(for: draw.sampler0, filteringMode: draw.shader.filteringMode).gpuResourceID, index: 0)
            }
            if draw.shader.textureMask & 2 != 0 {
                guard let texture = prepared.texture1 else {
                    throw MetalRendererError.textureUnavailable(id: draw.textureID1)
                }
                slot.argumentTable.setTexture(texture.gpuResourceID, index: 1)
                slot.argumentTable.setSamplerState(try sampler(for: draw.sampler1, filteringMode: draw.shader.filteringMode).gpuResourceID, index: 1)
            }
            encoder.setArgumentTable(slot.argumentTable, stages: [.vertex, .fragment])
            encoder.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: Int(draw.triangleCount) * 3)
        }
        encoder.popDebugGroup()
        encoder.endEncoding()
        commandBuffer.popDebugGroup()
        commandBuffer.endCommandBuffer()

        queue.waitForDrawable(drawable)
        queue.commit([commandBuffer])
        let completionValue = nextCompletionValue
        nextCompletionValue += 1
        queue.signalEvent(completionEvent, value: completionValue)
        queue.signalDrawable(drawable)
        drawable.present()
        slot.completionValue = completionValue
        slot.retainedTextureResidencies = frameTextureBindings.compactMap {
            residentTextureBindings[$0.generation]
        }

        if let packet { lastPresentedPacket = packet.sequence }
        presentedFrameCount += 1
        if presentedFrameCount <= 5 || !uploads.isEmpty || presentedFrameCount.isMultiple(of: 600) {
            metalLogger.notice("metal_scene_presented frame=\(self.presentedFrameCount) packet=\(self.lastPresentedPacket) draws=\(preparedDraws.count) uploads=\(uploads.count) drawable=\(colorTexture.width)x\(colorTexture.height) source=display_link")
        }
        if let drawableSize = consumeDrawableSize() {
            layer.drawableSize = drawableSize
            metalLogger.notice("metal_resize_applied drawable=\(Int(drawableSize.width))x\(Int(drawableSize.height))")
        }
        frameIndex = (frameIndex + 1) % frameSlots.count
    }

    private func requiredTransientBytes(for packet: MetalScenePacket?) -> Int {
        var total = textureBindings(in: packet).reduce(0) { $0 + $1.pixels.count + 255 }
        if let packet {
            total += packet.vertices.count * MemoryLayout<Float>.size
            total += packet.draws.count * 512
        }
        return max(total, 256)
    }

    private func ensureTransientCapacity(_ required: Int, slot: FrameSlot) throws {
        guard required > slot.transientBuffer.length else { return }
        var capacity = slot.transientBuffer.length
        while capacity < required { capacity *= 2 }
        guard let replacement = device.makeBuffer(length: capacity, options: .storageModeShared) else {
            throw MetalRendererError.transientBufferUnavailable(bytes: capacity)
        }
        replacement.label = "SM64 Modern Transient Frame \(slot.index) (\(capacity) bytes)"
        sceneResidency.removeAllocation(slot.transientBuffer)
        sceneResidency.addAllocation(replacement)
        sceneResidency.commit()
        slot.transientBuffer = replacement
        metalLogger.notice("metal_transient_grew slot=\(slot.index) bytes=\(capacity)")
    }

    private func prepareUploads(
        _ bindings: [MetalTextureUpload],
        into buffer: any MTLBuffer,
        cursor: inout Int
    ) throws -> [PreparedUpload] {
        var uploads: [PreparedUpload] = []
        var residencyChanged = false
        for upload in bindings.sorted(by: { $0.generation < $1.generation }) {
            guard residentTextureBindings[upload.generation] == nil else { continue }
            let pixels = upload.pixels
            cursor = aligned(cursor, to: 256)
            pixels.copyBytes(to: buffer.contents().advanced(by: cursor).assumingMemoryBound(to: UInt8.self), count: pixels.count)
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: upload.width,
                height: upload.height,
                mipmapped: false
            )
            descriptor.storageMode = .private
            descriptor.usage = .shaderRead
            guard let texture = device.makeTexture(descriptor: descriptor) else {
                throw MetalRendererError.textureUnavailable(id: upload.textureID)
            }
            texture.label = "SM64 Texture \(upload.textureID).\(upload.generation) \(upload.width)x\(upload.height)"
            let residency = MetalTextureResidency(upload: upload, texture: texture)
            sceneResidency.addAllocation(texture)
            residentTextureBindings[upload.generation] = residency
            residencyChanged = true
            uploads.append(PreparedUpload(binding: residency, texture: texture, offset: cursor, bytesPerRow: upload.width * 4))
            cursor += pixels.count
        }
        if residencyChanged { sceneResidency.commit() }
        return uploads
    }

    private func prepareDraws(_ packet: MetalScenePacket?, into buffer: any MTLBuffer, cursor: inout Int) throws -> [PreparedDraw]? {
        guard let packet else { return [] }
        var prepared: [PreparedDraw] = []
        do {
            try packet.vertices.withUnsafeBufferPointer { source in
                for draw in packet.draws {
                    guard let baseAddress = source.baseAddress,
                          draw.vertexOffset >= 0,
                          draw.floatCount >= 0,
                          draw.vertexOffset <= source.count,
                          draw.floatCount <= source.count - draw.vertexOffset else {
                        throw MetalRendererError.invalidDraw(shaderID: draw.shader.shaderID)
                    }
                    let pipeline = try shaderCompiler.pipeline(for: draw.shader)
                    let expected = Int(draw.triangleCount) * 3 * pipeline.vertexStride
                    guard expected == draw.floatCount else {
                        throw MetalRendererError.invalidDraw(shaderID: draw.shader.shaderID)
                    }
                    cursor = aligned(cursor, to: 16)
                    let vertexOffset = cursor
                    let byteCount = draw.floatCount * MemoryLayout<Float>.size
                    buffer.contents().advanced(by: vertexOffset).copyMemory(
                        from: baseAddress.advanced(by: draw.vertexOffset),
                        byteCount: byteCount
                    )
                    cursor += byteCount
                    cursor = aligned(cursor, to: 16)
                    let uniformOffset = cursor
                    buffer.contents().advanced(by: uniformOffset).assumingMemoryBound(to: UInt32.self).initialize(repeating: 0, count: 4)
                    buffer.contents().advanced(by: uniformOffset).assumingMemoryBound(to: UInt32.self).pointee = UInt32(truncatingIfNeeded: packet.sequence)
                    cursor += 16
                    let texture0 = draw.textureUpload0.flatMap {
                        residentTextureBindings[$0.generation]?.texture
                    }
                    let texture1 = draw.textureUpload1.flatMap {
                        residentTextureBindings[$0.generation]?.texture
                    }
                    prepared.append(PreparedDraw(
                        draw: draw,
                        pipeline: pipeline,
                        vertexOffset: vertexOffset,
                        uniformOffset: uniformOffset,
                        texture0: texture0,
                        texture1: texture1
                    ))
                }
            }
        } catch MetalShaderCompilerError.pipelineNotReady {
            return nil
        }
        return prepared
    }

    private func ensureDepthTexture(for drawable: any MTLTexture, slot: FrameSlot) throws {
        if let depth = slot.depthTexture, depth.width == drawable.width, depth.height == drawable.height { return }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: drawable.width, height: drawable.height, mipmapped: false)
        descriptor.storageMode = .memoryless
        descriptor.usage = .renderTarget
        guard let depth = device.makeTexture(descriptor: descriptor) else {
            throw MetalRendererError.textureUnavailable(id: UInt32.max)
        }
        depth.label = "SM64 Modern Memoryless Depth Slot \(slot.index) \(drawable.width)x\(drawable.height)"
        slot.depthTexture = depth
    }

    private func sampler(for key: MetalSamplerKey, filteringMode: UInt32) throws -> any MTLSamplerState {
        var effective = key
        if filteringMode == 2 { effective = MetalSamplerKey(linear: false, wrapS: key.wrapS, wrapT: key.wrapT) }
        if let cached = samplers[effective] { return cached }
        let descriptor = MTLSamplerDescriptor()
        descriptor.label = "SM64 Sampler linear=\(effective.linear) s=\(effective.wrapS) t=\(effective.wrapT)"
        descriptor.minFilter = effective.linear ? .linear : .nearest
        descriptor.magFilter = effective.linear ? .linear : .nearest
        descriptor.sAddressMode = addressMode(effective.wrapS)
        descriptor.tAddressMode = addressMode(effective.wrapT)
        guard let sampler = device.makeSamplerState(descriptor: descriptor) else { throw MetalRendererError.textureUnavailable(id: 0) }
        samplers[effective] = sampler
        return sampler
    }

    private func addressMode(_ flags: UInt32) -> MTLSamplerAddressMode {
        if flags & 2 != 0 { return .clampToEdge }
        if flags & 1 != 0 { return .mirrorRepeat }
        return .repeat
    }

    private func depthState(test: Bool, write: Bool) throws -> any MTLDepthStencilState {
        let key = DepthStateKey(test: test, write: write)
        if let cached = depthStates[key] { return cached }
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.label = "SM64 Depth test=\(test) write=\(write)"
        descriptor.depthCompareFunction = test ? .lessEqual : .always
        descriptor.isDepthWriteEnabled = write
        guard let state = device.makeDepthStencilState(descriptor: descriptor) else {
            throw MetalRendererError.textureUnavailable(id: UInt32.max)
        }
        depthStates[key] = state
        return state
    }

    private func makeViewport(_ rect: MetalRect, drawableHeight: Int) -> MTLViewport {
        let y = max(0, drawableHeight - Int(rect.y) - Int(rect.height))
        return MTLViewport(originX: Double(max(rect.x, 0)), originY: Double(y), width: Double(max(rect.width, 1)), height: Double(max(rect.height, 1)), znear: 0, zfar: 1)
    }

    private func makeScissor(_ rect: MetalRect, width: Int, height: Int) -> MTLScissorRect {
        let x = min(max(Int(rect.x), 0), max(width - 1, 0))
        let y = min(max(height - Int(rect.y) - Int(rect.height), 0), max(height - 1, 0))
        return MTLScissorRect(x: x, y: y, width: min(max(Int(rect.width), 1), width - x), height: min(max(Int(rect.height), 1), height - y))
    }

    private func textureBindings(in packet: MetalScenePacket?) -> [MetalTextureUpload] {
        guard let packet else { return [] }
        var seen = Set<UInt64>()
        var result: [MetalTextureUpload] = []
        result.reserveCapacity(packet.draws.count)

        func appendIfNew(_ upload: MetalTextureUpload?) {
            guard let upload, seen.insert(upload.generation).inserted else { return }
            result.append(upload)
        }

        for draw in packet.draws {
            appendIfNew(draw.textureUpload0)
            appendIfNew(draw.textureUpload1)
        }
        return result
    }

    private func collectUnusedTextureBindings() {
        var liveGenerations = Set(textures.values.compactMap { $0.upload?.generation })
        for upload in textureBindings(in: recorder.latestPacket) { liveGenerations.insert(upload.generation) }
        for residency in frameSlots.flatMap(\.retainedTextureResidencies) { liveGenerations.insert(residency.generation) }
        let unused = residentTextureBindings.values.filter { !liveGenerations.contains($0.generation) }
        guard !unused.isEmpty else { return }
        for binding in unused {
            sceneResidency.removeAllocation(binding.texture)
            residentTextureBindings.removeValue(forKey: binding.generation)
        }
        sceneResidency.commit()
    }

    private func aligned(_ value: Int, to alignment: Int) -> Int { (value + alignment - 1) & ~(alignment - 1) }

    private func waitForGPU(value: UInt64) throws {
        guard completionEvent.signaledValue < value else { return }
        guard completionEvent.wait(untilSignaledValue: value, timeoutMS: Self.gpuWaitTimeoutMilliseconds) else {
            throw MetalRendererError.gpuDrainTimedOut(value: value)
        }
    }
}
