import CoreGraphics
import Foundation
import Metal
import QuartzCore
import os

private let metalLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Metal")

enum MetalRendererError: LocalizedError {
    case configurationUnavailable
    case commandQueueUnavailable
    case commandAllocatorUnavailable(slot: Int)
    case commandBufferUnavailable(slot: Int)
    case sharedEventUnavailable
    case renderEncoderUnavailable
    case gpuDrainTimedOut(value: UInt64)

    var errorDescription: String? {
        switch self {
        case .configurationUnavailable:
            "Metal surface configuration was not installed before engine startup"
        case .commandQueueUnavailable:
            "Metal 4 command queue creation failed"
        case let .commandAllocatorUnavailable(slot):
            "Metal 4 command allocator creation failed for frame slot \(slot)"
        case let .commandBufferUnavailable(slot):
            "Metal 4 command buffer creation failed for frame slot \(slot)"
        case .sharedEventUnavailable:
            "Metal shared event creation failed"
        case .renderEncoderUnavailable:
            "Metal 4 clear render encoder creation failed"
        case let .gpuDrainTimedOut(value):
            "Timed out waiting for Metal completion value \(value)"
        }
    }
}

final class MetalRenderer: NSObject, CAMetalDisplayLinkDelegate, @unchecked Sendable {
    private final class FrameSlot {
        let allocator: any MTL4CommandAllocator
        let commandBuffer: any MTL4CommandBuffer
        var completionValue: UInt64 = 0

        init(allocator: any MTL4CommandAllocator, commandBuffer: any MTL4CommandBuffer) {
            self.allocator = allocator
            self.commandBuffer = commandBuffer
        }
    }

    // HARDCODED(M3): use the approved double-buffered bring-up depth until M4
    // sources frame pacing from the native renderer configuration.
    private static let frameSlotCount = 2
    // HARDCODED(M3): bound validation shutdowns until M4 centralizes renderer timeouts.
    private static let gpuWaitTimeoutMilliseconds: UInt64 = 5_000
    // HARDCODED(M3): the approved diagnostic clear is replaced by M4 scene output.
    private static let clearColor = MTLClearColor(red: 0.015, green: 0.035, blue: 0.085, alpha: 1.0)

    private let layer: CAMetalLayer
    private let queue: any MTL4CommandQueue
    private let completionEvent: any MTLSharedEvent
    private let consumeDrawableSize: @Sendable () -> CGSize?
    private let displayLink: CAMetalDisplayLink
    private var frameSlots: [FrameSlot] = []
    private var frameIndex = 0
    private var nextCompletionValue: UInt64 = 1
    private var presentedFrameCount: UInt64 = 0
    private var renderFailure: Error?
    private var isRunning = false

    init(
        device: any MTLDevice,
        layer: CAMetalLayer,
        consumeDrawableSize: @escaping @Sendable () -> CGSize?
    ) throws {
        let queueDescriptor = MTL4CommandQueueDescriptor()
        queueDescriptor.label = "SM64 Modern Present Queue"
        guard let queue = try? device.makeMTL4CommandQueue(descriptor: queueDescriptor) else {
            throw MetalRendererError.commandQueueUnavailable
        }
        guard let completionEvent = device.makeSharedEvent() else {
            throw MetalRendererError.sharedEventUnavailable
        }
        completionEvent.label = "SM64 Modern Frame Completion"

        self.layer = layer
        self.queue = queue
        self.completionEvent = completionEvent
        self.consumeDrawableSize = consumeDrawableSize
        self.displayLink = CAMetalDisplayLink(metalLayer: layer)
        super.init()

        for slotIndex in 0..<Self.frameSlotCount {
            let allocatorDescriptor = MTL4CommandAllocatorDescriptor()
            allocatorDescriptor.label = "SM64 Modern Frame Allocator \(slotIndex)"
            guard let allocator = try? device.makeCommandAllocator(descriptor: allocatorDescriptor) else {
                throw MetalRendererError.commandAllocatorUnavailable(slot: slotIndex)
            }
            guard let commandBuffer = device.makeCommandBuffer() else {
                throw MetalRendererError.commandBufferUnavailable(slot: slotIndex)
            }
            commandBuffer.label = "SM64 Modern Reusable Frame \(slotIndex)"
            frameSlots.append(FrameSlot(allocator: allocator, commandBuffer: commandBuffer))
        }

        queue.addResidencySet(layer.residencySet)
        displayLink.delegate = self
        displayLink.preferredFrameLatency = Float(Self.frameSlotCount)
        metalLogger.notice(
            "metal_device_ready name=\(device.name, privacy: .public) api=Metal4 format=BGRA8Unorm frame_slots=\(Self.frameSlotCount)"
        )
    }

    func start(on runLoop: RunLoop) {
        precondition(!isRunning, "MetalRenderer.start must be called exactly once")
        isRunning = true
        displayLink.add(to: runLoop, forMode: .common)
        displayLink.isPaused = false
        metalLogger.notice("metal_display_link_started owner_main=\(Thread.isMainThread)")
    }

    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        autoreleasepool {
            guard isRunning, renderFailure == nil else { return }
            do {
                try renderClearFrame(to: update.drawable)
            } catch {
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

        for slot in frameSlots where slot.completionValue != 0 {
            try waitForGPU(value: slot.completionValue)
        }
        queue.removeResidencySet(layer.residencySet)
        metalLogger.notice(
            "metal_shutdown_drained frames=\(self.presentedFrameCount) completion=\(self.completionEvent.signaledValue)"
        )
        if let renderFailure {
            throw renderFailure
        }
    }

    private func renderClearFrame(to drawable: any CAMetalDrawable) throws {
        let slot = frameSlots[frameIndex]
        if slot.completionValue != 0 {
            try waitForGPU(value: slot.completionValue)
        }
        slot.allocator.reset()

        let commandBuffer = slot.commandBuffer
        commandBuffer.beginCommandBuffer(allocator: slot.allocator)
        commandBuffer.pushDebugGroup("M3 Clear and Present")

        let pass = MTL4RenderPassDescriptor()
        let colorAttachment = pass.colorAttachments[0]
        colorAttachment?.texture = drawable.texture
        colorAttachment?.loadAction = .clear
        colorAttachment?.storeAction = .store
        colorAttachment?.clearColor = Self.clearColor

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else {
            commandBuffer.popDebugGroup()
            commandBuffer.endCommandBuffer()
            throw MetalRendererError.renderEncoderUnavailable
        }
        encoder.label = "SM64 Modern Clear Pass"
        encoder.pushDebugGroup("Clear drawable to SM64 blue")
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

        presentedFrameCount += 1
        if presentedFrameCount == 1 || presentedFrameCount.isMultiple(of: 600) {
            metalLogger.notice(
                "metal_presented frame=\(self.presentedFrameCount) drawable=\(drawable.texture.width)x\(drawable.texture.height)"
            )
        }

        if let drawableSize = consumeDrawableSize() {
            layer.drawableSize = drawableSize
            metalLogger.notice("metal_resize_applied drawable=\(Int(drawableSize.width))x\(Int(drawableSize.height))")
        }
        frameIndex = (frameIndex + 1) % frameSlots.count
    }

    private func waitForGPU(value: UInt64) throws {
        guard completionEvent.signaledValue < value else { return }
        guard completionEvent.wait(untilSignaledValue: value, timeoutMS: Self.gpuWaitTimeoutMilliseconds) else {
            throw MetalRendererError.gpuDrainTimedOut(value: value)
        }
    }
}
