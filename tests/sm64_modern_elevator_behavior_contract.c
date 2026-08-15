#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t action, timer;
    float position_y, velocity_y, bottom_y, top_y, midpoint_y, mario_position_y;
    uint32_t platform_kind;
    int mario_on_platform, mario_in_air_action;
};
struct Output { int32_t action; float position_y, velocity_y; uint32_t sound; int shake_small; };

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static float approach_signed(float value, float target, float increment) {
    float result = value + increment;
    if (increment >= 0.0f) {
        if (result > target) result = target;
    } else if (result < target) {
        result = target;
    }
    return result;
}

static struct Output update(struct Input input) {
    struct Output output = { input.action, input.position_y, input.velocity_y, 0, 0 };
    switch (input.action) {
    case 0:
        output.velocity_y = 0;
        if (input.platform_kind == 2) {
            if (input.mario_on_platform)
                output.action = output.position_y > input.midpoint_y ? 2 : 1;
        } else if (input.mario_position_y > input.midpoint_y || input.platform_kind == 1) {
            output.position_y = input.top_y;
            if (input.mario_on_platform) output.action = 2;
        } else {
            output.position_y = input.bottom_y;
            if (input.mario_on_platform) output.action = 1;
        }
        break;
    case 1:
        output.sound = 1;
        if (input.timer == 0 && input.mario_on_platform) { output.sound = 2; output.shake_small = 1; }
        output.velocity_y = approach_signed(output.velocity_y, 10.0f, 2.0f);
        output.position_y += output.velocity_y;
        if (output.position_y > input.top_y) {
            output.position_y = input.top_y;
            if (input.platform_kind == 2 || input.platform_kind == 1) output.action = 3;
            else if (input.mario_position_y < input.midpoint_y) output.action = 2;
            else output.action = 3;
        }
        break;
    case 2:
        output.sound = 1;
        if (input.timer == 0 && input.mario_on_platform) { output.sound = 2; output.shake_small = 1; }
        output.velocity_y = approach_signed(output.velocity_y, -10.0f, -2.0f);
        output.position_y += output.velocity_y;
        if (output.position_y < input.bottom_y) {
            output.position_y = input.bottom_y;
            if (input.platform_kind == 1) output.action = 4;
            else if (input.platform_kind == 2) output.action = 3;
            else if (input.mario_position_y > input.midpoint_y) output.action = 1;
            else output.action = 3;
        }
        break;
    case 3:
        output.velocity_y = 0;
        if (input.timer == 0) { output.sound = 3; output.shake_small = 1; }
        if (!input.mario_in_air_action && !input.mario_on_platform) output.action = 0;
        break;
    case 4:
        output.velocity_y = 0;
        if (input.timer == 0) { output.sound = 3; output.shake_small = 1; }
        if (!input.mario_in_air_action && !input.mario_on_platform) output.action = 1;
        break;
    default: break;
    }
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    uint32_t bits;
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.action);
    memcpy(&bits, &output.position_y, sizeof(bits)); *fingerprint = hash_u32(*fingerprint, bits);
    memcpy(&bits, &output.velocity_y, sizeof(bits)); *fingerprint = hash_u32(*fingerprint, bits);
    *fingerprint = hash_u32(*fingerprint, output.sound);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.shake_small);
}

int main(void) {
    struct Output rising = update((struct Input) { 1, 0, 18, 8, 0, 20, 10, 4, 0, 1, 0 });
    struct Output descending = update((struct Input) { 2, 3, 4, -8, 0, 20, 10, 18, 0, 1, 0 });
    struct Output resting = update((struct Input) { 3, 0, 20, 4, 0, 20, 10, 20, 0, 0, 0 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, rising);
    append_output(&fingerprint, descending);
    append_output(&fingerprint, resting);
    printf("elevatorBehaviorFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return rising.action == 2 && rising.position_y == 20 && rising.velocity_y == 10
        && rising.sound == 2 && rising.shake_small
        && descending.action == 1 && descending.position_y == 0 && descending.velocity_y == -10
        && resting.action == 0 && resting.sound == 3 && resting.shake_small ? 0 : 1;
}
