#import "MetalCompilerBridge.h"

static NSLock *sSM64ModernCompilerTaskLock;
static NSMutableArray<id<MTL4CompilerTask>> *sSM64ModernCompilerTasks;

static void SM64ModernEnsureCompilerTaskStore(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSM64ModernCompilerTaskLock = [NSLock new];
        sSM64ModernCompilerTasks = [NSMutableArray array];
    });
}

id<MTLRenderPipelineState> _Nullable SM64ModernMakeRenderPipelineState(
    id<MTL4Compiler> compiler,
    MTL4PipelineDescriptor *descriptor,
    NSError **error
) {
    return [compiler newRenderPipelineStateWithDescriptor:descriptor
                                      compilerTaskOptions:nil
                                                    error:error];
}

void SM64ModernMakeRenderPipelineStateAsync(
    id<MTL4Compiler> compiler,
    MTL4PipelineDescriptor *descriptor,
    NSArray<id<MTL4Archive>> * _Nullable lookupArchives,
    SM64ModernRenderPipelineCompletion completion
) {
    SM64ModernEnsureCompilerTaskStore();
    MTL4CompilerTaskOptions *options = [MTL4CompilerTaskOptions new];
    options.lookupArchives = lookupArchives;
    __block id<MTL4CompilerTask> task = nil;
    task = [compiler newRenderPipelineStateWithDescriptor:descriptor
                                      compilerTaskOptions:options
                                         completionHandler:^(id<MTLRenderPipelineState> state, NSError *error) {
        completion(state, error);
        [sSM64ModernCompilerTaskLock lock];
        if (task) { [sSM64ModernCompilerTasks removeObject:task]; }
        [sSM64ModernCompilerTaskLock unlock];
    }];
    [sSM64ModernCompilerTaskLock lock];
    [sSM64ModernCompilerTasks addObject:task];
    [sSM64ModernCompilerTaskLock unlock];
}

void SM64ModernWaitForRenderPipelineTasks(void) {
    SM64ModernEnsureCompilerTaskStore();
    while (YES) {
        [sSM64ModernCompilerTaskLock lock];
        NSArray<id<MTL4CompilerTask>> *tasks = [sSM64ModernCompilerTasks copy];
        [sSM64ModernCompilerTaskLock unlock];
        if (tasks.count == 0) { return; }
        for (id<MTL4CompilerTask> task in tasks) {
            [task waitUntilCompleted];
        }
    }
}

id<MTL4PipelineDataSetSerializer> _Nullable SM64ModernMakePipelineDataSetSerializer(
    id<MTLDevice> device
) {
    MTL4PipelineDataSetSerializerDescriptor *descriptor =
        [MTL4PipelineDataSetSerializerDescriptor new];
    descriptor.configuration = MTL4PipelineDataSetSerializerConfigurationCaptureDescriptors
        | MTL4PipelineDataSetSerializerConfigurationCaptureBinaries;
    return [device newPipelineDataSetSerializerWithDescriptor:descriptor];
}

id<MTL4Archive> _Nullable SM64ModernLoadArchive(
    id<MTLDevice> device,
    NSURL *url,
    NSError **error
) {
    return [device newArchiveWithURL:url error:error];
}

BOOL SM64ModernFlushPipelineDataSetSerializer(
    id<MTL4PipelineDataSetSerializer> serializer,
    NSURL *url,
    NSError **error
) {
    return [serializer serializeAsArchiveAndFlushToURL:url error:error];
}

NSData * _Nullable SM64ModernSerializePipelineDataSetScript(
    id<MTL4PipelineDataSetSerializer> serializer,
    NSError **error
) {
    return [serializer serializeAsPipelinesScriptWithError:error];
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
