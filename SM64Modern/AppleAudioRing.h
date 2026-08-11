#ifndef SM64_MODERN_APPLE_AUDIO_RING_H
#define SM64_MODERN_APPLE_AUDIO_RING_H

#include <CoreAudioTypes/CoreAudioBaseTypes.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SM64ModernAudioRing SM64ModernAudioRing;

typedef struct SM64ModernAudioRingStats {
    uint64_t enqueued_frames;
    uint64_t rendered_frames;
    uint64_t underrun_frames;
    uint64_t dropped_frames;
    uint64_t render_calls;
} SM64ModernAudioRingStats;

SM64ModernAudioRing *SM64ModernAudioRingCreate(uint32_t capacity_frames);
void SM64ModernAudioRingDestroy(SM64ModernAudioRing *ring);

uint32_t SM64ModernAudioRingBufferedFrames(const SM64ModernAudioRing *ring);
uint32_t SM64ModernAudioRingWrite(SM64ModernAudioRing *ring,
                                  const int16_t *interleaved_stereo_samples,
                                  uint32_t frame_count,
                                  uint32_t backlog_ceiling_frames);

// The audio render thread receives a complete requested buffer: unread frames
// are zeroed and reported as an underrun rather than exposing stale memory.
uint32_t SM64ModernAudioRingRead(SM64ModernAudioRing *ring,
                                 int16_t *interleaved_stereo_output,
                                 uint32_t requested_frames,
                                 bool *out_is_silence) CA_REALTIME_API;

// The caller must first stop AVAudioEngine so the consumer cannot race reset.
void SM64ModernAudioRingDiscardBuffered(SM64ModernAudioRing *ring);
void SM64ModernAudioRingGetStats(const SM64ModernAudioRing *ring,
                                 SM64ModernAudioRingStats *out_stats);

#ifdef __cplusplus
}
#endif

#endif
