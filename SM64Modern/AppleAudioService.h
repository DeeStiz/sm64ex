#ifndef SM64_MODERN_APPLE_AUDIO_SERVICE_H
#define SM64_MODERN_APPLE_AUDIO_SERVICE_H

#import <Foundation/Foundation.h>

#import "AppleAudioRing.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct SM64ModernAppleAudioStatus {
    uint32_t buffered_frames;
    uint32_t desired_buffered_frames;
    uint32_t capacity_frames;
    uint32_t backlog_ceiling_frames;
    double output_sample_rate;
    uint32_t output_channel_count;
    bool running;
    bool recovery_pending;
    SM64ModernAudioRingStats ring;
} SM64ModernAppleAudioStatus;

// Swift owns this service's lifecycle, but the realtime render block is kept
// entirely in Objective-C/C because macOS 27 disallows Swift realtime blocks.
@interface SM64ModernAppleAudioService : NSObject

+ (nullable instancetype)makeAudioService NS_SWIFT_NAME(makeAudioService());
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)startAndReturnError:(NSError **)error NS_SWIFT_NAME(start());
- (BOOL)recoverIfNeededAndReturnError:(NSError **)error NS_SWIFT_NAME(recoverIfNeeded());
- (void)stop;

- (int32_t)bufferedFrames;
- (uint32_t)desiredBufferedFrames;
- (BOOL)recoveryPending;
- (void)enqueueInterleavedStereoSamples:(const int16_t *)samples
                             frameCount:(uint32_t)frameCount;
- (SM64ModernAppleAudioStatus)audioStatus;

@end

NS_ASSUME_NONNULL_END

#endif
