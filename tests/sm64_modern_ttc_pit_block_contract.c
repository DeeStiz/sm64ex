#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & 0xffu;
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}

struct Init { uint8_t collision; float peak; float initial; };
struct Input {
    int32_t speed, timer, direction, wait;
    float velocity, position, home, peak;
    int32_t random_wait;
};
struct Output {
    int32_t timer, direction, wait;
    float velocity, position;
    int32_t clamped;
};

static struct Init initialize(float position, uint8_t collision, int32_t speed) {
    struct Init result = { collision, position + 330.0f,
                           speed == 3 ? position + 330.0f : position };
    return result;
}

static struct Output update(struct Input input) {
    static const float speeds[4][2] = {{11, -9}, {18, -11}, {11, -9}, {0, 0}};
    static const int32_t waits[4][2] = {{20, 30}, {15, 15}, {20, -1}, {0, 0}};
    struct Output result = {
        input.timer, input.direction, input.wait, input.velocity,
        input.position, 0
    };
    if (input.timer > input.wait) {
        result.position += result.velocity;
        if (result.position <= input.home) {
            result.position = input.home;
            result.clamped = 1;
        } else if (result.position >= input.peak) {
            result.position = input.peak;
            result.clamped = 1;
        }
        if (result.clamped) {
            result.direction ^= 1;
            result.wait = waits[input.speed][result.direction & 1];
            if (result.wait < 0) result.wait = input.random_wait;
            result.velocity = speeds[input.speed][result.direction & 1];
            result.timer = 0;
        }
    }
    return result;
}

static uint64_t append_init(uint64_t hash, struct Init value) {
    hash = hash_u32(hash, value.collision);
    hash = hash_f32(hash, value.peak);
    return hash_f32(hash, value.initial);
}

static uint64_t append_output(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.timer);
    hash = hash_u32(hash, (uint32_t)value.direction);
    hash = hash_u32(hash, (uint32_t)value.wait);
    hash = hash_f32(hash, value.velocity);
    hash = hash_f32(hash, value.position);
    return hash_u32(hash, (uint32_t)value.clamped);
}

int main(void) {
    struct Init slow = initialize(100.0f, 0, 0);
    struct Init stopped_init = initialize(100.0f, 1, 3);
    struct Output waiting = update((struct Input){0, 0, 0, 20, 11, 100, 100, 430, 70});
    struct Output rising = update((struct Input){0, 21, 0, 20, 11, 100, 100, 430, 70});
    struct Output top = update((struct Input){0, 21, 0, 20, 11, 425, 100, 430, 70});
    struct Output random_top = update((struct Input){2, 21, 0, 20, 11, 425, 100, 430, 70});
    struct Output bottom = update((struct Input){2, 31, 1, 30, -9, 105, 100, 430, 70});
    struct Output stopped = update((struct Input){3, 1, 1, 0, 0, 430, 100, 430, 70});
    if (slow.peak != 430 || slow.initial != 100 || stopped_init.initial != 430 ||
        waiting.position != 100 || rising.position != 111 ||
        top.direction != 1 || top.wait != 30 || top.velocity != -9 ||
        random_top.wait != 70 || bottom.direction != 0 || stopped.direction != 0) {
        return 2;
    }
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append_init(fingerprint, slow);
    fingerprint = append_init(fingerprint, stopped_init);
    fingerprint = append_output(fingerprint, waiting);
    fingerprint = append_output(fingerprint, rising);
    fingerprint = append_output(fingerprint, top);
    fingerprint = append_output(fingerprint, random_top);
    fingerprint = append_output(fingerprint, bottom);
    fingerprint = append_output(fingerprint, stopped);
    printf("ttcPitBlockFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern TTC pit block C contract passed");
    return 0;
}
