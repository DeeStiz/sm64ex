#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "AppleAudioRing.h"

static int failures;

enum { CONCURRENT_FRAME_COUNT = 20000 };

struct ConcurrentRingTest {
    SM64ModernAudioRing *ring;
    atomic_bool failed;
    atomic_bool producer_done;
};

static void expect_true(const char *operation, bool value) {
    if (!value) {
        fprintf(stderr, "%s failed\n", operation);
        failures++;
    }
}

static void expect_u64(const char *operation, uint64_t actual, uint64_t expected) {
    if (actual != expected) {
        fprintf(stderr, "%s: expected %llu, got %llu\n",
                operation,
                (unsigned long long) expected,
                (unsigned long long) actual);
        failures++;
    }
}

static void fill_frames(int16_t *samples, uint32_t frames, int16_t first_value) {
    for (uint32_t frame = 0; frame < frames; frame++) {
        samples[frame * 2] = first_value + (int16_t) (frame * 2);
        samples[frame * 2 + 1] = first_value + (int16_t) (frame * 2 + 1);
    }
}

static void *produce_concurrently(void *context) {
    struct ConcurrentRingTest *test = context;
    for (uint32_t frame = 0; frame < CONCURRENT_FRAME_COUNT; frame++) {
        const int16_t samples[2] = {
            (int16_t) frame,
            (int16_t) (frame * 3u),
        };
        while (SM64ModernAudioRingWrite(test->ring, samples, 1, 1024) == 0) {
            if (atomic_load_explicit(&test->failed, memory_order_relaxed)) {
                return NULL;
            }
            sched_yield();
        }
    }
    atomic_store_explicit(&test->producer_done, true, memory_order_release);
    return NULL;
}

static void *consume_concurrently(void *context) {
    struct ConcurrentRingTest *test = context;
    for (uint32_t frame = 0; frame < CONCURRENT_FRAME_COUNT; frame++) {
        int16_t output[2];
        bool is_silence = false;
        while (SM64ModernAudioRingBufferedFrames(test->ring) == 0) {
            if (atomic_load_explicit(&test->producer_done, memory_order_acquire)) {
                atomic_store_explicit(&test->failed, true, memory_order_relaxed);
                return NULL;
            }
            sched_yield();
        }
        if (SM64ModernAudioRingRead(test->ring, output, 1, &is_silence) != 1
            || is_silence
            || (uint16_t) output[0] != (uint16_t) frame
            || (uint16_t) output[1] != (uint16_t) (frame * 3u)) {
            atomic_store_explicit(&test->failed, true, memory_order_relaxed);
            return NULL;
        }
    }
    return NULL;
}

int main(void) {
    int16_t first[10];
    int16_t wrapped[10];
    int16_t output[16];
    bool is_silence = false;
    SM64ModernAudioRingStats stats;

    expect_true("reject non-power-of-two capacity", SM64ModernAudioRingCreate(7) == NULL);
    SM64ModernAudioRing *ring = SM64ModernAudioRingCreate(8);
    expect_true("create ring", ring != NULL);
    if (!ring) {
        return 1;
    }

    fill_frames(first, 5, 10);
    expect_u64("write initial frames", SM64ModernAudioRingWrite(ring, first, 5, 6), 5);
    expect_u64("initial buffered frames", SM64ModernAudioRingBufferedFrames(ring), 5);
    expect_u64("read initial prefix", SM64ModernAudioRingRead(ring, output, 3, &is_silence), 3);
    expect_true("initial read is not silence", !is_silence);
    for (uint32_t sample = 0; sample < 6; sample++) {
        expect_u64("initial sample order", (uint16_t) output[sample], (uint16_t) first[sample]);
    }

    fill_frames(wrapped, 5, 100);
    expect_u64("write wrapped frames", SM64ModernAudioRingWrite(ring, wrapped, 5, 6), 5);
    expect_u64("wrapped buffered frames", SM64ModernAudioRingBufferedFrames(ring), 7);
    expect_u64("read wrapped sequence", SM64ModernAudioRingRead(ring, output, 7, &is_silence), 7);
    for (uint32_t sample = 0; sample < 4; sample++) {
        expect_u64("wrapped old samples", (uint16_t) output[sample], (uint16_t) first[sample + 6]);
    }
    for (uint32_t sample = 0; sample < 10; sample++) {
        expect_u64("wrapped new samples", (uint16_t) output[sample + 4], (uint16_t) wrapped[sample]);
    }

    for (uint32_t sample = 0; sample < 8; sample++) {
        output[sample] = 1;
    }
    expect_u64("underrun copied frames", SM64ModernAudioRingRead(ring, output, 4, &is_silence), 0);
    expect_true("empty read is silence", is_silence);
    for (uint32_t sample = 0; sample < 8; sample++) {
        expect_u64("underrun zero fill", (uint16_t) output[sample], 0);
    }

    expect_u64("write partial underrun prefix", SM64ModernAudioRingWrite(ring, first, 2, 6), 2);
    expect_u64("partial underrun copied frames", SM64ModernAudioRingRead(ring, output, 4, &is_silence), 2);
    expect_true("partial underrun is not all silence", !is_silence);
    for (uint32_t sample = 0; sample < 4; sample++) {
        expect_u64("partial underrun sample order", (uint16_t) output[sample], (uint16_t) first[sample]);
    }
    for (uint32_t sample = 4; sample < 8; sample++) {
        expect_u64("partial underrun zero fill", (uint16_t) output[sample], 0);
    }

    int16_t seven_frames[14];
    fill_frames(seven_frames, 7, 200);
    expect_u64("write backlog", SM64ModernAudioRingWrite(ring, seven_frames, 7, 6), 7);
    expect_u64("drop above backlog ceiling", SM64ModernAudioRingWrite(ring, first, 2, 6), 0);
    SM64ModernAudioRingDiscardBuffered(ring);
    expect_u64("discard buffered frames", SM64ModernAudioRingBufferedFrames(ring), 0);

    expect_u64("write before capacity drop", SM64ModernAudioRingWrite(ring, first, 5, 6), 5);
    expect_u64("drop block larger than capacity", SM64ModernAudioRingWrite(ring, wrapped, 5, 6), 0);

    SM64ModernAudioRingGetStats(ring, &stats);
    expect_u64("enqueued stats", stats.enqueued_frames, 24);
    expect_u64("rendered stats", stats.rendered_frames, 12);
    expect_u64("underrun stats", stats.underrun_frames, 6);
    expect_u64("dropped stats", stats.dropped_frames, 7);
    expect_u64("render-call stats", stats.render_calls, 4);

    SM64ModernAudioRingDestroy(ring);

    struct ConcurrentRingTest concurrent = {
        .ring = SM64ModernAudioRingCreate(1024),
    };
    atomic_init(&concurrent.failed, false);
    atomic_init(&concurrent.producer_done, false);
    expect_true("create concurrent ring", concurrent.ring != NULL);
    if (concurrent.ring) {
        pthread_t producer;
        pthread_t consumer;
        const int producer_result = pthread_create(&producer, NULL, produce_concurrently, &concurrent);
        const int consumer_result = producer_result == 0
            ? pthread_create(&consumer, NULL, consume_concurrently, &concurrent)
            : producer_result;
        expect_u64("start concurrent producer", (uint64_t) producer_result, 0);
        expect_u64("start concurrent consumer", (uint64_t) consumer_result, 0);
        if (producer_result == 0) {
            if (consumer_result != 0) {
                pthread_cancel(producer);
            }
            pthread_join(producer, NULL);
        }
        if (consumer_result == 0) {
            pthread_join(consumer, NULL);
        }
        expect_true("concurrent SPSC sample order",
                    !atomic_load_explicit(&concurrent.failed, memory_order_relaxed));
        SM64ModernAudioRingDestroy(concurrent.ring);
    }
    if (failures) {
        fprintf(stderr, "SM64 Modern audio ring smoke failed: %d failure(s)\n", failures);
        return 1;
    }
    puts("SM64 Modern audio ring smoke passed");
    return 0;
}
