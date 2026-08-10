import AppKit
import QuartzCore

@MainActor
final class GameView: NSView {
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
        updateDrawableSize()
    }

    var metalLayer: CAMetalLayer {
        guard let layer = layer as? CAMetalLayer else {
            preconditionFailure("GameView must remain backed by CAMetalLayer")
        }
        return layer
    }

    func updateDrawableSize() {
        let pixelBounds = convertToBacking(bounds)
        guard pixelBounds.width > 0, pixelBounds.height > 0 else { return }
        metalLayer.drawableSize = pixelBounds.size
    }

    private func configureLayerOwnership() {
        wantsLayer = true
        layerContentsRedrawPolicy = .duringViewResize
    }
}
