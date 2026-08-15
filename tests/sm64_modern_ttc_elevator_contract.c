#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t speed_setting, timer, direction, move_time;
    float position_y, home_y, peak_y, gravity;
    int32_t random_sign, random_move_time;
};
struct Output {
    float velocity_y;
    int32_t direction, move_time, timer;
    float position_y;
    int clamped_at_endpoint;
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

static float initialize(float position_y, uint16_t behavior_parameter_high) {
    float peak_offset = behavior_parameter_high != 0
        ? 100.0f * behavior_parameter_high : 500.0f;
    return position_y + peak_offset;
}

static struct Output update(struct Input input) {
    static const float speeds[] = { 6.0f, 10.0f, 6.0f, 0.0f };
    struct Output output = {
        speeds[input.speed_setting] * input.direction,
        input.direction,
        input.move_time,
        input.timer,
        input.position_y,
        0,
    };
    if (input.speed_setting == 2) {
        if (input.timer > input.move_time) {
            output.direction = input.random_sign;
            output.move_time = input.random_move_time;
            output.timer = 0;
        } else if (input.timer < 5) {
            output.velocity_y = 0.0f;
        }
    }
    output.velocity_y += input.gravity;
    output.position_y += output.velocity_y;
    if (output.position_y < input.home_y) {
        output.position_y = input.home_y;
        output.clamped_at_endpoint = 1;
    } else if (output.position_y > input.peak_y) {
        output.position_y = input.peak_y;
        output.clamped_at_endpoint = 1;
    }
    if (output.clamped_at_endpoint) output.direction = -output.direction;
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.velocity_y));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.direction);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.move_time);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.timer);
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.position_y));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.clamped_at_endpoint);
}

int main(void) {
    struct Output slow = update((struct Input) { 0, 10, 1, 0, 100, 0, 600, 0, -1, 20 });
    struct Output fast = update((struct Input) { 1, 10, -1, 0, 100, 0, 600, 0, 1, 20 });
    struct Output stopped = update((struct Input) { 3, 10, 1, 0, 100, 0, 600, 0, -1, 20 });
    struct Output random_pause = update((struct Input) { 2, 3, 1, 10, 100, 0, 600, 0, -1, 20 });
    struct Output random_change = update((struct Input) { 2, 11, 1, 10, 100, 0, 600, 0, -1, 20 });
    struct Output endpoint = update((struct Input) { 0, 10, 1, 0, 598, 0, 600, 0, -1, 20 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, slow);
    append_output(&fingerprint, fast);
    append_output(&fingerprint, stopped);
    append_output(&fingerprint, random_pause);
    append_output(&fingerprint, random_change);
    append_output(&fingerprint, endpoint);
    printf("ttcElevatorFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern TTC elevator C contract matched\n");
    return initialize(100, 0) == 600.0f && initialize(100, 4) == 500.0f
        && slow.velocity_y == 6.0f && slow.position_y == 106.0f && slow.direction == 1
        && fast.velocity_y == -10.0f && fast.position_y == 90.0f
        && stopped.velocity_y == 0.0f && stopped.position_y == 100.0f
        && random_pause.velocity_y == 0.0f && random_pause.position_y == 100.0f
        && random_change.velocity_y == 6.0f && random_change.direction == -1
        && random_change.move_time == 20 && random_change.timer == 0
        && endpoint.position_y == 600.0f && endpoint.direction == -1
        && endpoint.clamped_at_endpoint ? 0 : 1;
}
