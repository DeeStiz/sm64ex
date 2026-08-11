import Foundation

private func renderingHost(from context: UnsafeMutableRawPointer?) -> EngineHost? {
    guard let context else { return nil }
    return Unmanaged<EngineHost>.fromOpaque(context).takeUnretainedValue()
}

func makeMetalRenderingAPI(host: EngineHost) -> SM64ModernRenderingApiV1 {
    var api = SM64ModernRenderingApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernRenderingApiV1>.size)
    api.context = Unmanaged.passUnretained(host).toOpaque()
    api.initialize = renderingInitialize
    api.shutdown = renderingShutdown
    api.create_shader = renderingCreateShader
    api.select_shader = renderingSelectShader
    api.create_texture = renderingCreateTexture
    api.select_texture = renderingSelectTexture
    api.upload_texture = renderingUploadTexture
    api.set_sampler_parameters = renderingSetSampler
    api.set_depth_test = renderingSetDepthTest
    api.set_depth_mask = renderingSetDepthMask
    api.set_zmode_decal = renderingSetDecal
    api.set_viewport = renderingSetViewport
    api.set_scissor = renderingSetScissor
    api.set_use_alpha = renderingSetAlpha
    api.draw_triangles = renderingDraw
    api.start_frame = renderingStartFrame
    api.end_frame = renderingEndFrame
    api.finish_render = renderingFinish
    api.get_dimensions = renderingGetDimensions
    return api
}

private func renderingInitialize(_ context: UnsafeMutableRawPointer?, _ filteringMode: UInt32) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingInitialize(filteringMode: filteringMode) ?? SM64_MODERN_STATUS_INVALID_STATE
}

private func renderingShutdown(_ context: UnsafeMutableRawPointer?) {
    renderingHost(from: context)?.renderingShutdown()
}

private func renderingCreateShader(
    _ context: UnsafeMutableRawPointer?,
    _ shaderID: UInt32,
    _ filteringMode: UInt32,
    _ inputCount: UInt32,
    _ textureMask: UInt32
) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingCreateShader(
        id: shaderID,
        filteringMode: filteringMode,
        inputCount: inputCount,
        textureMask: textureMask
    ) ?? SM64_MODERN_STATUS_INVALID_STATE
}

private func renderingSelectShader(_ context: UnsafeMutableRawPointer?, _ shaderID: UInt32) {
    renderingHost(from: context)?.renderingSelectShader(shaderID)
}

private func renderingCreateTexture(_ context: UnsafeMutableRawPointer?, _ textureID: UInt32) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingCreateTexture(textureID) ?? SM64_MODERN_STATUS_INVALID_STATE
}

private func renderingSelectTexture(_ context: UnsafeMutableRawPointer?, _ tile: UInt32, _ textureID: UInt32) {
    renderingHost(from: context)?.renderingSelectTexture(tile: tile, id: textureID)
}

private func renderingUploadTexture(
    _ context: UnsafeMutableRawPointer?,
    _ tile: UInt32,
    _ textureID: UInt32,
    _ pixels: UnsafePointer<UInt8>?,
    _ width: UInt32,
    _ height: UInt32
) -> SM64ModernStatus {
    guard let pixels else { return SM64_MODERN_STATUS_INVALID_ARGUMENT }
    return renderingHost(from: context)?.renderingUploadTexture(id: textureID, pixels: pixels, width: width, height: height)
        ?? SM64_MODERN_STATUS_INVALID_STATE
}

private func renderingSetSampler(
    _ context: UnsafeMutableRawPointer?,
    _ tile: UInt32,
    _ textureID: UInt32,
    _ linear: UInt32,
    _ wrapS: UInt32,
    _ wrapT: UInt32
) {
    renderingHost(from: context)?.renderingSetSampler(tile: tile, linear: linear != 0, wrapS: wrapS, wrapT: wrapT)
}

private func renderingSetDepthTest(_ context: UnsafeMutableRawPointer?, _ enabled: UInt32) {
    renderingHost(from: context)?.renderingSetDepthTest(enabled != 0)
}
private func renderingSetDepthMask(_ context: UnsafeMutableRawPointer?, _ enabled: UInt32) {
    renderingHost(from: context)?.renderingSetDepthWrite(enabled != 0)
}
private func renderingSetDecal(_ context: UnsafeMutableRawPointer?, _ enabled: UInt32) {
    renderingHost(from: context)?.renderingSetDecal(enabled != 0)
}
private func renderingSetAlpha(_ context: UnsafeMutableRawPointer?, _ enabled: UInt32) {
    renderingHost(from: context)?.renderingSetAlphaBlend(enabled != 0)
}

private func renderingSetViewport(
    _ context: UnsafeMutableRawPointer?, _ x: Int32, _ y: Int32, _ width: Int32, _ height: Int32
) {
    renderingHost(from: context)?.renderingSetViewport(MetalRect(x: x, y: y, width: width, height: height))
}

private func renderingSetScissor(
    _ context: UnsafeMutableRawPointer?, _ x: Int32, _ y: Int32, _ width: Int32, _ height: Int32
) {
    renderingHost(from: context)?.renderingSetScissor(MetalRect(x: x, y: y, width: width, height: height))
}

private func renderingDraw(
    _ context: UnsafeMutableRawPointer?,
    _ vertices: UnsafePointer<Float>?,
    _ floatCount: UInt32,
    _ triangleCount: UInt32
) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingDraw(vertices: vertices, floatCount: floatCount, triangleCount: triangleCount)
        ?? SM64_MODERN_STATUS_INVALID_STATE
}

private func renderingStartFrame(_ context: UnsafeMutableRawPointer?) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingStartFrame() ?? SM64_MODERN_STATUS_INVALID_STATE
}
private func renderingEndFrame(_ context: UnsafeMutableRawPointer?) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingEndFrame() ?? SM64_MODERN_STATUS_INVALID_STATE
}
private func renderingFinish(_ context: UnsafeMutableRawPointer?) -> SM64ModernStatus {
    renderingHost(from: context)?.renderingFinish() ?? SM64_MODERN_STATUS_INVALID_STATE
}

private func renderingGetDimensions(
    _ context: UnsafeMutableRawPointer?,
    _ width: UnsafeMutablePointer<UInt32>?,
    _ height: UnsafeMutablePointer<UInt32>?
) {
    guard let dimensions = renderingHost(from: context)?.renderingDimensions() else { return }
    width?.pointee = dimensions.0
    height?.pointee = dimensions.1
}
