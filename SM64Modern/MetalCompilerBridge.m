#import "MetalCompilerBridge.h"

id<MTLRenderPipelineState> _Nullable SM64ModernMakeRenderPipelineState(
    id<MTL4Compiler> compiler,
    MTL4PipelineDescriptor *descriptor,
    NSError **error
) {
    return [compiler newRenderPipelineStateWithDescriptor:descriptor
                                      compilerTaskOptions:nil
                                                    error:error];
}

void SM64ModernCopyBufferToTexture(
    id<MTL4ComputeCommandEncoder> encoder,
    id<MTLBuffer> source,
    NSUInteger sourceOffset,
    NSUInteger bytesPerRow,
    NSUInteger bytesPerImage,
    MTLSize sourceSize,
    id<MTLTexture> destination
) {
    [encoder copyFromBuffer:source
               sourceOffset:sourceOffset
          sourceBytesPerRow:bytesPerRow
        sourceBytesPerImage:bytesPerImage
                 sourceSize:sourceSize
                  toTexture:destination
           destinationSlice:0
           destinationLevel:0
          destinationOrigin:MTLOriginMake(0, 0, 0)];
}

void SM64ModernBarrierBlitToFragmentProducer(id<MTL4CommandEncoder> encoder) {
    [encoder barrierAfterStages:MTLStageBlit
              beforeQueueStages:MTLStageFragment
              visibilityOptions:MTL4VisibilityOptionDevice];
}

void SM64ModernBarrierBlitToFragmentConsumer(id<MTL4CommandEncoder> encoder) {
    [encoder barrierAfterQueueStages:MTLStageBlit
                        beforeStages:MTLStageFragment
                   visibilityOptions:MTL4VisibilityOptionDevice];
}
