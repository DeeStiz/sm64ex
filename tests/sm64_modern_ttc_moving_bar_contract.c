#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t speed_setting, action, timer, delay, stopped_timer;
    float offset, speed;
    int16_t face_yaw;
    int32_t random_delay, random_pause_timer;
    int random_pause_selected, random_fakeout;
};
struct Output {
    int32_t action, timer, delay, stopped_timer;
    float offset, speed, start_offset;
    int16_t move_yaw;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint32_t bits_f32(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static struct Output update(struct Input input) {
    struct Output output = {
        input.action, input.timer, input.delay, input.stopped_timer,
        input.offset, input.speed, input.offset, (int16_t) (0x4000 - input.face_yaw),
    };
    output.offset += output.speed;
    switch (input.action) {
        case 0:
            if (input.delay != 0 && input.timer > input.delay) {
                if (output.stopped_timer != 0) {
                    --output.stopped_timer;
                } else {
                    if (input.speed_setting == 2) {
                        output.delay = input.random_delay;
                        if (input.random_pause_selected)
                            output.stopped_timer = input.random_pause_timer;
                    }
                    output.action = 1;
                    output.speed = -8.0f;
                }
            }
            break;
        case 1:
            output.speed += 0.73f;
            if (output.speed > 0.0f) {
                if (output.stopped_timer != 0) {
                    --output.stopped_timer;
                    output.speed = 0.0f;
                } else {
                    output.action = 2;
                    output.speed = 29.0f;
                }
            }
            break;
        case 2:
            if ((output.offset == 250.0f
                 || (250.0f - output.offset) * (250.0f - output.start_offset) < 0.0f)
                && output.speed > -8.0f && output.speed < 8.0f) {
                output.action = 3;
                output.speed = 0.0f;
            } else {
                float acceleration = output.offset < 250.0f ? 6.4f : -6.4f;
                if (output.speed * acceleration < 0.0f) acceleration *= 2.35f;
                output.speed += acceleration;
                if (input.speed_setting == 2 && output.offset * output.start_offset < 0.0f
                    && input.random_fakeout) {
                    output.action = 0;
                    output.offset = 0.0f;
                    output.speed = 0.0f;
                }
            }
            break;
        case 3:
            if (input.timer > 30) {
                output.speed = -5.0f;
                if (output.offset < 0.0f) {
                    output.action = 0;
                    output.offset = 0.0f;
                    output.speed = 0.0f;
                }
            }
            break;
    }
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.action);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.timer);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.delay);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.stopped_timer);
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.offset));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.speed));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.start_offset));
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.move_yaw);
}

int main(void) {
    struct Output waiting = update((struct Input) { 0, 0, 55, 55, 0, 0, 0, 0x1000, 12, 0, 0, 0 });
    struct Output starts_pull = update((struct Input) { 0, 0, 56, 55, 0, 0, 0, 0x1000, 12, 0, 0, 0 });
    struct Output pull = update((struct Input) { 0, 1, 0, 55, 0, 0, -8, 0x1000, 12, 0, 0, 0 });
    struct Output pull_to_extend = update((struct Input) { 0, 1, 0, 55, 0, 0, -0.5f, 0x1000, 12, 0, 0, 0 });
    struct Output crossed = update((struct Input) { 0, 2, 0, 55, 0, 249, 2, 0x1000, 12, 0, 0, 0 });
    struct Output fakeout = update((struct Input) { 2, 2, 0, 55, 0, -1, 2, 0x1000, 12, 0, 0, 1 });
    struct Output reset = update((struct Input) { 0, 3, 31, 55, 0, 0, -5, 0x1000, 12, 0, 0, 0 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, waiting);
    append_output(&fingerprint, starts_pull);
    append_output(&fingerprint, pull);
    append_output(&fingerprint, pull_to_extend);
    append_output(&fingerprint, crossed);
    append_output(&fingerprint, fakeout);
    append_output(&fingerprint, reset);
    printf("ttcMovingBarFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern TTC moving bar C contract matched\n");
    return waiting.action == 0 && waiting.offset == 0.0f
        && starts_pull.action == 1 && starts_pull.speed == -8.0f
        && pull.action == 1 && pull.speed == -7.27f
        && pull_to_extend.action == 2 && pull_to_extend.speed == 29.0f
        && crossed.action == 3 && crossed.offset == 251.0f && crossed.speed == 0.0f
        && fakeout.action == 0 && fakeout.offset == 0.0f && fakeout.speed == 0.0f
        && reset.action == 0 && reset.offset == 0.0f && reset.speed == 0.0f ? 0 : 1;
}
