#ifndef SM64_MODERN_METAL_COMPILER_BRIDGE_H
#define SM64_MODERN_METAL_COMPILER_BRIDGE_H

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

id<MTLRenderPipelineState> _Nullable SM64ModernMakeRenderPipelineState(
    id<MTL4Compiler> compiler,
    MTL4PipelineDescriptor *descriptor,
    NSError **error
) API_AVAILABLE(macos(26.0));

typedef void (^SM64ModernRenderPipelineCompletion)(
    id<MTLRenderPipelineState> _Nullable state,
    NSError * _Nullable error
) API_AVAILABLE(macos(26.0));

void SM64ModernMakeRenderPipelineStateAsync(
    id<MTL4Compiler> compiler,
    MTL4PipelineDescriptor *descriptor,
    NSArray<id<MTL4Archive>> * _Nullable lookupArchives,
    SM64ModernRenderPipelineCompletion completion
) API_AVAILABLE(macos(26.0));

void SM64ModernWaitForRenderPipelineTasks(void) API_AVAILABLE(macos(26.0));

id<MTL4PipelineDataSetSerializer> _Nullable SM64ModernMakePipelineDataSetSerializer(
    id<MTLDevice> device
) API_AVAILABLE(macos(26.0));
id<MTL4Archive> _Nullable SM64ModernLoadArchive(
    id<MTLDevice> device,
    NSURL *url,
    NSError **error
) API_AVAILABLE(macos(26.0));
BOOL SM64ModernFlushPipelineDataSetSerializer(
    id<MTL4PipelineDataSetSerializer> serializer,
    NSURL *url,
    NSError **error
) API_AVAILABLE(macos(26.0));
NSData * _Nullable SM64ModernSerializePipelineDataSetScript(
    id<MTL4PipelineDataSetSerializer> serializer,
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

void SM64ModernCopyBufferToBuffer(
    id<MTL4ComputeCommandEncoder> encoder,
    id<MTLBuffer> source,
    NSUInteger sourceOffset,
    id<MTLBuffer> destination,
    NSUInteger destinationOffset,
    NSUInteger size
) API_AVAILABLE(macos(26.0));

void SM64ModernBarrierBlitToFragmentProducer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
void SM64ModernBarrierBlitToFragmentConsumer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
void SM64ModernBarrierBlitToVertexFragmentProducer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
void SM64ModernBarrierBlitToVertexFragmentConsumer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
void SM64ModernBarrierFragmentToFragmentProducer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
void SM64ModernBarrierFragmentToFragmentConsumer(id<MTL4CommandEncoder> encoder)
    API_AVAILABLE(macos(26.0));
NS_ASSUME_NONNULL_END

#endif
