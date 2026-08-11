#ifndef SM64_MODERN_METAL_COMPILER_BRIDGE_H
#define SM64_MODERN_METAL_COMPILER_BRIDGE_H

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

id<MTLRenderPipelineState> _Nullable SM64ModernMakeRenderPipelineState(
    id<MTL4Compiler> compiler,
    MTL4PipelineDescriptor *descriptor,
    NSError **error
) API_AVAILABLE(macos(26.0));

void SM64ModernCopyBufferToTexture(
    id<MTL4ComputeCommandEncoder> encoder,
    id<MTLBuffer> source,
    NSUInteger sourceOffset,
    NSUInteger bytesPerRow,
    NSUInteger bytesPerImage,
    MTLSize sourceSize,
    id<MTLTexture> destination
) API_AVAILABLE(macos(26.0));

void SM64ModernBarrierBlitToFragmentProducer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
void SM64ModernBarrierBlitToFragmentConsumer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
NS_ASSUME_NONNULL_END

#endif
