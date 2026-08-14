#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u8(uint64_t hash, uint8_t value) { return (hash ^ value) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t hash, uint16_t value) {
    for (unsigned byte = 0; byte < 2; ++byte) { hash ^= (value >> (byte * 8u)) & 0xffu; hash *= FNV_PRIME; }
    return hash;
}

struct item { uint8_t mode; int16_t duration, strength, decay; };
struct settings { uint8_t mode; int16_t strength, duration, phase, warmup, reset_timer, reset_period, decay; };
struct scheduler { struct item queue[3]; struct settings settings; int16_t cancel_timer; };
struct tick { uint8_t command, advanced; struct settings settings; struct item queue[3]; };

static uint64_t hash_tick(uint64_t hash, const struct tick *tick) {
    hash = hash_u8(hash, tick->command); hash = hash_u8(hash, tick->advanced);
    hash = hash_u8(hash, tick->settings.mode);
    hash = hash_u16(hash, (uint16_t) tick->settings.strength);
    hash = hash_u16(hash, (uint16_t) tick->settings.duration);
    hash = hash_u16(hash, (uint16_t) tick->settings.phase);
    hash = hash_u16(hash, (uint16_t) tick->settings.warmup);
    hash = hash_u16(hash, (uint16_t) tick->settings.reset_timer);
    hash = hash_u16(hash, (uint16_t) tick->settings.reset_period);
    for (unsigned index = 0; index < 3; ++index) {
        hash = hash_u8(hash, tick->queue[index].mode);
        hash = hash_u16(hash, (uint16_t) tick->queue[index].duration);
        hash = hash_u16(hash, (uint16_t) tick->queue[index].strength);
        hash = hash_u16(hash, (uint16_t) tick->queue[index].decay);
    }
    return hash;
}

static void update_queue(struct scheduler *scheduler) {
    if (scheduler->queue[0].mode != 0) {
        scheduler->settings.phase = 0;
        scheduler->settings.warmup = 4;
        scheduler->settings.mode = scheduler->queue[0].mode;
        scheduler->settings.duration = scheduler->queue[0].duration;
        scheduler->settings.strength = scheduler->queue[0].strength;
        scheduler->settings.decay = scheduler->queue[0].decay;
    }
    scheduler->queue[0] = scheduler->queue[1];
    scheduler->queue[1] = scheduler->queue[2];
    scheduler->queue[2] = (struct item) { 0, 0, 0, 0 };
}

static struct tick tick(struct scheduler *scheduler, uint64_t global_timer, int advance) {
    struct tick result = { 0, 0, scheduler->settings, { scheduler->queue[0], scheduler->queue[1], scheduler->queue[2] } };
    if (!advance) return result;
    update_queue(scheduler);
    uint8_t command;
    if (scheduler->cancel_timer > 0) {
        scheduler->cancel_timer--;
        command = 2;
        result.command = command;
        result.advanced = 1;
        result.settings = scheduler->settings;
        memcpy(result.queue, scheduler->queue, sizeof(result.queue));
        return result;
    } else if (scheduler->settings.warmup > 0) {
        scheduler->settings.warmup--;
        command = 1;
    } else if (scheduler->settings.duration > 0) {
        scheduler->settings.duration--;
        scheduler->settings.strength -= scheduler->settings.decay;
        if (scheduler->settings.strength < 0) scheduler->settings.strength = 0;
        if (scheduler->settings.mode == 1) {
            command = 1;
        } else if (scheduler->settings.phase >= 0x100) {
            scheduler->settings.phase -= 0x100;
            command = 1;
        } else {
            scheduler->settings.phase += ((scheduler->settings.strength * scheduler->settings.strength * scheduler->settings.strength) / 0x200) + 4;
            command = 2;
        }
    } else {
        scheduler->settings.duration = 0;
        if (scheduler->settings.reset_timer >= 5) command = 1;
        else if (scheduler->settings.reset_timer >= 2 && scheduler->settings.reset_period > 0
                 && global_timer % (uint64_t) scheduler->settings.reset_period == 0) command = 1;
        else command = 2;
    }
    if (scheduler->settings.reset_timer > 0) scheduler->settings.reset_timer--;
    result.command = command;
    result.advanced = 1;
    result.settings = scheduler->settings;
    memcpy(result.queue, scheduler->queue, sizeof(result.queue));
    return result;
}

int main(void) {
    struct scheduler scheduler;
    memset(&scheduler, 0, sizeof(scheduler));
    scheduler.queue[2] = (struct item) { 1, 80, 5, 0 };
    uint64_t fingerprint = FNV_OFFSET;
    struct tick result = tick(&scheduler, 0, 0);
    fingerprint = hash_tick(fingerprint, &result);
    for (uint64_t timer = 0; timer < 7; ++timer) {
        result = tick(&scheduler, timer, 1);
        fingerprint = hash_tick(fingerprint, &result);
    }

    scheduler.queue[2] = (struct item) { 2, 70, 5, 0 };
    result = tick(&scheduler, 7, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 8, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 9, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 10, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 11, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 12, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 13, 1); fingerprint = hash_tick(fingerprint, &result);

    if (scheduler.settings.reset_timer == 0) scheduler.settings.reset_timer = 7;
    if (scheduler.settings.reset_timer < 4) scheduler.settings.reset_timer = 4;
    scheduler.settings.reset_period = 5;
    result = tick(&scheduler, 14, 1); fingerprint = hash_tick(fingerprint, &result);

    scheduler.cancel_timer = 2;
    result = tick(&scheduler, 15, 1); fingerprint = hash_tick(fingerprint, &result);
    result = tick(&scheduler, 16, 1); fingerprint = hash_tick(fingerprint, &result);
    printf("rumbleCoreFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
