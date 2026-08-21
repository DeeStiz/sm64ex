#import "AppleAudioService.h"

#include <Availability.h>
#import <AVFAudio/AVFAudio.h>
#import <pthread.h>
#import <stdatomic.h>

static NSString *const SM64ModernAppleAudioErrorDomain = @"io.github.deestiz.sm64modern.Audio";

// The core's legacy audio contract is 32 kHz interleaved s16 stereo. The
// desired/backlog values preserve the SDL backends' buffering policy; the
// power-of-two capacity leaves bounded headroom above that backlog ceiling.
enum {
    SM64ModernAudioSampleRate = 32000,
    SM64ModernAudioChannelCount = 2,
    SM64ModernAudioDesiredBufferedFrames = 1100,
    SM64ModernAudioBacklogCeilingFrames = 6000,
    SM64ModernAudioCapacityFrames = 8192,
};

typedef NS_ENUM(NSInteger, SM64ModernAppleAudioErrorCode) {
    SM64ModernAppleAudioErrorAllocation = 1,
    SM64ModernAppleAudioErrorOutputUnavailable = 3,
    SM64ModernAppleAudioErrorConnection = 4,
    SM64ModernAppleAudioErrorStart = 5,
};

static NSError *audio_error(SM64ModernAppleAudioErrorCode code, NSString *description) {
    return [NSError errorWithDomain:SM64ModernAppleAudioErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

@interface SM64ModernAppleAudioService () {
    AVAudioEngine *_engine;
    AVAudioSourceNode *_sourceNode;
    AVAudioFormat *_sourceFormat;
    SM64ModernAudioRing *_ring;
    _Atomic bool _configurationChangePending;
    uint64_t _ownerThread;
    BOOL _sourceAttached;
    BOOL _running;
    BOOL _observingConfiguration;
}
- (nullable instancetype)initPrivate;
@end

@implementation SM64ModernAppleAudioService

+ (nullable instancetype)makeAudioService {
    return [[self alloc] initPrivate];
}

- (nullable instancetype)initPrivate {
    self = [super init];
    if (!self) {
        return nil;
    }

    _ring = SM64ModernAudioRingCreate(SM64ModernAudioCapacityFrames);
    if (!_ring) {
        return nil;
    }
    atomic_init(&_configurationChangePending, false);

    _sourceFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                    sampleRate:SM64ModernAudioSampleRate
                                                      channels:SM64ModernAudioChannelCount
                                                   interleaved:YES];
    if (!_sourceFormat) {
        SM64ModernAudioRingDestroy(_ring);
        _ring = NULL;
        return nil;
    }

    SM64ModernAudioRing *renderRing = _ring;
    AVAudioSourceNodeRenderBlock renderBlock = ^OSStatus(BOOL *isSilence,
                                                         const AudioTimeStamp *timestamp,
                                                         AVAudioFrameCount frameCount,
                                                         AudioBufferList *outputData) {
        (void) timestamp;
        if (outputData->mNumberBuffers != 1
            || outputData->mBuffers[0].mNumberChannels != SM64ModernAudioChannelCount
            || !outputData->mBuffers[0].mData
            || outputData->mBuffers[0].mDataByteSize
                < frameCount * SM64ModernAudioChannelCount * sizeof(int16_t)) {
            *isSilence = YES;
            return kAudio_ParamError;
        }
        bool silence = false;
        SM64ModernAudioRingRead(renderRing,
                                outputData->mBuffers[0].mData,
                                frameCount,
                                &silence);
        *isSilence = silence;
        return noErr;
    };
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 270000
    _sourceNode = [[AVAudioSourceNode alloc]
        initWithFormat:_sourceFormat
        realtimeSafeRenderBlock:(AVAudioSourceNodeRenderBlockRealtimeSafe)renderBlock];
#else
    _sourceNode = [[AVAudioSourceNode alloc]
        initWithFormat:_sourceFormat
        renderBlock:renderBlock];
#endif
    if (!_sourceNode) {
        SM64ModernAudioRingDestroy(_ring);
        _ring = NULL;
        return nil;
    }

    _engine = [[AVAudioEngine alloc] init];
    return self;
}

- (void)dealloc {
    if (_observingConfiguration) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVAudioEngineConfigurationChangeNotification
                                                      object:_engine];
    }
    if (_engine.isRunning) {
        [_engine stop];
    }
    SM64ModernAudioRingDestroy(_ring);
}

- (BOOL)startAndReturnError:(NSError **)error {
    if (_running) {
        return YES;
    }
    if (!_ring || !_sourceNode || !_engine) {
        if (error) {
            *error = audio_error(SM64ModernAppleAudioErrorAllocation,
                                 @"Could not allocate the native audio service");
        }
        return NO;
    }

    _ownerThread = [self currentThreadIdentifier];
    if (!_observingConfiguration) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioEngineConfigurationChanged:)
                                                     name:AVAudioEngineConfigurationChangeNotification
                                                   object:_engine];
        _observingConfiguration = YES;
    }
    return [self startGraphAndReturnError:error];
}

- (BOOL)recoverIfNeededAndReturnError:(NSError **)error {
    [self assertOwnerThread];
    // Consume only the notification observed before this recovery attempt. A
    // second route change racing graph restart remains set for the next tick.
    const bool recoveryPending = atomic_exchange_explicit(&_configurationChangePending,
                                                           false,
                                                           memory_order_acq_rel);
    if (!recoveryPending && _engine.isRunning) {
        return YES;
    }

    [_engine stop];
    _running = NO;
    SM64ModernAudioRingDiscardBuffered(_ring);
    if (_sourceAttached) {
        [_engine disconnectNodeOutput:_sourceNode];
    }
    if (![self startGraphAndReturnError:error]) {
        return NO;
    }
    return YES;
}

- (void)stop {
    if (_ownerThread != 0) {
        [self assertOwnerThread];
    }
    if (_observingConfiguration) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVAudioEngineConfigurationChangeNotification
                                                      object:_engine];
        _observingConfiguration = NO;
    }
    [_engine stop];
    _running = NO;
    if (_sourceAttached) {
        [_engine detachNode:_sourceNode];
        _sourceAttached = NO;
    }
    SM64ModernAudioRingDiscardBuffered(_ring);
    atomic_store_explicit(&_configurationChangePending, false, memory_order_release);
}

- (int32_t)bufferedFrames {
    [self assertOwnerThread];
    return (int32_t) SM64ModernAudioRingBufferedFrames(_ring);
}

- (uint32_t)desiredBufferedFrames {
    [self assertOwnerThread];
    return SM64ModernAudioDesiredBufferedFrames;
}

- (BOOL)recoveryPending {
    [self assertOwnerThread];
    return atomic_load_explicit(&_configurationChangePending, memory_order_acquire);
}

- (void)enqueueInterleavedStereoSamples:(const int16_t *)samples
                             frameCount:(uint32_t)frameCount {
    [self assertOwnerThread];
    SM64ModernAudioRingWrite(_ring,
                             samples,
                             frameCount,
                             SM64ModernAudioBacklogCeilingFrames);
}

- (SM64ModernAppleAudioStatus)audioStatus {
    [self assertOwnerThread];
    const AVAudioFormat *outputFormat = [_engine.outputNode outputFormatForBus:0];
    SM64ModernAppleAudioStatus status = {
        .buffered_frames = SM64ModernAudioRingBufferedFrames(_ring),
        .desired_buffered_frames = SM64ModernAudioDesiredBufferedFrames,
        .capacity_frames = SM64ModernAudioCapacityFrames,
        .backlog_ceiling_frames = SM64ModernAudioBacklogCeilingFrames,
        .output_sample_rate = outputFormat.sampleRate,
        .output_channel_count = outputFormat.channelCount,
        .running = _engine.isRunning,
        .recovery_pending = atomic_load_explicit(&_configurationChangePending,
                                                  memory_order_acquire),
    };
    SM64ModernAudioRingGetStats(_ring, &status.ring);
    return status;
}

- (BOOL)startGraphAndReturnError:(NSError **)error {
    [self assertOwnerThread];
    const AVAudioFormat *outputFormat = [_engine.outputNode outputFormatForBus:0];
    if (outputFormat.sampleRate <= 0 || outputFormat.channelCount == 0) {
        if (error) {
            *error = audio_error(SM64ModernAppleAudioErrorOutputUnavailable,
                                 @"The default audio output is unavailable");
        }
        return NO;
    }

    if (!_sourceAttached) {
        [_engine attachNode:_sourceNode];
        _sourceAttached = YES;
    }

#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 270000
    NSError *connectionError = nil;
    if (![_engine connect:_sourceNode
                        to:_engine.mainMixerNode
                    format:nil
                     error:&connectionError]) {
        if (error) {
            *error = connectionError ?: audio_error(SM64ModernAppleAudioErrorConnection,
                                                      @"Could not connect the audio source node");
        }
        return NO;
    }
#else
    // macOS 26.x SDKs expose only the legacy void connection API. Verify the
    // resulting graph when possible; unlike the newer API, this call cannot
    // provide an NSError for a rejected connection.
    [_engine connect:_sourceNode
                  to:_engine.mainMixerNode
              format:nil];
    BOOL sourceConnected = NO;
    for (AVAudioConnectionPoint *connection in
         [_engine outputConnectionPointsForNode:_sourceNode outputBus:0]) {
        if (connection.node == _engine.mainMixerNode) {
            sourceConnected = YES;
            break;
        }
    }
    if (!sourceConnected) {
        if (error) {
            *error = audio_error(SM64ModernAppleAudioErrorConnection,
                                  @"Could not connect the audio source node");
        }
        return NO;
    }
#endif

    [_engine prepare];
    NSError *startError = nil;
    if (![_engine startAndReturnError:&startError]) {
        if (error) {
            *error = startError ?: audio_error(SM64ModernAppleAudioErrorStart,
                                                @"Could not start AVAudioEngine");
        }
        return NO;
    }
    _running = YES;
    return YES;
}

- (void)audioEngineConfigurationChanged:(NSNotification *)notification {
    (void) notification;
    // Apple posts this on an internal queue and forbids synchronous teardown
    // there. The owner thread performs all graph mutations on its next tick.
    atomic_store_explicit(&_configurationChangePending, true, memory_order_release);
}

- (uint64_t)currentThreadIdentifier {
    uint64_t identifier = 0;
    const int result = pthread_threadid_np(NULL, &identifier);
    NSCAssert(result == 0, @"pthread_threadid_np must produce an owner token");
    return identifier;
}

- (void)assertOwnerThread {
    NSCAssert(_ownerThread != 0 && _ownerThread == [self currentThreadIdentifier],
              @"Native audio lifecycle and producer calls require the engine owner thread");
}

@end
