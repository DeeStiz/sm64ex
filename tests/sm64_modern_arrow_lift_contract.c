#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "PR/ultratypes.h"

#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t action, timer;
    int16_t face_yaw;
    float displacement;
    int mario_is_on_platform;
};

struct Output {
    int32_t action;
    int16_t move_yaw;
    float velocity_y, forward_velocity, displacement, delta_x, delta_z;
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
        input.action, input.face_yaw, 0.0f, 0.0f, input.displacement, 0.0f, 0.0f,
    };
    switch (input.action) {
        case 0:
            if (input.timer > 60 && input.mario_is_on_platform) output.action = 1;
            break;
        case 1:
            output.move_yaw = (int16_t) (input.face_yaw - 0x4000);
            output.forward_velocity = 12.0f;
            output.displacement += output.forward_velocity;
            if (output.displacement > 384.0f) {
                output.forward_velocity = 0.0f;
                output.displacement = 384.0f;
                output.action = 2;
            }
            output.delta_x = gSineTable[(uint16_t) output.move_yaw >> 4]
                * output.forward_velocity;
            output.delta_z = gSineTable[((uint16_t) (output.move_yaw + 0x4000)) >> 4]
                * output.forward_velocity;
            break;
        case 2:
            if (input.timer > 60) {
                output.move_yaw = (int16_t) (input.face_yaw + 0x4000);
                output.forward_velocity = 12.0f;
                output.displacement -= output.forward_velocity;
                if (output.displacement < 0.0f) {
                    output.forward_velocity = 0.0f;
                    output.displacement = 0.0f;
                    output.action = 0;
                }
                output.delta_x = gSineTable[(uint16_t) output.move_yaw >> 4]
                    * output.forward_velocity;
                output.delta_z = gSineTable[((uint16_t) (output.move_yaw + 0x4000)) >> 4]
                    * output.forward_velocity;
            }
            break;
    }
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.action);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.move_yaw);
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.velocity_y));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.forward_velocity));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.displacement));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.delta_x));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.delta_z));
}

int main(void) {
    struct Output waiting = update((struct Input) { 0, 60, 0, 0.0f, 1 });
    struct Output starts = update((struct Input) { 0, 61, 0, 0.0f, 1 });
    struct Output away = update((struct Input) { 1, 0, 0, 100.0f, 0 });
    struct Output away_done = update((struct Input) { 1, 0, 0, 378.0f, 0 });
    struct Output back_waiting = update((struct Input) { 2, 60, 0, 200.0f, 0 });
    struct Output back_done = update((struct Input) { 2, 61, 0, 4.0f, 0 });

    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, waiting);
    append_output(&fingerprint, starts);
    append_output(&fingerprint, away);
    append_output(&fingerprint, away_done);
    append_output(&fingerprint, back_waiting);
    append_output(&fingerprint, back_done);
    printf("arrowLiftFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern arrow lift C contract matched\n");
    return waiting.action == 0 && waiting.forward_velocity == 0.0f
        && starts.action == 1
        && away.action == 1 && away.displacement == 112.0f
        && away.delta_x == -12.0f && away.delta_z == 0.0f
        && away_done.action == 2 && away_done.displacement == 384.0f
        && away_done.forward_velocity == 0.0f
        && back_waiting.action == 2 && back_waiting.displacement == 200.0f
        && back_done.action == 0 && back_done.displacement == 0.0f
        && back_done.forward_velocity == 0.0f ? 0 : 1;
}
