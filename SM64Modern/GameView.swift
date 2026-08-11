import AppKit
import Metal
import QuartzCore

@MainActor
final class GameView: NSView {
    private var drawableSizeHandler: (@Sendable (CGSize) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureLayerOwnership()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayerOwnership()
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CAMetalLayer()
        layer.name = "SM64 Modern Drawable Surface"
        layer.isOpaque = true
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }

    override func layout() {
        super.layout()
        publishDrawableSize()
    }

    var metalLayer: CAMetalLayer {
        guard let layer = layer as? CAMetalLayer else {
            preconditionFailure("GameView must remain backed by CAMetalLayer")
        }
        return layer
    }

    func configureMetal(device: any MTLDevice) -> CGSize {
        let metalLayer = metalLayer
        metalLayer.device = device
        // M4 keeps the approved SDR surface and two-slot presentation contract;
        // scene format and pacing are sourced by the native Metal renderer.
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.maximumDrawableCount = 2
        metalLayer.displaySyncEnabled = true
        metalLayer.allowsNextDrawableTimeout = true
        metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)

        let size = drawableSize()
        metalLayer.drawableSize = size
        return size
    }

    func installDrawableSizeHandler(_ handler: @escaping @Sendable (CGSize) -> Void) {
        drawableSizeHandler = handler
    }

    func publishDrawableSize() {
        let size = drawableSize()
        guard size.width > 0, size.height > 0 else { return }
        if let drawableSizeHandler {
            drawableSizeHandler(size)
        } else {
            metalLayer.drawableSize = size
        }
    }

    private func drawableSize() -> CGSize {
        let pixelBounds = convertToBacking(bounds)
        return pixelBounds.size
    }

    private func configureLayerOwnership() {
        wantsLayer = true
        layerContentsRedrawPolicy = .duringViewResize
    }
}
