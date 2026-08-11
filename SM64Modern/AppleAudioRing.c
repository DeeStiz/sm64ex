#include "AppleAudioRing.h"

#include <stdatomic.h>
#include <stddef.h>
#include <stdlib.h>

enum { SM64_MODERN_AUDIO_CHANNEL_COUNT = 2 };

_Static_assert(ATOMIC_LONG_LOCK_FREE == 2,
               "SM64 Modern requires lock-free 64-bit atomics on Apple Silicon");

struct SM64ModernAudioRing {
    uint32_t capacity_frames;
    uint32_t frame_mask;
    int16_t *samples;
    _Atomic uint64_t read_index;
    _Atomic uint64_t write_index;
    _Atomic uint64_t enqueued_frames;
    _Atomic uint64_t rendered_frames;
    _Atomic uint64_t underrun_frames;
    _Atomic uint64_t dropped_frames;
    _Atomic uint64_t render_calls;
};

static bool is_power_of_two(uint32_t value) {
    return value >= 2 && (value & (value - 1)) == 0;
}

static uint32_t clamped_distance(uint64_t write_index,
                                 uint64_t read_index,
                                 uint32_t capacity_frames) {
    const uint64_t distance = write_index - read_index;
    return distance > capacity_frames ? capacity_frames : (uint32_t) distance;
}

SM64ModernAudioRing *SM64ModernAudioRingCreate(uint32_t capacity_frames) {
    if (!is_power_of_two(capacity_frames)) {
        return NULL;
    }

    SM64ModernAudioRing *ring = calloc(1, sizeof(*ring));
    if (!ring) {
        return NULL;
    }
    ring->samples = calloc((size_t) capacity_frames * SM64_MODERN_AUDIO_CHANNEL_COUNT,
                           sizeof(*ring->samples));
    if (!ring->samples) {
        free(ring);
        return NULL;
    }
    ring->capacity_frames = capacity_frames;
    ring->frame_mask = capacity_frames - 1;
    atomic_init(&ring->read_index, 0);
    atomic_init(&ring->write_index, 0);
    atomic_init(&ring->enqueued_frames, 0);
    atomic_init(&ring->rendered_frames, 0);
    atomic_init(&ring->underrun_frames, 0);
    atomic_init(&ring->dropped_frames, 0);
    atomic_init(&ring->render_calls, 0);

    return ring;
}

void SM64ModernAudioRingDestroy(SM64ModernAudioRing *ring) {
    if (!ring) {
        return;
    }
    free(ring->samples);
    free(ring);
}

uint32_t SM64ModernAudioRingBufferedFrames(const SM64ModernAudioRing *ring) {
    if (!ring) {
        return 0;
    }
    const uint64_t write_index = atomic_load_explicit(&ring->write_index, memory_order_acquire);
    const uint64_t read_index = atomic_load_explicit(&ring->read_index, memory_order_acquire);
    return clamped_distance(write_index, read_index, ring->capacity_frames);
}

uint32_t SM64ModernAudioRingWrite(SM64ModernAudioRing *ring,
                                  const int16_t *samples,
                                  uint32_t frame_count,
                                  uint32_t backlog_ceiling_frames) {
    if (!ring || (!samples && frame_count != 0)) {
        return 0;
    }
    if (frame_count == 0) {
        return 0;
    }

    const uint64_t write_index = atomic_load_explicit(&ring->write_index, memory_order_relaxed);
    const uint64_t read_index = atomic_load_explicit(&ring->read_index, memory_order_acquire);
    const uint32_t buffered = clamped_distance(write_index, read_index, ring->capacity_frames);
    const uint32_t available = ring->capacity_frames - buffered;

    // Match the SDL backend's low-latency policy: once the backlog ceiling is
    // reached, discard new audio instead of overwriting unread older frames.
    if (buffered >= backlog_ceiling_frames || frame_count > available) {
        atomic_fetch_add_explicit(&ring->dropped_frames, frame_count, memory_order_relaxed);
        return 0;
    }

    for (uint32_t frame = 0; frame < frame_count; frame++) {
        const uint32_t destination_frame = (uint32_t) (write_index + frame) & ring->frame_mask;
        ring->samples[destination_frame * 2] = samples[frame * 2];
        ring->samples[destination_frame * 2 + 1] = samples[frame * 2 + 1];
    }

    atomic_store_explicit(&ring->write_index, write_index + frame_count, memory_order_release);
    atomic_fetch_add_explicit(&ring->enqueued_frames, frame_count, memory_order_relaxed);
    return frame_count;
}

uint32_t SM64ModernAudioRingRead(SM64ModernAudioRing *ring,
                                 int16_t *output,
                                 uint32_t requested_frames,
                                 bool *out_is_silence) {
    if (!ring || !output || !out_is_silence) {
        return 0;
    }

    const uint64_t read_index = atomic_load_explicit(&ring->read_index, memory_order_relaxed);
    const uint64_t write_index = atomic_load_explicit(&ring->write_index, memory_order_acquire);
    const uint32_t buffered = clamped_distance(write_index, read_index, ring->capacity_frames);
    const uint32_t copied_frames = buffered < requested_frames ? buffered : requested_frames;

    for (uint32_t frame = 0; frame < copied_frames; frame++) {
        const uint32_t source_frame = (uint32_t) (read_index + frame) & ring->frame_mask;
        output[frame * 2] = ring->samples[source_frame * 2];
        output[frame * 2 + 1] = ring->samples[source_frame * 2 + 1];
    }
    for (uint32_t frame = copied_frames; frame < requested_frames; frame++) {
        output[frame * 2] = 0;
        output[frame * 2 + 1] = 0;
    }

    atomic_store_explicit(&ring->read_index, read_index + copied_frames, memory_order_release);
    atomic_fetch_add_explicit(&ring->render_calls, 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&ring->rendered_frames, copied_frames, memory_order_relaxed);
    atomic_fetch_add_explicit(&ring->underrun_frames,
                              requested_frames - copied_frames,
                              memory_order_relaxed);
    *out_is_silence = copied_frames == 0;
    return copied_frames;
}

void SM64ModernAudioRingDiscardBuffered(SM64ModernAudioRing *ring) {
    if (!ring) {
        return;
    }
    const uint64_t write_index = atomic_load_explicit(&ring->write_index, memory_order_acquire);
    atomic_store_explicit(&ring->read_index, write_index, memory_order_release);
}

void SM64ModernAudioRingGetStats(const SM64ModernAudioRing *ring,
                                 SM64ModernAudioRingStats *out_stats) {
    if (!out_stats) {
        return;
    }
    if (!ring) {
        *out_stats = (SM64ModernAudioRingStats) { 0 };
        return;
    }
    out_stats->enqueued_frames = atomic_load_explicit(&ring->enqueued_frames, memory_order_relaxed);
    out_stats->rendered_frames = atomic_load_explicit(&ring->rendered_frames, memory_order_relaxed);
    out_stats->underrun_frames = atomic_load_explicit(&ring->underrun_frames, memory_order_relaxed);
    out_stats->dropped_frames = atomic_load_explicit(&ring->dropped_frames, memory_order_relaxed);
    out_stats->render_calls = atomic_load_explicit(&ring->render_calls, memory_order_relaxed);
}
